# Extrapolierte COVID19-Infektionen

## Dresden 

### Deutsch 

![](de_plus5.png)

Datenquelle: [dresden.de](https://www.dresden.de/de/leben/gesundheit/hygiene/infektionsschutz/corona.php)

### English

![](en_plus5.png)

data source: [dresden.de](https://www.dresden.de/de/leben/gesundheit/hygiene/infektionsschutz/corona.php)

# Reproduziere das!

## German

1. [R installieren](https://www.r-project.org)
2. Abhängigkeiten installieren

``` r
> install.packages(c("ggplot2","dplyr","readr","optparse"))
```

3. `exponential.R`-Script laufen lassen

``` 
$ Rscript exponential.R -i de_dresden.csv
```

4. Dies produziert zwei Dateien `de_plus5.png` und `en_plus5.png`.

## English

1. [install R](https://www.r-project.org)
2. install dependencies

``` r
> install.packages(c("ggplot2","dplyr","readr","optparse"))
```

3. run `exponential.R` script

``` 
$ Rscript exponential.R -i de_dresden.csv
```

4. this produces 2 files: `de_plus5.png` and `en_plus5.png` that contain the plots based on `de_dresden.csv`
