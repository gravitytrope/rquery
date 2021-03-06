% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lookup_by_column.R
\name{lookup_by_column}
\alias{lookup_by_column}
\title{Use one column to pick values from other columns.}
\usage{
lookup_by_column(source, pick, result, ...,
  tmp_name_source = wrapr::mk_tmp_name_source("qn"), temporary = TRUE,
  f_dt_factory = NULL)
}
\arguments{
\item{source}{source to select from (relop or data.frame).}

\item{pick}{character scalar, name of column to control value choices.}

\item{result}{character scalar, name of column to place values in.}

\item{...}{force later arguments to be bound by name}

\item{tmp_name_source}{wrapr::mk_tmp_name_source(), temporary name generator.}

\item{temporary}{logical, if TRUE use temporary tables.}

\item{f_dt_factory}{optional signature f_dt_factory(pick, result) returns function with signature f_dt(d, nd) where d is a data.table.  The point is the function must come from a data.table enabled package. Please see \code{rqdatatable::make_dt_lookup_by_column} for an example.}
}
\description{
The \code{pick} column selects values from the columns it names (per-row).
}
\examples{

df = data.frame(x = c(1, 2, 3, 4),
                y = c(5, 6, 7, 8),
                choice = c("x", "y", "x", "z"),
                stringsAsFactors = FALSE)

# library("rqdatatable")
# df \%.>\%
#   lookup_by_column(., "choice", "derived")

if (requireNamespace("DBI", quietly = TRUE) &&
    requireNamespace("RSQLite", quietly = TRUE)) {
  db <- DBI::dbConnect(RSQLite::SQLite(),
                       ":memory:")
  RSQLite::initExtension(db)
  dr <- rq_copy_to(db, "dRemote", df,
                   overwrite = TRUE,
                   temporary = TRUE)

  ops <- dr \%.>\%
    lookup_by_column(., "choice", "derived")
  cat(format(ops))

  execute(db, ops) \%.>\%
     print(.)

  DBI::dbDisconnect(db)
}


}
