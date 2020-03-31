# this file explores the capabilities of R with respect to non-linear least square fitting

library(ggplot2)
library(dplyr)
library(readr)

## We create an arbitrary function

df = data.frame(x = seq(0,12,by=1))
df$y = 2*(1+.33)**df$x


myplot = ggplot(df, aes(x, y)) +
  geom_point() +
  ggtitle("synthetic infections in Dresden, Germany") +
  geom_smooth(method = "nls",
              method.args = list(formula = y ~ a*(1+b)**(x),
                                 start = list(a = 1, b = 0.33)),
              data = df,
              se = FALSE)

ggsave("ref.png",myplot)

## We "noise" to the data by drawing from a normal distribution
## with mean 1 and standard deviated 0.2 and multiplying all data
## with this number
df$ny = df$y*rnorm(nrow(df),mean=1, sd=.2)

## we create the model ny = f(x) = a*(1+b)**(x)
## the ~ character tells R that this is to be interpreted
## in a special mannor
fit = nls(ny ~ a*(1+b)**(x),
          data=df,
          start = list(a = 1, b = 0.33)
          )

# print the results
cat("our fit:\n")
fit
# print the summary of the fit
cat("our summary(fit):\n")
summary(fit)
# print only the coefficients
cat("our coef(fit):\n")
coef(fit)
# print the residuals
cat("our residuals(fit):\n")
residuals(fit)
df$nyres = residuals(fit)
df$nyf = fitted(fit)

df$nyres_min = ifelse(df$nyres > 0,df$nyf, df$nyf + df$nyres)
df$nyres_max = ifelse(df$nyres > 0,df$nyf + df$nyres, df$nyf)

cat("plot the fit with the data\n")
myplot = ggplot(df, aes(x, ny)) +
  geom_point() +
  ggtitle("synthetic infections") +
  geom_line(aes(y=fitted(fit)), color="red") +
  geom_linerange(aes(ymin = nyres_min, ymax = nyres_max), color="blue")
ggsave("nref.png",myplot)
