# Extrapolierte COVID19-Infektionen

## Warum machst du das? / Why are you doing this?

Ich bin kein Virologe noch ein Epidemiologe. Ich bin langjähriger [HPC](https://de.wikipedia.org/wiki/Supercomputer)-Nutzer, [Research Software Engineer](https://en.wikipedia.org/wiki/Research_software_engineering), Datenwissenschaftler und Machine-Learning-Praktiker.

Ich habe dieses Projekt ins Leben gerufen, um mit meinen mentalen Mitteln die Pandemie und den Virus zu verstehen und vielleicht ein Beitrag bei der Wissensvermittlung zu leisten.

---

I am no virologist and no epidemioligist. I am a seasoned [HPC](https://en.wikipedia.org/wiki/Supercomputer) user, [Research Software Engineer](https://en.wikipedia.org/wiki/Research_software_engineering), data scientist and machine learner practitioner. 

I created this project, to try to understand the SARS-COV-2 virus and the pandemic with my mental tools. I hope to potentially contribute to the communication of knowledge and results.

# Exponentielles Modell / Exponential Model

Die folgenden Grafiken versuchen ein exponentielles Modell an die Daten für Dresden anzupassen (techn. zu fitten). Diesem Modell liegen einige Annahmen zugrunde:

- die Zahl der für den Virus empfänglichen Personen ist unbegrenzt
- die Genesungsrate ist verschwindend klein oder `0`

Vgl. auch [lernapparat.de/epidemiologie-sir](http://lernapparat.de/epidemiologie-sir/) für eine tiefere Diskussion. Die Daten zeigen, dass diese Annahmen zunehmend in der Wirklichkeit verletzt werden und damit der Fit mit einem exponentiellen Modell schrittweise seine Aussagekraft mehr hat.

---

The following plots try to fit an exponential model to the data of Dresden, Germany. This model has several assumptions underlying such as:

- the number of susceptible persons is unlimited
- the rate of recovery is `0` or vanishingly small

See also [lernapparat.de/epidemiology-sir](http://lernapparat.de/epidemiology-sir/) for in-depth discussion. The data shows that these assumptions are increasingly violated by reality and therefor the fit with an exponential model looses any basis for interpretation.


## COVID19 Im Krankenhaus / Hospitalized

![](de_de_dresden_www_hospitalized.png)
![](en_de_dresden_www_hospitalized.png)

Datenquelle/data source: [dresden.de](https://www.dresden.de/de/leben/gesundheit/hygiene/infektionsschutz/corona.php)


## COVID19-Diagnosen / Diagnoses

### Dresden

![](de_de_dresden_www_diagnosed.png)
![](en_de_dresden_www_diagnosed.png)

Datenquelle/data source: [dresden.de](https://www.dresden.de/de/leben/gesundheit/hygiene/infektionsschutz/corona.php)


### Sachsen

![](de_de_sachsen_sms_diagnosed.png)
![](en_de_sachsen_sms_diagnosed.png)

Datenquelle/data source: [SMS by @dgerber](https://danielgerber.eu/2020/03/22/corona-zahlen-in-sachsen/)



## Statistik

### Deutsch

Für die rote Linie im o.g. Plot benutze ich ein sehr einfaches Modell: das [exponentiellen Wachstum](https://de.wikipedia.org/wiki/Exponentielles_Wachstum) der COVID19-Pandemie. Ich fitte die Daten mit einem [Least-Squares-Verfahren](https://de.wikipedia.org/wiki/Methode_der_kleinsten_Quadrate) entsprechend der Formel für das Modell:

``` r
diagnosed ~ a*exp(b*day)
```

Wobei `a` und `b` freie Parameter sind.

### English

For the red line in the plot above, I use a simple model: the [exponential growth](https://en.wikipedia.org/wiki/Exponential_growth) of the COVID19 pandemia. I fit the data using a [Least Squares Algorithm](https://en.wikipedia.org/wiki/Least_squares) using the formula of the model:

``` r
diagnosed ~ a*exp(b*day)
```

Here `a` and `b` are free parameters.

# Reproduziere das!

## German

1. [R installieren](https://www.r-project.org)
2. Abhängigkeiten interaktiv installieren

``` shell
$ R
> install.packages(c("ggplot2","dplyr","readr","optparse", "cowplot","lubridate"))
> quit(save="default",status=0,runLast=TRUE)
```

3. `exponential.R`-Script laufen lassen

``` shell
$ Rscript exponential.R -i data/de_dresden_www.csv
```

4. Dies produziert drei Dateien `de_plus7.png`, `en_plus7.png` und `residuals_plus7.png`, die die Plots basierend auf `data/de_dresden_www.csv` beinhalten.

## English

1. [install R](https://www.r-project.org)
2. install dependencies interactively

``` shell
$ R
> install.packages(c("ggplot2","dplyr","readr","optparse", "cowplot","lubridate"))
> quit(save="default",status=0,runLast=TRUE)
```

3. run `exponential.R` script

``` shell
$ Rscript exponential.R -i de_dresden.csv
```

4. this produces 3 files: `de_plus7.png`, `en_plus7.png` and `residuals_plus7.png` that contain the plots based on `data/de_dresden_www.csv`

## For Statistics Fans

### Residuals

My fit uses a simple exponential function. It is important to have a look at the residuals according to the same ordering as above.

![](residuals_de_dresden_www_hospitalized.png)
![](residuals_de_dresden_www_diagnosed.png)
![](residuals_de_sachsen_sms_diagnosed.png)

The `nls` fit that I use, assumes that the data follows a Gaussian around the predicted values. The above plot looks like a very wide spread Gaussian. On top, there is a strong tendency towards positive values.

The plot above lists a parameter by the name `chi2/ndf`, if this is close to `1`, then the fit can be considered good. For more details, see the [wikipedia page on errors and residuals](https://en.wikipedia.org/wiki/Errors_and_residuals).

### Uncertainties

As I am using the standard uncertainties for all parameters from `nls` in R, these are 1 standard deviation uncertainties directly obtained from the square root of diagonal elements of the covariance matrix.
