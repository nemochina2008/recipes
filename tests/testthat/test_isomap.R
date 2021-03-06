library(testthat)
library(recipes)

context("ISOmap")

## expected results form the `dimRed` package

exp_res <- structure(list(Isomap1 = c(0.312570873898531, 0.371885353599467, 2.23124009833741,
                                      0.248271457498181, -0.420128801874122),
                          Isomap2 = c(-0.443724171391742, -0.407721529759647, 0.245721022395862,
                                      3.112001672258, 0.0292770508011519),
                          Isomap3 = c(0.761529345514676, 0.595015565588918, 1.59943072269788,
                                      0.566884409484389, 1.53770327701819)),
                     .Names = c("Isomap1","Isomap2", "Isomap3"),
                     class = c("tbl_df", "tbl", "data.frame"),
                     row.names = c(NA, -5L))

set.seed(1)
dat1 <- matrix(rnorm(15), ncol = 3)
dat2 <- matrix(rnorm(15), ncol = 3)
colnames(dat1) <- paste0("x", 1:3)
colnames(dat2) <- paste0("x", 1:3)

rec <- recipe( ~ ., data = dat1)

test_that('correct Isomap values', {
  skip_on_cran()
  skip_if_not_installed("RSpectra")
  skip_if_not_installed("igraph")
  skip_if_not_installed("RANN")
  skip_if_not_installed("dimRed")
  skip_if(getRversion() <= "3.4.4")

  im_rec <- rec %>%
    step_isomap(x1, x2, x3, neighbors = 3, num_terms = 3, id = "")

  im_trained <- prep(im_rec, training = dat1, verbose = FALSE)

  im_pred <- bake(im_trained, new_data = dat2)

  # unique up to sign
  all.equal(abs(as.matrix(im_pred)), abs(as.matrix(exp_res)))

  im_tibble <-
    tibble(terms = c("x1", "x2", "x3"), id = "")

  expect_equal(tidy(im_rec, 1), im_tibble)
  expect_equal(tidy(im_trained, 1), im_tibble)
})


test_that('deprecated arg', {
  skip_if_not_installed("dimRed")
  expect_message(
    rec %>%
      step_isomap(x1, x2, x3, num = 3, id = "")
  )
})

test_that('printing', {
  skip_on_cran()
  skip_if_not_installed("RSpectra")
  skip_if_not_installed("igraph")
  skip_if_not_installed("RANN")
  skip_if_not_installed("dimRed")
  skip_if(getRversion() <= "3.4.4")

  im_rec <- rec %>%
    step_isomap(x1, x2, x3, neighbors = 3, num_terms = 3)
  expect_output(print(im_rec))
  expect_output(prep(im_rec, training = dat1, verbose = TRUE))
})


test_that('No ISOmap', {
  im_rec <- rec %>%
    step_isomap(x1, x2, x3, neighbors = 3, num_terms = 0, id = "") %>%
    prep()

  expect_equal(
    names(juice(im_rec)),
    colnames(dat1)
  )
  expect_true(inherits(im_rec$steps[[1]]$res, "list"))
  expect_output(print(im_rec),
                regexp = "Isomap was not conducted")
  expect_equal(
    tidy(im_rec, 1),
    tibble::tibble(terms = im_rec$steps[[1]]$res$x_vars, id = "")
  )
})

