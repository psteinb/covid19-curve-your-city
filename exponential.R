library(ggplot2)
library(dplyr, warn.conflicts=FALSE)
library(readr)
library(optparse)

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
              help='output file name of plot [default %default]')
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

df = read.csv(opts$input)
df$date = as.Date(df$date)
df$day = as.integer(df$date - df$date[1])
glimpse(df)

model.expon = nls(diagnosed ~ a*(1+b)**(day),
                  data=df,
                  start = list(a = 1, b = 0.33)
                  )
model.expon

myplot = ggplot(df, aes(x=day, y=diagnosed)) +
  geom_point() +
  ggtitle("COVID19-Infectionen in Dresden") +
  xlab("Tag") + ylab("Diagnostiziert") +
  geom_line(aes(
                y=fitted(model.expon)
                ),
            color="red",
            linewidth=6) +
  mytheme

ggsave("exponential.png",myplot)

dfx = data.frame(day=0:(nrow(df)+6))
dfx$diagnosed = predict(model.expon,
                        list(day=dfx$day),
                        interval = "prediction")
dfx$date = df$date[1] + dfx$day
glimpse(dfx)

myplot = ggplot(dfx, aes(x=day, y=diagnosed)) +
  geom_line(color="red",
            linewidth=6) +
  ggtitle("COVID19-Infektionen in Dresden",
          subtitle="https://github.com/psteinb/covid19-extrapol") +
  xlab("Tag") + ylab("Diagnostiziert") +
  xlim(0,nrow(df)+7) +
  geom_point(aes(
    x=day,
    y=diagnosed
  ),data=df) +
  geom_label(data=dfx %>% filter(day>nrow(df)-1),
             aes(label=round(diagnosed)),
             hjust="outward"
             )+
  geom_label(data=dfx %>% filter(day>nrow(df)-1),
             aes(label=date),
             hjust="inward"
             ) +
  geom_line(aes(y = lwr), color = "red", linetype = "dashed") +
  geom_line(aes(y = upr), color = "red", linetype = "dashed")
  mytheme

ggsave(opts$output,myplot)
