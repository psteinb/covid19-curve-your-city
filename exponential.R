library(ggplot2)
library(dplyr)
library(readr)

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

df = read.csv("by_city.csv")
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

dfx = data.frame(day=1:(nrow(df)+5))
dfx$diagnosed = predict(model.expon,list(day=1:(nrow(df)+5)))

myplot = ggplot(dfx, aes(x=day, y=diagnosed)) +
  geom_line(color="red",
            linewidth=6) +
  ggtitle("COVID19-Infektionen in Dresden") +
  xlab("Tag") + ylab("Diagnostiziert") +
  geom_point(aes(
    x=day,
    y=diagnosed
  ),data=df) +
  mytheme

ggsave("plus5.png",myplot)
