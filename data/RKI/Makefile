
SRC_FILES=$(wildcard *Rmd)

PDF_FILES=$(SRC_FILES:%.Rmd=%.pdf)
HTML_FILES=$(SRC_FILES:%.Rmd=%.html)

all : rki_de_dresden.csv $(HTML_FILES) #$(PDF_FILES)

%.html : %.Rmd RKI_COVID19_Dresden.csv
		Rscript -e "rmarkdown::render('$<')"

fullpage-report.pdf : %.Rmd
		Rscript -e "rmarkdown::render('$<','pdf_document')"
		mv report.pdf $@

%.pdf : %.html
	node_modules/.bin/decktape -s 1920x1080 reveal $<\?fragments=true $@

rki_de_dresden.csv : fill_the_gap.html

clean :
		rm -fv $(PDF_FILES) $(HTML_FILES)

RKI_COVID19_Dresden.csv: RKI_COVID19.csv
	@csvgrep -c3 -m Dresden  $< > $@

echo :
	@echo ${HTML_FILES}
