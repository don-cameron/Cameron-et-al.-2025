## For this analysis, I first used FIJI to 
##  1) split each composite image into multiple 8-bit tiff
##  2) set an ROI around the cell of interest 
##  3) turned all pixels outside the ROI to 0 by
##   a) creating a second ROI using "select all"
##   b) Using XOR on the two ROI to create a third ROI of the area outside the chosen cell
##   c) uses "Cut" to remove all signal from outside cell (I'm sure there is a smarter way to do this)
##  4) Save the image as a "Text image" .csv file
## This means that the inputs for this analysis are two csv files with a matrix of numeral values corresponding to the pixels of
## the cell, with all pixels outside the cell set to 0.

library(dplyr)
library(ggplot2)
library(MASS)
library(viridis)

setwd("/path/to/your/working/directory")

# ---- 1) Load & prep ----
dfA <- read.csv("Image1.csv", header = FALSE)
dfB <- read.csv("Image2.csv",   header = FALSE)
stopifnot(all(dim(dfA) == dim(dfB)))

matA <- as.matrix(dfA); mode(matA) <- "numeric"
matB <- as.matrix(dfB); mode(matB) <- "numeric"
vecA <- as.vector(t(matA))
vecB <- as.vector(t(matB))

dat <- tibble(intenA = vecA, intenB = vecB) %>%
  # remove all pairs where both intensities are zero since this corresponds to cropped parts of the image that are outside the cell
  filter(!(intenA == 0 & intenB == 0)) %>%
  # count how many pixels share each remaining (intenA, intenB) pair
  count(intenA, intenB, name = "n")

# ---- 2) Expand by count and compute KDE ----
x_rep <- rep(dat$intenA, dat$n)
y_rep <- rep(dat$intenB, dat$n)

kde <- kde2d(
  x    = x_rep,
  y    = y_rep,
  h    = c(10, 10),             # adjust for your data
  n    = 200,
  lims = c(range(dat$intenA), range(dat$intenB))
)

kdf <- with(kde,
            expand.grid(intenA = x, intenB = y) %>%
              mutate(density = as.vector(z))
)

# ---- 3) Plot: coloured points + log‐spaced KDE contours + black axes ----
p <- ggplot() +
  # points coloured by count
  geom_point(
    data = dat,
    aes(x = intenA, y = intenB, color = n),
    size = 0.4
  ) +
  scale_color_viridis(
    option    = "inferno",
    direction = -1,
    trans     = "log10",
    name      = "Pixel count"
  ) +
  
  # KDE contours
  geom_contour(
    data = kdf,
    aes(x = intenA, y = intenB, z = log(density + 1e-6)),
    bins  = 6,
    color = "firebrick",
    size  = 0.7
  ) +
  
  # black axes at x=0, y=0
  geom_vline(xintercept = 0, color = "black", size = 1) +
  geom_hline(yintercept = 0, color = "black", size = 1) +
  
  # force axes to start at zero, no extra padding
  coord_cartesian(xlim = c(0, NA), ylim = c(0, NA), expand = FALSE) +
  
  # remove title, axis labels, legend
  labs(title = NULL, x = NULL, y = NULL) +
  guides(color = FALSE) +
  
  # theme tweaks
  theme_minimal() +
  theme(
    panel.grid.major    = element_blank(),
    panel.grid.minor    = element_blank(),
    panel.border        = element_blank(),
    aspect.ratio        = 1,
    
    # draw ticks & text only on the bottom & left
    axis.line          = element_blank(),         # turn off default
    axis.ticks.length = unit(5, "pt"),
    
    axis.text.x         = element_text(
      family = "Helvetica",
      size   = 14,
      color  = "black"
    ),
    axis.text.y         = element_text(
      family = "Helvetica",
      size   = 14,
      color  = "black"
    ),
    
    # but keep the ticks themselves
    axis.ticks.x       = element_line(color = "black"),
    axis.ticks.y       = element_line(color = "black")
  )

# ---- 4) Export as PDF  ----
pdf(
  file   = "Intensity_correlation.pdf",
  width  = 6,    # inches
  height = 6     # inches
)
print(p)
dev.off()

