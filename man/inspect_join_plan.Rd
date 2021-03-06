% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/join_controller.R
\name{inspect_join_plan}
\alias{inspect_join_plan}
\title{check that a join plan is consistent with table descriptions.}
\usage{
inspect_join_plan(tDesc, columnJoinPlan, ..., checkColClasses = FALSE)
}
\arguments{
\item{tDesc}{description of tables, from \code{\link{describe_tables}} (and likely altered by user).}

\item{columnJoinPlan}{columns to join, from \code{\link{build_join_plan}} (and likely altered by user). Note: no column names must intersect with names of the form \code{table_CLEANEDTABNAME_present}.}

\item{...}{force later arguments to bind by name.}

\item{checkColClasses}{logical if true check for exact class name matches}
}
\value{
NULL if okay, else a string
}
\description{
Please see \code{vignette('DependencySorting', package = 'rquery')} and \code{vignette('joinController', package= 'rquery')} for more details.
}
\examples{

if (requireNamespace("DBI", quietly = TRUE) && requireNamespace("RSQLite", quietly = TRUE)) {
  my_db <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  # example data
  DBI::dbWriteTable(my_db,
                    "d1",
                    data.frame(id= 1:3,
                               weight= c(200, 140, 98),
                               height= c(60, 24, 12)))
  DBI::dbWriteTable(my_db,
                    "d2",
                    data.frame(pid= 2:3,
                               weight= c(130, 110),
                               width= 1))
  # get the initial description of table defs
  tDesc <- describe_tables(my_db, qc(d1, d2))
  # declare keys (and give them consistent names)
  tDesc$keys[[1]] <- list(PrimaryKey= 'id')
  tDesc$keys[[2]] <- list(PrimaryKey= 'pid')
  # build the join plan
  columnJoinPlan <- build_join_plan(tDesc)
  # confirm the plan
  print(inspect_join_plan(tDesc, columnJoinPlan,
                          checkColClasses= TRUE))
  # damage the plan
  columnJoinPlan$sourceColumn[columnJoinPlan$sourceColumn=='width'] <- 'wd'
  # find a problem
  print(inspect_join_plan(tDesc, columnJoinPlan,
                          checkColClasses= TRUE))
  DBI::dbDisconnect(my_db)
}

}
\seealso{
\code{\link{describe_tables}}, \code{\link{build_join_plan}}, \code{\link{graph_join_plan}}, \code{\link{actualize_join_plan}}
}
