# > X
#       [,1] [,2]
# [1,]    1    4
# [2,]    2    5
# [3,]    3    6
#
# > Xout
# 3 x 6 sparse Matrix of class "dgCMatrix"
#
# [1,] 1 4 . . . .
# [2,] . . 2 5 . .
# [3,] . . . . 3 6
#' @export
SURform <- function(X){
  r <- nrow(X); c <- ncol(X);
  idi <- kronecker(c(1:r), rep(1,c));
  idj <- c(1: (r*c))
  Xout <- Matrix::sparseMatrix(i = idi,j = idj, x = as.numeric(t(X)))
  return(Xout)
}

#' @export
reprow<-function(x,n){
  matrix(rep(x,each=n),nrow=n)
}

#' @export
repcol<-function(x,n){
  matrix(rep(x,each=n), ncol=n, byrow=TRUE)
}

#' @export
adaptamount <- function(iteration){
  return( min( 0.01, 1.0 / sqrt(iteration) ) );
}

#' @export
B0_mat <- function(b0, K, p){
  # matrix coefficient B
  B0 <- cbind(rep(0,K))
  if (length(b0) == 1) {
    for (i in c(1:p)){
      B0 <- cbind(B0, b0^i*diag(K))
    }
  } else {
    B0 <- matrix(b0, nrow = K, byrow = TRUE)
  }
  return(B0)
}


#' @export
A0_mat <- function(a0, K){
  # Sample matrix corr A0
  if (length(a0) == 1) {
    A0 <- matrix(a0, K, K)
    diag(A0) <- 1
    A0[upper.tri(A0)] <- 0
  } else {
    A0 <- matrix(0, nrow = K, ncol = K)
    A0[upper.tri(A0)] <- a0
    A0 <- t(A0)
    diag(A0) <- 1
  }
  return(A0)
}

#' @export
Sigma_sample <- function(Beta, Beta0, Sigma_Beta, Prior_Beta, t_max){
  K <- ncol(Beta)
  if (K>1) {
    sse_2 <- apply( (Beta - rbind(Beta0,Beta[1:(t_max-1),]) )^2, MARGIN = 2, FUN = sum)
  } else {
    sse_2 <- sum( (Beta - c(Beta0,Beta[1:(t_max-1),]) )^2 )
  }

  # Normal prior
  # Equation 9 in https://doi.org/10.1016/j.csda.2013.01.002
  sigma_post_a <- rep(t_max,K) # prior of sigma_h Gamma(1,0.0001)
  sigma_post_b <- sse_2 # prior of sigma_h

  for (i in c(1:K)){
    sigma_new <- rinvgamma(1, shape = sigma_post_a[i] * 0.5, rate = sigma_post_b[i] * 0.5)
    alpha = 0.5 * (Sigma_Beta[i] - sigma_new) / Prior_Beta[i] + 0.5 * (log(sigma_new) - log(Sigma_Beta[i])) # B_sigma = 1
    temp = log(runif(1))
    if (alpha > temp){
      Sigma_Beta[i] <- sigma_new
    }
    #log_sigma_den[]
  }
  return(Sigma_Beta)
}



#' @export
Normal_approx <- function(mcmc_sample, ndraws){
  mcmc_mean <- apply(mcmc_sample, 2, mean)
  mcmc_Sigma <- cov(mcmc_sample)
  nElements <- length(mcmc_mean)

  new_samples <- mvnfast::rmvn(ndraws, mu = mcmc_mean, sigma = mcmc_Sigma)
  colnames(new_samples) <- colnames(mcmc_sample)
  sum_log_prop <- mvnfast::dmvn(X = new_samples,
                                mu = as.numeric(mcmc_mean), sigma = mcmc_Sigma, log = T)
  return(list(new_samples = new_samples,
              sum_log_prop = sum_log_prop))
}
