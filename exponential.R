#!/usr/bin/env Rscript
library(ggplot2)
library(dplyr, warn.conflicts=FALSE)
library(readr)
library(optparse)
library(cowplot, warn.conflicts=FALSE)
library(lubridate, warn.conflicts=FALSE)
library(nls2)

## DEFINING COMMAND LINE INTERFACE
parser <- OptionParser(## description='process COVID19 data'
)
option_list <- list(
  make_option(c('-i','--input'),
              type="character",
              action="store",
              default="data/de_dresden_www.csv",
              help='an csv file with COVID19 diagnosed cases [default %default]'),

  make_option(c('-o','--output'),
              default='plus7.png',
              help='output file name of plot [default %default]'),

  make_option(c('-c','--column'),
              default='diagnosed',
              help='column in .csv input to plot [default %default]'),

  make_option(c('-d','--deLabel'),
              default='Dresden',
              help='the name of the region under investigation in German [default %default]'),

  make_option(c('-e','--enLabel'),
              default='Dresden, Germany',
              help='the name of the region under investigation in English [default %default]'),

  make_option(c('-T','--titleextra'),
              default='[dresden.de]',
              help='add this to the title [default %default]'),

  make_option(c('-L','--onlylinear'),
              action="store_true",
              default=FALSE,
              help='include a logscale plot in a second column [default %default]')
)
opts = parse_args(OptionParser(option_list=option_list))

if (is.null(opts$input)){
  print_help(parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

mytheme = theme_bw(base_size=20)##  + theme(
    ## ##text = element_text(family = "Decima WE", color = "grey20"),
    ## ## strip.background = element_blank(),
    ## ## strip.text = element_text(hjust = 0),
    ## ## panel.grid.major = element_line(colour="grey50",size=0.35),
    ## ## panel.grid.minor = element_blank(),
    ## ## plot.margin=unit(c(0,1,0,1),"cm"),
    ## legend.position="top",
    ## plot.caption=element_text(hjust=1,size=14,colour="grey30"),
    ## plot.subtitle=element_text(face="italic",size=14,colour="grey40"),
    ## plot.title=element_text(size=18,face="bold")
## )

## THE MODEL TO FIT

df = read.csv(opts$input)

colid = which( colnames(df)== opts$column )
if (colid > 0){
  df$ydata = df[,colid]
} else {
  stop(cat("column",opts$column,"not found in",
           opts$input,"\navailable:",colnames(df)),
       call.=FALSE)
}

df$date = as.Date(df$date)
df$day = as.integer(df$date - df$date[1])
df

print(">>nls<<: ydata ~ a*(1+b)**(day)")
exponf = function(day, a, b){
  return(a*(1+b)**(day))
}
form = ydata ~ a*(1+b)**(day)
model.expon = nls(form,
                  data=df,
                  start = list(a = 1, b = 0.33)
                  )
summary(model.expon)

#based on http://rocs.hu-berlin.de/corona/docs/forecast/model/
#a: is the reproduction rate of the process which quantifies how many of
#   the potential susceptible-infectious contacts lead to new infections per day.
#b: quantifying the number of infected people that cease to take part
#   in the transmission process per day.
print(">>nls<<: ydata ~ a*exp(b*day) + c")
siredf = function(day,a,b,c){
  return(a*exp(b*day) + c)
}
form = ydata ~ a*exp(b*day) + c
model.sired = nls(form,
                  data=df,
                  start = list(a = 10,
                               b = 0.33,
                               c = 0
                               )
                  )
summary(model.sired)

##############
## GERMAN PLOT
offset_1d = 1
offset_1w = 7

last_day = df$day[length(df$day)]
dfx = data.frame(day=seq(0,(last_day+offset_1w), by=1))


## the fitted parameters
value.a = summary(model.sired)$coefficients[1,1]
value.b = summary(model.sired)$coefficients[2,1]
value.c = summary(model.sired)$coefficients[3,1]


## the fitted parameter uncertainties
unc.a = summary(model.sired)$coefficients[1,2]
unc.b = summary(model.sired)$coefficients[2,2]
unc.c = summary(model.sired)$coefficients[3,2]


dfx$ydata = predict(model.sired,
                    list(day=dfx$day),
                    se.fit = T)


df$ydata_residuals = residuals(model.sired)

dfx$upr = siredf(dfx$day,
                 value.a + unc.a,
                 value.b + unc.b,
                 value.c + unc.c
                 )

dfx$lwr = siredf(dfx$day,
                 value.a - unc.a,
                 value.b - unc.b,
                 value.c - unc.c
                 )


dfx$date = df$date[1] + dfx$day

dfx

sprintf("tomorrow, day %i",last_day+1)
#td = today()

tmr = dfx %>% filter(day == last_day+1)
tmr

sprintf("1 week from now, day %i",last_day+offset_1w)
onew = dfx %>% filter(day == (last_day+offset_1w))
onew


myplot = ggplot(dfx, aes(x=day, y=ydata)) +
  ggtitle(paste("Prognose der COVID19-Fälle",opts$column,"in", opts$deLabel, opts$titleextra),
          subtitle="github.com/psteinb/covid19-curve-your-city") +
  xlab("Tag der Aufzeichnung") + ylab(paste("#",opts$column,"Fälle")) +
  xlim(0,onew$day[1]) +
  geom_ribbon(aes(ymin = lwr, ymax = upr), fill = "grey70") +
  geom_line(color="red",
            linewidth=6) +
  geom_point(aes(
    x=day,
    y=ydata
  ),data=df)  +
  ############### LABEL TOMORROW ################
  annotate("segment",
           x = tmr$day[1]-3, xend = tmr$day[1],
           y = tmr$ydata[1],
           yend = tmr$ydata[1],
           colour = "red",
           arrow = arrow(length = unit(2, "mm"))) +

  geom_label(data=tmr,
             aes(label=c(paste(paste(day(date),month(date),":",sep="."),
                               "(",round(lwr),"<",round(ydata),"<",round(upr),")"

                               )
                         )
                 ),
             hjust="inward",
             nudge_x = -3
             ) +

  ############### LABEL 1 WEEK FROM NOW ################
  annotate("segment",
           x = onew$day[1]-5, xend = onew$day[1],
           y = onew$ydata[1],
           yend = onew$ydata[1],
           colour = "red",
           arrow = arrow(length = unit(2, "mm")),
           arrow.fill = "red"
           )+

  geom_label(data=onew,
             aes(label=c(paste(paste(day(date),month(date),":",sep="."),
                               "(",round(lwr),"<",round(ydata),"<",round(upr),")"

                               )
                         )
                 ),
             hjust="inward",
             nudge_x = -2
             )+
  ### THEME
  mytheme

output_name = paste("de",opts$output,sep="_")

##
if (!opts$onlylinear){

  print("plotting linear and log scale")

  #remove title
  myplot = myplot + theme(
    plot.title = element_blank(),
    plot.subtitle = element_blank()## ,
    ## axis.title.x = element_blank(),
    ## axis.title.y = element_blank()
  )

  logscaleplot = myplot
  logscaleplot = logscaleplot +
    scale_y_continuous(trans = "log10") +
    theme(plot.title = element_blank(),
          plot.subtitle = element_blank(),
          axis.title.y = element_blank())

  #put 2 plots into 1 horizontally row side-by-side
  gridplots = plot_grid(myplot, logscaleplot,
                        labels = c('linear', 'logarithmisch'),
                        label_fontface = "plain",
                        label_y = 1.03,
                        label_x = c(.10,.0)+.4,
                        ## hjust = -.1,
                        label_size = 16)

  # now add the title, see https://wilkelab.org/cowplot/articles/plot_grid.html
  title <- ggdraw() +
    draw_label(
      paste("Prognose der COVID19-Fälle",opts$column,"in",opts$deLabel,opts$titleextra),
      size = 24,
      x = 0,
      hjust = 0
    ) +
    theme(
      # add margin on the left of the drawing canvas,
      # so title is aligned with left edge of first plot
      plot.margin = margin(0, 0, 0, 7)
    )

  subtitle <- ggdraw() +
    draw_label(
      "https://github.com/psteinb/covid19-curve-your-city, CC-BY 4.0",
      size = 16,
      x = .5## ,
      ## hjust = -1
    ) +
    theme(
      # add margin on the left of the drawing canvas,
      # so title is aligned with left edge of first plot
      plot.margin = margin(0, 0, 0, 7)
    )

  mycanvas = plot_grid(
    title, gridplots, subtitle,
    ncol = 1,
    # rel_heights values control vertical title margins
    rel_heights = c(0.12, 1, .075)
  )

  ggsave(output_name,mycanvas, width = 12, height = 6.5)
} else {
  ggsave(output_name,myplot)
}


###############q
## ENGLISH PLOT

en_myplot = ggplot(dfx, aes(x=day, y=ydata)) +
  ggtitle(paste("Prognosis of COVID19 cases",opts$column,"in",opts$enLabel,opts$titleextra),
          subtitle="github.com/psteinb/covid19-curve-your-city") +
  xlab("Day of Record") + ylab(paste("# of",opts$column,"Cases")) +
  xlim(0,onew$day) +
  geom_ribbon(aes(ymin = lwr, ymax = upr), fill = "grey70") +
  geom_line(color="red",
            linewidth=6) +
  geom_point(aes(
    x=day,
    y=ydata
  ),data=df) +
  ############### LABEL TOMORROW ################
  annotate("segment",
           x = tmr$day[1]-3, xend = tmr$day[1],
           y = tmr$ydata[1],
           yend = tmr$ydata[1],
           colour = "red",
           arrow = arrow(length = unit(2, "mm"))) +

  geom_label(data=tmr,
             aes(label=c(paste(paste(month(date),"/",day(date),":",sep=""),
                               "(",round(lwr),"<",round(ydata),"<",round(upr),")"

                               )
                         )
                 ),
             hjust="inward",
             nudge_x = -3
             ) +

  ############### LABEL 1 WEEK FROM NOW ################
  annotate("segment",
           x = onew$day[1]-5, xend = onew$day[1],
           y = onew$ydata[1],
           yend = onew$ydata[1],
           colour = "red",
           arrow = arrow(length = unit(2, "mm")),
           arrow.fill = "red"
           )+

  geom_label(data=onew,
             aes(label=c(paste(paste(month(date),"/",day(date),":",sep=""),
                               "(",round(lwr),"<",round(ydata),"<",round(upr),")"

                               )
                         )
                 ),
             hjust="inward",
             nudge_x = -2
             )+
  ### THEME
  mytheme

output_name = paste("en",opts$output,sep="_")

##
if (!opts$onlylinear){

  print("plotting linear and log scale [EN]")

  #remove title
  en_myplot = en_myplot + theme(
    plot.title = element_blank(),
    plot.subtitle = element_blank()## ,
    ## axis.title.x = element_blank(),
    ## axis.title.y = element_blank()
  )

  logscaleplot = en_myplot
  logscaleplot = logscaleplot +
    scale_y_continuous(trans = "log10") +
    theme(plot.title = element_blank(),
          plot.subtitle = element_blank(),
          axis.title.y = element_blank())

  #put 2 plots into 1 horizontally row side-by-side
  gridplots = plot_grid(en_myplot, logscaleplot,
                        labels = c('linear', 'logarithmic'),
                        label_fontface = "plain",
                        label_y = 1.03,
                        label_x = c(.10,.0)+.4,
                        ## hjust = -.1,
                        label_size = 16)

  # now add the title, see https://wilkelab.org/cowplot/articles/plot_grid.html
  title <- ggdraw() +
    draw_label(
      paste("Prognosis of COVID19 cases",opts$column,"in",opts$enLabel,opts$titleextra),
      size = 24,
      x = 0,
      hjust = 0
    ) +
    theme(
      # add margin on the left of the drawing canvas,
      # so title is aligned with left edge of first plot
      plot.margin = margin(0, 0, 0, 7)
    )

  subtitle <- ggdraw() +
    draw_label(
      "https://github.com/psteinb/covid19-curve-your-city, CC-BY 4.0",
      size = 16,
      x = .5## ,
      ## hjust = -1
    ) +
    theme(
      # add margin on the left of the drawing canvas,
      # so title is aligned with left edge of first plot
      plot.margin = margin(0, 0, 0, 7)
    )

  mycanvas = plot_grid(
    title, gridplots, subtitle,
    ncol = 1,
    # rel_heights values control vertical title margins
    rel_heights = c(0.12, 1, .075)
  )

  ggsave(output_name,mycanvas, width = 12, height = 6.5)
} else {
  ggsave(output_name,en_myplot)
}

## For the statistics fans
chi2 = sum(df$ydata_residuals**2)/sd(df$ydata_residuals)**2
cat(">> ndf=", nrow(df) - 2 -1,"chi2:", chi2,"\n")
chi2_ndf = chi2/(nrow(df) - 2 -1)

resids = ggplot(df, aes(ydata_residuals)) +
  geom_histogram() +
  ggtitle("Residuals of the exponential fit",
          subtitle = sprintf("mean: %2.2f, med: %2.2f, std: %2.2f, chi2/ndf: %2.3f",
                             mean(df$ydata_residuals),
                             median(df$ydata_residuals),
                             sd(df$ydata_residuals),
                             chi2_ndf
                           )) +
  xlab("Residuals: X - predicted(X)") + ylab("N") +
  mytheme

ggsave(paste("residuals",opts$output,sep="_"), width=8,height=5)
