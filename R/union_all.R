
#' Make an union_all node (not a relational operation).
#'
#'
#' Concantinate tables.
#'
#'
#' @param sources list of relop trees or list of data.frames
#' @return order_by node or altered data.frame.
#'
#' @examples
#'
#' if (requireNamespace("RSQLite", quietly = TRUE)) {
#'   my_db <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
#'   d <- dbi_copy_to(my_db, 'd',
#'                    data.frame(AUC = 0.6, R2 = 0.2))
#'   optree <- union_all(list(d, d, d))
#'   cat(format(optree))
#'   sql <- to_sql(optree, my_db, limit = 2)
#'   cat(sql)
#'   print(DBI::dbGetQuery(my_db, sql))
#'   DBI::dbDisconnect(my_db)
#' }
#'
#' @export
#'
union_all <- function(sources) {
  if((!is.list(sources))||(length(sources)<2)) {
    stop("rquery::union_all sources must be a list of length at least 2")
  }
  ns <- length(sources)
  if((!is.data.frame(sources[[1]])) &&
     (!("relop" %in% class(sources[[1]])))) {
    stop("rquery::union_all sources[[1]] must be a data.frame of of class relop.")
  }
  cols <- column_names(sources[[1]])
  for(i in 2:ns) {
    ci <- column_names(sources[[i]])
    if(!isTRUE(all.equal(cols, ci))) {
      stop("rquery::union_all all sources must have identical column structure")
    }
  }
  if(is.data.frame(sources[[1]])) {
    for(i in 2:ns) {
      if(!is.data.frame(sources[[i]])) {
        stop("rquery::union_all when sources[[1]]] is a data.frame, all other sources must also be data.frames.")
      }
    }
    tmp_name_source <- mk_tmp_name_source("rquery_tmp")
    sources_tmp <- lapply(1:ns,
                          function(i) {
                            tmp_name <- tmp_name_source()
                            dnode <- table_source(tmp_name, cols)
                            dnode$data <- sources[[i]]
                            dnode
                          })
    return(union_all(sources_tmp))
  }
  # leave in redundant check to document intent and make invariants obvious
  if(!("relop" %in% class(sources[[1]]))) {
    stop("rquery::union_all when sources[[1]]] is not a data.frame it must have class relop.")
  }
  for(i in 2:ns) {
    if(!("relop" %in% class(sources[[i]]))) {
      stop("rquery::union_all when sources[[1]]] is of class relop, all other sources must also be of class relop.")
    }
  }
  r <- list(source = sources,
            table_name = NULL,
            parsed = NULL,
            cols = cols)
  r <- relop_decorate("relop_union_all", r)
  r
}



#' @export
format_node.relop_union_all <- function(node) {
  inps <- paste0(".", seq_len(length(node$source)))
  paste0("union_all(",
         paste(inps, collapse = ", "),
         ")")
}

#' @export
format.relop_union_all  <- function(x, ...) {
  wrapr::stop_if_dot_args(substitute(list(...)),
                          "format.relop_union_all")
  inputs <- vapply(x$source,
                   function(si) {
                     trimws(format(si), which = "right")
                   }, character(1))
  inputs <- trimws(inputs, which = "right")
  paste0("union_all(.,\n",
         "  ", paste(inputs, collapse = ",\n "),
         ")",
         "\n")
}


#' @export
column_names.relop_union_all <- function (x, ...) {
  wrapr::stop_if_dot_args(substitute(list(...)),
                          "rquery::column_names.relop_union_all")
  x$cols
}

#' @export
columns_used.relop_union_all <- function (x, ...,
                                          using = NULL,
                                          contract = FALSE) {
  columns_used(x$source[[1]], using = using, contract = contract)
}


#' @export
to_sql.relop_union_all <- function (x,
                                    db,
                                    ...,
                                    limit = NULL,
                                    source_limit = NULL,
                                    indent_level = 0,
                                    tnum = mk_tmp_name_source('tsql'),
                                    append_cr = TRUE,
                                    using = NULL) {
  wrapr::stop_if_dot_args(substitute(list(...)),
                          "rquery::to_sql.relop_union_all")
  qlimit = limit
  if(!getDBOption(db, "use_pass_limit", TRUE)) {
    qlimit = NULL
  }
  subsql_list <- lapply(
    x$source,
    function(si) {
      to_sql(si,
             db = db,
             limit = qlimit,
             source_limit = source_limit,
             indent_level = indent_level + 1,
             tnum = tnum,
             append_cr = FALSE,
             using = using)
    })
  sql_list <- NULL
  inputs <- character(0)
  for(sil in subsql_list) {
    sql_list <- c(sql_list, sil[-length(sil)])
    inputs <- c(inputs, sil[length(sil)])
  }
  tmps <- vapply(seq_len(length(inputs)),
                 function(i) {
                   tnum()
                 }, character(1))
  # allows us to ensure column order
  cols <- x$cols
  if(length(using)>0) {
    cols <- intersect(cols, using)
  }
  cols <- vapply(cols,
                 function(ci) {
                   DBI::dbQuoteIdentifier(db, ci)
                 }, character(1))
  cols <- paste(cols, collapse = ", ")
  inputs <- paste("SELECT ", cols, " FROM ( ", inputs, ")", tmps)
  q <- paste(inputs, collapse = " UNION ALL ")
  if(!is.null(x$limit)) {
    limit <- min(limit, x$limit)
  }
  if(!is.null(limit)) {
    q <- paste(q, "LIMIT",
               format(ceiling(limit), scientific = FALSE))
  }
  if(append_cr) {
    q <- paste0(q, "\n")
  }
  c(sql_list, q)
}
