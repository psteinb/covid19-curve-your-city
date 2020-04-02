
all : de_dresden_www_diagnosed.png de_dresden_www_hospitalized.png de_sachsen_sms_diagnosed.png de_leipzig_sms_diagnosed.png de_chemnitz_sms_diagnosed.png

de_dresden_www_diagnosed.png : data/de_dresden_www.csv
	@Rscript exponential.R -i $< -o $@

de_dresden_www_hospitalized.png : data/de_dresden_www.csv
	@Rscript exponential.R -i $< -c hospitalized -o $@

de_sachsen_sms_diagnosed.png : data/SMS/de_sachsen_sms.csv
	@Rscript exponential.R -i $< -o $@ -d 'Sachsen' -e 'Saxony, Germany' -T '[SMS by @dgerber]'

de_chemnitz_sms_diagnosed.png : data/SMS/de_chemnitz_sms.csv
	@Rscript exponential.R -i $< -o $@ -d 'Chemnitz' -e 'Chemnitz, Germany' -T '[SMS by @dgerber]'

de_leipzig_sms_diagnosed.png : data/SMS/de_leipzig_sms.csv
	@Rscript exponential.R -i $< -o $@ -d 'Leipzig' -e 'Leipzig, Germany' -T '[SMS by @dgerber]'
