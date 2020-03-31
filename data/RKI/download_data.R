#from https://github.com/nevrome/covid19germany
library(covid19germany)

#from cran
library(optparse)
library(readr)
library(dplyr)

## DEFINING COMMAND LINE INTERFACE
parser <- OptionParser()
option_list <- list(
  make_option(c('-o','--output'),
              default='RKI_COVID19.csv',
              help='output file RKI data [default %default]')#,
)
opts = parse_args(OptionParser(option_list=option_list))

if (is.null(opts$output)){
  print_help(parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

df = covid19germany::get_RKI_timeseries()
glimpse(df)
write.csv(df,opts$output)
