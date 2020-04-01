#!/usr/bin/env sh
assert_tools () {
	err=0
	while test $# -gt 0; do
		which $1 1>/dev/null 2>&1 || {
			1>&2 printf "tool missing: $1"
			err=$(( $err + 1 ))
		}
		shift
	done
	test $err -eq 0 || exit $err
}

# test for tools used
dependencies="printf cat cut rev test date sleep curl jq"
assert_tools $dependencies

while test "$#" -gt "0"; do
	case "$1" in
	*.json)
		jsonfn="$1"
		;;
	*.config)
		configfn="$1"
		;;
	*.csv)
		csvfn="$1"
		;;
	noquery)
		noquery="true"
		;;
	*)
		echo $1
		;;
	esac
	shift
done

# configuration file expecting e.g.
#~ result="data/de_dresden_www.csv"
#~ useragent="Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0"
#~ query1="https://services.arcgis.com/ORpvigFPJUhb8RDF/arcgis/rest/services/corona_DD_3/FeatureServer/0/query?f=json&where=Anzeige_Indikator%3D%27x%27&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&resultOffset=0&resultRecordCount=50&cacheHint=true"
#~ query2="https://services.arcgis.com/ORpvigFPJUhb8RDF/arcgis/rest/services/corona_DD_3/FeatureServer/0/query?f=json&where=Fallzahl%20IS%20NOT%20NULL&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&resultOffset=0&resultRecordCount=2000&cacheHint=true"
#~ #timestamp='+%Y-%m-%dT%H:%M:%S'
#~ csvheader="city,date,tod_hhmm,diagnosed,deceased,recovered,hospitalized"
#~ defaultentryplace="Dresden"
#~ defaultentrytod="12:00"
#~ jsonquery="'.features[] .attributes | { Datum, Fallzahl, Sterbefall, Genesungsfall, Hospitalisierung }'"

test -z "$configfn" && { configfn="data.config"; }

# for calling existing file, fallback test case
test -z "$jsonfn" && jsonfn="data/de_dresden_www.json"
# could test for existing file

# user agent
a=$(cat "$configfn" | grep -i "^useragent="|head -1|cut -d= -f2-|cut -d'"' -f2)
test -z "$a" && a="Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0"

# 1st request
url1=$(cat "$configfn" | grep -i "^query1="|head -1|cut -d= -f2-|cut -d'"' -f2)
test -z "$url1" && url1="https://services.arcgis.com/ORpvigFPJUhb8RDF/arcgis/rest/services/corona_DD_3/FeatureServer/0/query?f=json&where=Anzeige_Indikator%3D%27x%27&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&resultOffset=0&resultRecordCount=50&cacheHint=true"
# 2nd request, needs 1st request, otherwise satus code 400
url2=$(cat "$configfn" | grep -i "^query2="|head -1|cut -d= -f2-|cut -d'"' -f2)
test -z "$url2" && url2="https://services.arcgis.com/ORpvigFPJUhb8RDF/arcgis/rest/services/corona_DD_3/FeatureServer/0/query?f=json&where=Fallzahl%20IS%20NOT%20NULL&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&resultOffset=0&resultRecordCount=2000&cacheHint=true"

test -z "$csvheader" && { csvheader=$(cat "$configfn" | grep -i "^csvheader="|head -1|cut -d= -f2-|cut -d'"' -f2); }

test -z "$csvfn" && { csvfn=$(cat "$configfn" | grep -i "^csvfn="|head -1|cut -d= -f2-|cut -d'"' -f2); }
test -z "$csvfn" && { csvfn=$(printf "$jsonfn"|rev|cut -d. -f2-|rev)".csv"; }
test -z "$jsonfn" && { jsonfn=$(cat "$configfn" | grep -i "^jsonfn="|head -1|cut -d= -f2-|cut -d'"' -f2); }
test -z "$jsonfn" && { jsonfn=$(printf "$csvfn"|rev|cut -d. -f2-|rev)".json"; }
test -z "$jsonfn" && { csvfn="data/de_dresden_www.json"; }
test -z "$csvfn" && { jsonfn="data/de_dresden_www.csv"; }

test -z "$ts" && { ts=$(cat "$configfn" | grep -i "^timestamp="|head -1|cut -d= -f2-|cut -d'"' -f2); }

# disable query new file with cli option
test "$noquery" = "true" && { printf "ommiting web requets."; } || {

# alternative tool would be e.g. wget
# here call is silent, without checks on certificates and with custom user agent (browser name/version etc.)
curl -s -k -A "$a" "$url1" 2>&1 1>/dev/null
# wait a moment to not trigger some protection on server side
sleep 1 # although this doesnt seem to be necessarry at all
# write actual content to file $fn
curl -s -o "$jsonfn" -k -A "$a" "$url2"

}

# information on file names, print to stderr, assert on existing file
1>&2 printf "Reading from:\t%s\n" "$jsonfn"
test -f "$jsonfn" || { 1>&2 printf "file does not exist.\n"; exit 1; }
# output file with ISO timestamp in filename
# or no timestamp as prefix
test -z "$ts" || { path=$(printf "$csvfn"|rev|cut -d"/" -f2-|rev); csvfn=$(printf "$csvfn"|rev|cut -d"/" -f1|rev); csvfn="${path}/"$(date "$ts")"_$csvfn"; }
1>&2 printf "Writing to:\t$csvfn\n"

# check for file extension
test "$(printf "$jsonfn\n"|rev|cut -d. -f1|rev)" = "json" && {

# head line as found in csv of the repo
1>"$csvfn" printf "$csvheader\n"

# following values are assumed constant
# standard values for place and time
p=$(cat "$configfn" | grep -i "defaultentryplace="|head -1|cut -d= -f2-|cut -d'"' -f2)
# time of date, format H:M
c=$(cat "$configfn" | grep -i "defaultentrytod="|head -1|cut -d= -f2-|cut -d'"' -f2)

# process lines (each day) of the files, filter json with `jq`
for i in $(cat $jsonfn | jq -c '.features[] .attributes | { Datum, Fallzahl, Sterbefall, Genesungsfall, Hospitalisierung }');
do
	# numbers, may need fix in case NAN
	# n: number of cases
	n=$(printf "$i"|cut -d} -f1|cut -d, -f2|cut -d: -f2); test "$n" = "null" && n="0"
	# b: deceased
	b=$(printf "$i"|cut -d} -f1|cut -d, -f3|cut -d: -f2); test "$b" = "null" && b="0"
	# r: recovered
	r=$(printf "$i"|cut -d} -f1|cut -d, -f4|cut -d: -f2); test "$r" = "null" && r="0"
	# h: hospitalized
	h=$(printf "$i"|cut -d} -f1|cut -d, -f5|cut -d: -f2); test "$h" = "null" && h="0"
	# t: timestamp
	t=$(printf "$i"|cut -d} -f1|cut -d, -f1|cut -d: -f2|cut -d'"' -f2)
	# split timestamp in parts, if leading zero, reduce to single digits
	# d: day
	d=$(printf "$t"|cut -d"." -f1); test "$(printf "$d"|cut -c1)" = "0" && d=$(printf "$d"|cut -c2)
	# m: month
	m=$(printf "$t"|cut -d"." -f2); test "$(printf "$m"|cut -c1)" = "0" && m=$(printf "$m"|cut -c2)
	# y: year
	y=$(printf "$t"|cut -d"." -f3-); test "$(printf "$y"|cut -c1)" = "0" && y=$(printf "$y"|cut -c2)
	# fix year to 4 digits
	test "$y" -lt "100" && y=$(( 2000 + $y ));

	# output for csv
	# including more numbers
	1>>"$csvfn" printf "%s,%04d-%02d-%02d,%s,%s,%s,%s,%s\n" "$p" "$y" "$m" "$d" "$c" "$n" "$b" "$r" "$h"
	# csv as used by R script, number infected only
	#~ 1>>"$csvfn" printf "%s,%04d-%02d-%02d,%s,%s\n" "$p" "$y" "$m" "$d" "$c" "$n"

done
	
}
