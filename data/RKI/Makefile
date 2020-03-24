
SRC_FILES=$(wildcard *Rmd)

PDF_FILES=$(SRC_FILES:%.Rmd=%.pdf)
HTML_FILES=$(SRC_FILES:%.Rmd=%.html)

all : RKI_COVID19_Dresden.csv $(HTML_FILES) #$(PDF_FILES)

%.html : %.Rmd
		Rscript -e "rmarkdown::render('$<')"

fullpage-report.pdf : %.Rmd
		Rscript -e "rmarkdown::render('$<','pdf_document')"
		mv report.pdf $@

%.pdf : %.html
	node_modules/.bin/decktape -s 1920x1080 reveal $<\?fragments=true $@

clean :
		rm -fv $(PDF_FILES) $(HTML_FILES)

RKI_COVID19_Dresden.csv: RKI_COVID19.csv
	@csvgrep -c3 -m Dresden  $< > $@

echo :
	@echo ${HTML_FILES}
# %.csv : %.log
# 	awk -vFS=',' '{printf "%s,%s,%s,", $1,$2,$3;$1=$2=$3=""; gsub(/^[ \t]+/,"",$0); print $0}' $< > $@
