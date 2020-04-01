
all : de_plus7_diagnosed.png en_plus7_diagnosed.png de_plus7_hospitalized.png en_plus7_hospitalized.png

de_plus7_diagnosed.png : data/de_dresden_www.csv
	@Rscript exponential.R -L -i $< -o plus7_diagnosed.png

de_plus7_hospitalized.png : data/de_dresden_www.csv
	@Rscript exponential.R -L -i $< -c hospitalized -o plus7_hospitalized.png
