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

# for calling existing file, fallback test case
test -z $1 && fn="g.json" || fn="$1"
# could test for existing file

# disable query new file with cli option
test "$2" = "noquery" || {

# user agent
a="Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0"
# 1st request
url1="https://services.arcgis.com/ORpvigFPJUhb8RDF/arcgis/rest/services/corona_DD_3/FeatureServer/0/query?f=json&where=Anzeige_Indikator%3D%27x%27&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&resultOffset=0&resultRecordCount=50&cacheHint=true"
# 2nd request, needs 1st request, otherwise satus code 400
url2="https://services.arcgis.com/ORpvigFPJUhb8RDF/arcgis/rest/services/corona_DD_3/FeatureServer/0/query?f=json&where=Fallzahl%20IS%20NOT%20NULL&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&resultOffset=0&resultRecordCount=2000&cacheHint=true"

# alternative tool: wget
# here call is silent, without checks on certificates and with custom user agent (browser name/version etc.)
curl -s -k -A "$a" "$url1" 2>&1 1>/dev/null
# wait a moment to not trigger some protection on server side
sleep 1 # although this doesnt seem to be necessarry at all
# write actual content to file $fn
curl -s -o "$fn" -k -A "$a" "$url2"

}

# information on file names, print to stderr, assert on existing file
1>&2 printf "Reading from: %s\n" "$fn"
test -f "$fn" || { 1>&2 printf "file does not exist.\n"; exit 1; }
# output file with ISO timestamp in filename
tf=$(date '+%Y-%m-%dT%H:%M:%S')"_"$(printf "$fn"|rev|cut -d. -f2-|rev)".csv"
1>&2 printf "Writing to: $tf\n"

# check for file extension
test "$(printf "$fn\n"|rev|cut -d. -f1|rev)" = "json" && {

# head line as found in csv of the repo
1>"$tf" printf "city,date,tod_hhmm,diagnosed,deceased,recovered,hospitalized"
# csv header as used in R script
#~ 1>"$tf" printf "city,date,tod_hhmm,diagnosed"

# following values are assumed constant
# standard values for place and time
p="Dresden"
c="12:00" # time of date, format H:M

# process lines (each day) of the files, filter json with `jq`
for i in $(cat $fn | jq -c '.features[] .attributes | { Datum, Fallzahl, Sterbefall, Genesungsfall, Hospitalisierung }');
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
	1>>"$tf" printf "%s,%04d-%02d-%02d,%s,%s,%s,%s,%s\n" "$p" "$y" "$m" "$d" "$c" "$n" "$b" "$r" "$h"
	# csv as used by R script, number infected only
	#~ 1>>"$tf" printf "%s,%04d-%02d-%02d,%s,%s\n" "$p" "$y" "$m" "$d" "$c" "$n"

done
	
}
