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

dfx = data.frame(day=0:(nrow(df)+6))
dfx$diagnosed = predict(model.expon,list(day=dfx$day))
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
  mytheme

ggsave("plus5.png",myplot)
