library(ggplot2)
library(dplyr, warn.conflicts=FALSE)
library(readr)
library(optparse)
library(cowplot)
library(lubridate)
library(nls2)

## DEFINING COMMAND LINE INTERFACE
parser <- OptionParser(## description='process COVID19 data'
)
option_list <- list(
  make_option(c('-i','--input'),
              type="character",
              action="store",
              default="de_dresden.csv",
              help='an csv file with COVID19 diagnosed cases [default %default]'),
  make_option(c('-o','--output'),
              default='plus5.png',
              help='output file name of plot [default %default]'),
  make_option(c('-d','--deLabel'),
              default='Dresden',
              help='the name of the region under investigation in German [default %default]'),
  make_option(c('-e','--enLabel'),
              default='Dresden, Germany',
              help='the name of the region under investigation in English [default %default]'),
  make_option(c('-T','--titleextra'),
              default='',
              help='add this to the title [default %default]'),
  make_option(c('-L','--logscale'),
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
df$date = as.Date(df$date)
df$day = as.integer(df$date - df$date[1])
df

print(">>nls<<: diagnosed ~ a*(1+b)**(day)")
model.expon = nls(diagnosed ~ a*(1+b)**(day),
                  data=df,
                  start = list(a = 1, b = 0.33)
                  )
summary(model.expon)

#based on http://rocs.hu-berlin.de/corona/docs/forecast/model/
#a: is the reproduction rate of the process which quantifies how many of
#   the potential susceptible-infectious contacts lead to new infections per day.
#b: quantifying the number of infected people that cease to take part
#   in the transmission process per day.
print(">>nls<<: diagnosed ~ a*exp(b*day)")
model.sired = nls(diagnosed ~ a*exp(b*day),
                  data=df,
                  start = list(a = 10, b = 0.33)
                  )
summary(model.sired)


## creating the error bands
upr.a = summary(model.expon)$coefficients[1,1] + summary(model.expon)$coefficients[1,2]
upr.b = summary(model.expon)$coefficients[2,1] + summary(model.expon)$coefficients[2,2]
lwr.a = summary(model.expon)$coefficients[1,1] - summary(model.expon)$coefficients[1,2]
lwr.b = summary(model.expon)$coefficients[2,1] - summary(model.expon)$coefficients[2,2]

supr.a = summary(model.sired)$coefficients[1,1] + summary(model.sired)$coefficients[1,2]
supr.b = summary(model.sired)$coefficients[2,1] + summary(model.sired)$coefficients[2,2]
slwr.a = summary(model.sired)$coefficients[1,1] - summary(model.sired)$coefficients[1,2]
slwr.b = summary(model.sired)$coefficients[2,1] - summary(model.sired)$coefficients[2,2]

##############
## GERMAN PLOT
offset_1d = 1
offset_1w = 7

dfx = data.frame(day=0:(nrow(df)+offset_1w))
dfx$diagnosed = predict(model.expon,
                        list(day=dfx$day),
                        se.fit = T)

dfx$diagnosed_sir = predict(model.sired,
                        list(day=dfx$day),
                        se.fit = T)

dfx$upr = upr.a*(1+upr.b)**(dfx$day)
dfx$lwr = lwr.a*(1+lwr.b)**(dfx$day)


dfx$date = df$date[1] + dfx$day

dfx

print("tomorrow")
td = today()
tmr = dfx %>% filter(day == nrow(df))
tmr

print("1 week from now")
onew = dfx %>% filter(day == (df$day[nrow(df)]+offset_1w))
onew

myplot = ggplot(dfx, aes(x=day, y=diagnosed)) +
  ggtitle(paste("Prognose der COVID19-Diagnosen in", opts$deLabel, opts$titleextra),
          subtitle="github.com/psteinb/covid19-curve-your-city") +
  xlab("Tag der Aufzeichnung") + ylab("# Diagnostizierte Fälle") +
  xlim(0,onew$day[1]) +
  geom_ribbon(aes(ymin = lwr, ymax = upr), fill = "grey70") +
  geom_line(color="red",
            linewidth=6) +
  geom_point(aes(
    x=day,
    y=diagnosed
  ),data=df)  +
  ############### LABEL TOMORROW ################
  annotate("segment",
           x = tmr$day[1]-3, xend = tmr$day[1],
           y = tmr$diagnosed[1],
           yend = tmr$diagnosed[1],
           colour = "red",
           arrow = arrow(length = unit(2, "mm"))) +

  geom_label(data=tmr,
             aes(label=c(paste(date,":",
                               "(",round(lwr),"<",round(diagnosed),"<",round(upr),")"

                               )
                         )
                 ),
             hjust="inward",
             nudge_x = -3
             ) +

  ############### LABEL 1 WEEK FROM NOW ################
  annotate("segment",
           x = onew$day[1]-5, xend = onew$day[1],
           y = onew$diagnosed[1],
           yend = onew$diagnosed[1],
           colour = "red",
           arrow = arrow(length = unit(2, "mm")),
           arrow.fill = "red"
           )+

  geom_label(data=onew,
             aes(label=c(paste(date,":",
                               "(",round(lwr),"<",round(diagnosed),"<",round(upr),")"

                               )
                         )
                 ),
             hjust="inward",
             nudge_x = -2
             )+
  ## geom_label(data=dfx %>% filter(day == nrow(df)),
  ##            aes(label=date),
  ##            hjust="inward",
  ##            nudge_x = -10,
  ##            nudge_y = .5
  ##            ) +
  mytheme

output_name = paste("de",opts$output,sep="_")

##
if (!is.null(opts$logscale)){

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
      paste("Prognose der COVID19-Diagnosen in",opts$deLabel,opts$titleextra),
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

en_myplot = ggplot(dfx, aes(x=day, y=diagnosed)) +
  ggtitle(paste("Prognosis of COVID19 diagnoses in",opts$enLabel,opts$titleextra),
          subtitle="github.com/psteinb/covid19-curve-your-city") +
  xlab("Day of Record") + ylab("# Diagnosed Cases") +
  xlim(0,nrow(df)+7) +
  geom_ribbon(aes(ymin = lwr, ymax = upr), fill = "grey70") +
  geom_line(color="red",
            linewidth=6) +
  geom_point(aes(
    x=day,
    y=diagnosed
  ),data=df) +

  annotate("segment",
           x = nrow(df)-2, xend = nrow(df),
           y = dfx$diagnosed[nrow(df)+1], yend = dfx$diagnosed[nrow(df)+1],
           colour = "red",
           arrow = arrow(length = unit(2, "mm"))) +

  geom_label(data=dfx %>% filter(day == nrow(df)),
             aes(label=c(paste(dfx$date[nrow(df)],":",
                               "(",round(lwr),"<",round(diagnosed),"<",round(upr),")"

                               )
                         )
                 ),
             hjust="inward",
             nudge_x = -2
             ) +

  annotate("segment",
           x = nrow(df)+7-2, xend = nrow(df)+7,
           y = dfx$diagnosed[nrow(df)+7], yend = dfx$diagnosed[nrow(df)+7],
           colour = "red",
           arrow = arrow(length = unit(2, "mm")),
           arrow.fill = "red"
           )+

  geom_label(data=dfx %>% filter(day == nrow(df)+7),
             aes(label=c(paste(dfx$date[nrow(df)+7],":",
                               "(",round(lwr),"<",round(diagnosed),"<",round(upr),")"

                               )
                         )
                 ),
             hjust="inward",
             nudge_x = -2
             )+
  ## geom_label(data=dfx %>% filter(day == nrow(df)),
  ##            aes(label=date),
  ##            hjust="inward",
  ##            nudge_x = -10,
  ##            nudge_y = .5
  ##            ) +
  mytheme

output_name = paste("en",opts$output,sep="_")

##
if (!is.null(opts$logscale)){

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
      paste("Prognosis of COVID19 diagnoses in",opts$enLabel,opts$titleextra),
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
