
library("rquery")


context("test_set_indicator.R")


test_that("test_set_indicator.R: Works As Expected", {

  if (requireNamespace("DBI", quietly = TRUE) && requireNamespace("RSQLite", quietly = TRUE)) {
    my_db <- DBI::dbConnect(RSQLite::SQLite(),
                            ":memory:")

    d <- rq_copy_to(my_db, 'd',
                    data.frame(
                      id = 1:4,
                      a = c("1", "2", "1", "3"),
                      b = c("1", "1", "3", "2"),
                      q = 1,
                      stringsAsFactors = FALSE),
                    temporary = TRUE,
                    overwrite = TRUE)
    # example
    set <- c("1", "2")

    testthat::expect_error({
      # expect an exception here
      op_tree <- d %.>%
        set_indicator(., "one_two", "a", set) %.>%
        set_indicator(., "z", "a", c()) %.>%
        select_rows(., q %in% c(1)) %.>%
        orderby(., "id")
    }, ".*")

    op_tree <- d %.>%
      set_indicator(., "one_two", "a", set) %.>%
      set_indicator(., "z", "a", c()) %.>%
      select_rows(., q == 1) %.>%
      orderby(., "id")
    res = execute(my_db, op_tree)
    testthat::expect_equivalent(c(1,1,1,0), res$one_two)

    # cleanup
    DBI::dbDisconnect(my_db)
  }


})
