#from https://github.com/nevrome/covid19germany
library(covid19germany)
library(optparse)
library(readr)
library(dplyr)

## DEFINING COMMAND LINE INTERFACE
parser <- OptionParser(## description='process COVID19 data'
)
option_list <- list(
  make_option(c('-o','--output'),
              default='RKI_COVID19.csv',
              help='output file RKI data [default %default]')#,
  ## make_option(c('-T','--titleextra'),
  ##             default='',
  ##             help='add this to the title [default %default]'),
  ## make_option(c('-L','--logscale'),
  ##             action="store_true",
  ##             default=FALSE,
  ##             help='include a logscale plot in a second column [default %default]')
)
opts = parse_args(OptionParser(option_list=option_list))

if (is.null(opts$output)){
  print_help(parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

df = covid19germany::get_RKI_timeseries()
glimpse(df)
write.csv(df,opts$output)
