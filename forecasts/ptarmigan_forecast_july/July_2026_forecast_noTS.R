# ================================================================
# H1_noTS forecast 2026: fit to 2000-2025 (T = 26), forecast 2026
# ================================================================
install.packages("nimble")
library(nimble)
library(AHMbook)   # standardize()
library(coda)

data_file   <- "data_JAGS_2026_v1.rds"            # <-- your new data file
output_file <- "output/H1_noTS_fitto2025_fc2026.RData"


# ----------------------------------------------------------------
# NIMBLE model
# ----------------------------------------------------------------
code <- nimbleCode({
  
  # ============================ Priors ====================================
  # Same values as priors_config.R (normals given as sd, not precision)
  alpha0  ~ dnorm(1,  sd = 2)
  btfR    ~ dnorm(0,  sd = 2)
  btDD    ~ dnorm(1,  sd = 1)
  btR     ~ dnorm(0,  sd = 2)
  btRD    ~ dnorm(0,  sd = 2)
  bttrend ~ dnorm(0,  sd = 0.2)
  btcarc  ~ dnorm(0,  sd = 2)
  btDoYf  ~ dnorm(0,  sd = 2)    # btDoYft / btDoYfs excluded (noTS)
  btMOTH  ~ dnorm(0,  sd = 2)    # btMOTHt / btMOTHs excluded (noTS)
  btharv  ~ dnorm(-1, sd = 1)    # btharvt / btharvs excluded (noTS)
  btrr    ~ dnorm(0,  sd = 2)    # btrrt   / btrrs   excluded (noTS)
  bttg    ~ dnorm(0,  sd = 2)    # bttgt   / bttgs   excluded (noTS)
  
  for (r in 1:4) {
    bt0[r]  ~ dnorm(1, sd = 2)
    btf0[r] ~ dnorm(1, sd = 2)
  }
  
  PrEc      <- 1 / (sdprectau * sdprectau)
  sdprectau ~ T(dt(0, 1, 3), 0, )
  PrOc      <- 1 / (sdproctau * sdproctau)
  sdproctau ~ T(dt(0, 1, 3), 0, )
  for (j in 1:NClust) {
    rCl1[j] ~ dnorm(0, tau = rtau)
    rCl[j]  ~ dnorm(0, tau = rtau2)
  }
  rtau    <- 1 / (sdrtau  * sdrtau)
  rtau2   <- 1 / (sdrtau2 * sdrtau2)
  sdrtau  ~ T(dt(0, 1, 3), 0, )
  sdrtau2 ~ T(dt(0, 1, 3), 0, )
  
  # ===================== Distance sampling obs model =====================
  for (i in 1:nobs) {
    dclass[i] ~ dcat(fc_adj[site[i], 1:nD])
  }
  
  # ============================= Likelihood ==============================
  for (s in 1:nsites) {
    
    for (g in 1:nD) {
      log(p[s, g])  <- -midpt[g] * midpt[g] / (2 * sigma[s] * sigma[s])
      pi[s, g]      <- delta / B
      f[s, g]       <- p[s, g] * pi[s, g]
      fc[s, g]      <- f[s, g] / pcap[s]
      fc_adj[s, g]  <- fc[s, g] + 0.01
    }
    pcap[s] <- sum(f[s, 1:nD])
    
    # Initial year
    y[s, 1]      ~ dbin(pcap[s], N[s, 1])
    N[s, 1]      ~ dpois(lambda[s, 1])
    lambda[s, 1] <- D[s, 1] * area[s, 1]
    logD[s, 1]   ~ dnorm(mu[s, 1], PrEc)
    mu[s, 1]     <- btf0[Reg[s]] + rCl1[Clust[s]] + btfR * rod[1, Reg[s]]
    D[s, 1]      <- exp(logD[s, 1])
    log(sigma[s]) <- alpha0
    
    # Population dynamics for subsequent years
    for (t in 2:T) {
      y[s, t]      ~ dbin(pcap[s], N[s, t])
      N[s, t]      ~ dpois(lambda[s, t])
      lambda[s, t] <- D[s, t] * area[s, t]
      
      mu[s, t] <- bt0[Reg[s]] + rCl[Clust[s]] +
        btDD    * mu[s, t-1] +
        btR     * rod[t, Reg[s]] +
        btRD    * rod[t-1, Reg[s]] +
        btDoYf  * DoYf[Clust[s], t-1] +
        btMOTH  * moth[Clust[s], t-1] +
        btharv  * harv[s, t-1] +
        btrr    * rr[Clust[s], t] +
        bttg    * tg[Clust[s], t] +
        btcarc  * carc[t] +
        bttrend * (t - 1)
      
      logD[s, t] ~ dnorm(mu[s, t], PrOc)
      D[s, t]    <- exp(logD[s, t])
    }
    
    # ---------------- In-model forecast for year T+1 (2026) ----------------
    predmu[s] <- bt0[Reg[s]] + rCl[Clust[s]] +
      btDD    * mu[s, T] +
      btR     * rod[T+1, Reg[s]] +
      btRD    * rod[T,   Reg[s]] +
      btDoYf  * DoYf[Clust[s], T] +
      btharv  * harv[s, T] +
      btMOTH  * moth[Clust[s], T] +
      btrr    * rr[Clust[s], T+1] +
      bttg    * tg[Clust[s], T+1] +
      btcarc  * carc[T] +
      bttrend * T
    
    predlogD[s]   ~ dnorm(predmu[s], PrOc)
    predD[s]      <- exp(predlogD[s])
    predlambda[s] <- predD[s] * area_pred[s]
    N_pred[s]     ~ dpois(predlambda[s])
    P_pred[s]     ~ dbin(pcap[s], N_pred[s])
  }
  
  # ========================= Derived parameters ==========================
  for (t in 1:T) {
    for (k in 1:NClust) {
      Dclust[k, t] <- inprod(clust_ind[k, 1:nsites], D[1:nsites, t]) / nSitesClust[k]
    }
    for (regi in 1:NReg) {
      Dreg[regi, t] <- inprod(reg_ind[regi, 1:NClust], Dclust[1:NClust, t]) / nClustReg[regi]
    }
    Dtot[t]    <- mean(Dreg[1:NReg, t])
    Dtot2[t]   <- inprod(reg_ind_tot2[1:NReg], Dreg[1:NReg, t]) / nRegTot2
    mean_mu[t] <- mean(mu[1:nsites, t])
  }
  
  mean_predmu <- mean(predmu[1:nsites])
  mean_predD  <- mean(predD[1:nsites])
  
  for (k in 1:NClust) {
    predDclust[k] <- inprod(clust_ind[k, 1:nsites], predD[1:nsites]) / nSitesClust[k]
  }
  for (regi in 1:NReg) {
    predDreg[regi] <- inprod(reg_ind[regi, 1:NClust], predDclust[1:NClust]) / nClustReg[regi]
  }
  predDtot  <- mean(predDreg[1:NReg])
  predDtot2 <- inprod(reg_ind_tot2[1:NReg], predDreg[1:NReg]) / nRegTot2
  
}) # end model


# ================================================================
# Driver
# ================================================================
load(data_file)
BugsData <- input.data
BugsData$VerbClust <- NULL

BugsData$T <- 26   # 2000-2025 fitted, forecast 2026

# Truncate Clust and Reg to nsites
BugsData$Clust <- BugsData$Clust[1:BugsData$nsites]
BugsData$Reg   <- BugsData$Reg[1:BugsData$nsites]

# Extract cluster and region info
NClust <- BugsData$NClust
clust_reg <- sapply(1:NClust, function(i) unique(BugsData$Reg[BugsData$Clust == i]))
NReg <- length(unique(clust_reg))


# ========================== Standardise predictors (noTS: only main matrices needed) ======================
BugsData$rod  <- apply(BugsData$rod, 2, standardize)
BugsData$DoYf <- standardize(BugsData$OnsetF)
BugsData$moth <- BugsData$anom
BugsData$harv <- standardize(BugsData$harv)
BugsData$rr   <- standardize(BugsData$rr)
BugsData$tg   <- standardize(BugsData$tg)

if (is.data.frame(BugsData$carc)) {
  BugsData$carc <- standardize(BugsData$carc$carc)
} else {
  BugsData$carc <- standardize(BugsData$carc)
}


# ========== Indicator matrices for derived quantities ====================
clust_ind <- matrix(0, NClust, BugsData$nsites)
for (k in 1:NClust) clust_ind[k, which(BugsData$Clust == k)] <- 1
nSitesClust <- as.numeric(rowSums(clust_ind))

reg_ind <- matrix(0, NReg, NClust)
for (r in 1:NReg) reg_ind[r, which(clust_reg == r)] <- 1
nClustReg <- as.numeric(rowSums(reg_ind))

reg_ind_tot2 <- rep(1, NReg)
reg_ind_tot2[3] <- 0
nRegTot2 <- sum(reg_ind_tot2)

area_pred <- BugsData$area[, BugsData$T]


# ================================================================
# Constants, data, inits
# ================================================================
constants <- list(
  nsites       = BugsData$nsites,
  nobs         = BugsData$nobs,
  nD           = BugsData$nD,
  T            = BugsData$T,
  NClust       = NClust,
  NReg         = NReg,
  B            = BugsData$B,
  delta        = BugsData$delta,
  midpt        = BugsData$midpt,
  site         = BugsData$site,
  Clust        = BugsData$Clust,
  Reg          = BugsData$Reg,
  area         = BugsData$area,
  rod          = BugsData$rod,
  DoYf         = BugsData$DoYf,
  moth         = BugsData$moth,
  harv         = BugsData$harv,
  rr           = BugsData$rr,
  tg           = BugsData$tg,
  carc         = BugsData$carc,
  clust_ind    = clust_ind,
  nSitesClust  = nSitesClust,
  reg_ind      = reg_ind,
  nClustReg    = nClustReg,
  reg_ind_tot2 = reg_ind_tot2,
  nRegTot2     = nRegTot2,
  area_pred    = area_pred
)

nimbleData <- list(
  y      = BugsData$y,
  dclass = BugsData$dclass
)

SimT <- BugsData$T
Nst  <- BugsData$y[, 1:SimT]

inits_fn <- function() {
  list(
    N         = Nst,
    sdproctau = runif(1, 0, 1),
    sdprectau = runif(1, 0, 1),
    sdrtau    = runif(1, 0, 1),
    sdrtau2   = runif(1, 0, 1),
    alpha0    = 0,
    bt0       = rep(0, 4),
    btf0      = rep(0, 4),
    btDD      = 0,
    btfR      = 0,
    btR       = 0,
    btRD      = 0,
    btDoYf    = 0,
    btMOTH    = 0,
    btharv    = 0,
    btrr      = 0,
    bttg      = 0,
    btcarc    = 0,
    bttrend   = 0
  )
}

params <- c(
  "btDD", "btR", "btRD",
  "btDoYf",
  "btMOTH",
  "btharv",
  "btrr",
  "bttg",
  "btcarc", "bttrend",
  "bt0", "rCl",
  "alpha0", "sdproctau",
  "Dtot", "Dtot2", "mean_mu",
  "Dclust", "Dreg",
  "predlambda", "N_pred", "P_pred",
  "predmu", "mean_predmu", "mean_predD", "pcap",
  "predDclust", "predDreg", "predDtot", "predDtot2"
)

ni <- 60000;   nb <- 30000;   nt <- 10;   nc <- 3


# ================================================================
# Run NIMBLE MCMC
# ================================================================
samples <- nimbleMCMC(
  code              = code,
  constants         = constants,
  data              = nimbleData,
  inits             = inits_fn,
  monitors          = params,
  niter             = ni,
  nburnin           = nb,
  thin              = nt,
  nchains           = nc,
  setSeed           = TRUE,
  samplesAsCodaMCMC = TRUE
)


# ================================================================
# Store output
# ================================================================
out_H1_noTS_fc_26 <- coda::as.mcmc.list(samples)

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
save(out_H1_noTS_fc_26, file = output_file)

#- end of script