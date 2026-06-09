#!/bin/sh

wk="$1"
mm="$2"
yyyy="$3"

burl="https://cfstore.ding-king.cf/blocklists"
dir="bc"
codec="u6"
f="basicconfig.json"
f2="filetag.json"
cwd=$(pwd)

# exec this script from npm or project root
out="./src/${codec}-${f}"
out2="./src/${codec}-${f2}"
name=$(uname)

# timestamp: 1667519318.799
if [ "$name" = "Darwin" ]; then
  now=$(date -u +"%s")
else
  now=$(date --utc +"%s")
fi

# date from timestamp
if [ "$name" = "Darwin" ]; then
  day=$(date -r "$now" "+%d")
else
  day=$(date -d "@$now" "+%d")
fi

# ex: conv 08 => 8
day=${day#0}

# week; ceil
wkdef=$(((day + 7 - 1) / 7))

# year
if [ "$name" = "Darwin" ]; then
  yyyydef=$(date -r "$now" "+%Y")
else
  yyyydef=$(date -d "@$now" "+%Y")
fi

# month
if [ "$name" = "Darwin" ]; then
  mmdef=$(date -r "$now" "+%m")
else
  mmdef=$(date -d "@$now" "+%m")
fi

mmdef=${mmdef#0}

# defaults
: "${wk:=$wkdef}" "${mm:=$mmdef}" "${yyyy:=$yyyydef}"

# wget opts
wgetopts="--tries=3 --retry-on-http-error=404 --waitretry=3 --no-dns-cache"

max=4

for i in $(seq 0 $max)
do
  echo "x=== pre.sh: $i try $yyyy/$mm-$wk at $now from $cwd"

  if [ -f "${out}" ] || [ -L "${out}" ]; then
    echo "=x== pre.sh: no op ${out}"
    exit 0
  else
    url1="${burl}/${yyyy}/${dir}/${mm}-${wk}/${codec}/${f}"
    echo "==x= pre.sh: $i url1 ${url1}"

    wget $wgetopts -q "$url1" -O "${out}"
    wcode=$?

    if [ $wcode -eq 0 ]; then
      fulltimestamp=$(jq -r '.timestamp' "$out")

      if [ -z "$fulltimestamp" ] || [ "$fulltimestamp" = "null" ]; then
        echo "===x pre.sh: $i timestamp missing in ${out}"
        rm -f "${out}"
      else
        echo "==x= pre.sh: $i ok $wcode; filetag? ${fulltimestamp}"

        url2="${burl}/${fulltimestamp}/${codec}/${f2}"
        echo "==x= pre.sh: $i url2 ${url2}"

        wget $wgetopts -q "$url2" -O "${out2}"
        wcode2=$?

        if [ $wcode2 -eq 0 ]; then
          echo "===x pre.sh: $i filetag ok $wcode2"
          exit 0
        else
          echo "===x pre.sh: $i not ok $wcode2"
          rm -f "${out}" "${out2}"
          exit 1
        fi
      fi
    else
      # wget creates blank files on errs
      rm -f "${out}"
      echo "==x= pre.sh: $i not ok $wcode"
    fi
  fi

  # see if the prev wk was latest
  wk=$((wk - 1))
  if [ $wk -eq 0 ]; then
    # only feb has 28 days (28/7 => 4), edge-case overcome by retries
    wk="5"
    mm=$((mm - 1))
  fi

  if [ $mm -eq 0 ]; then
    mm="12"
    yyyy=$((yyyy - 1))
  fi
done

exit 1
