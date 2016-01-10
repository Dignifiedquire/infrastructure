#!/usr/bin/env bash

set -e

find_units() {
  for u in `find . -name env.sh | xargs realpath | xargs dirname`; do
    u="$u/"
    u="${u#$(pwd)/}"
    u="${u%/}"
    [ -z "$u" ] && u="."
    echo "$u"
  done | LC_ALL=C sort
}

var() {
  key="$1"
  prefixes="var_ $host""_"

  # default to an error message, in case none of the prefixes yields a value
  value="ERR_UNKNOWN_VAR_$key"
  for p in $prefixes; do
    # try printing the variable with that prefix
    try=($(eval 'printf %s\\n "${'$p$key'[@]}"'))
    # if it yielded something, save that as the result
    [ -z "$try" ] || value=${try[@]}
  done

  printf %s\\n "${value[@]}"
}

template() {
  unit="$1"
  file="$2"
  path="$unit/$file.tpl"

  # escape double-quotes so they won't interfere with rendering
  tpl="$(cat $path | sed -e 's/"/\\"/g')"
  # render the template by printing it out, let shell take care of variables
  out="$(eval "printf %s\\\n \"$tpl\"")"

  [ -z "$out" ] \
    && echo "error: unknown template: $path" 1>&2 \
    && exit 1

  # detect and raise unknown var errors
  for line in "$out"; do
    regexp='ERR_UNKNOWN_VAR_([0-9a-z_]+)'
    [[ "$line" =~ $regexp ]] \
      && echo "error: unknown var: ${BASH_REMATCH[1]} (in $path)" 1>&2 \
      && exit 1
  done

  printf %s\\n "$out" > build/$host/$unit/$file
}

try_var() {
  key=$1
  value=($(var $key))

  if [ "$value" != "ERR_UNKNOWN_VAR_$key" ]; then
    printf %s\\n "${value[@]}"
  fi
}

for unit in $(find_units); do source "$unit/env.sh"; done

rm -rf build/
for host in ${hosts[@]}; do
  echo "build: $host"
  for unit in $(try_var units); do
    echo "- $unit"
    mkdir -p "build/$host/$unit"
    [ ! -r "$unit/build.sh" ] || source "$unit/build.sh"
  done
done
host=""

for host in ${hosts[@]}; do
  echo "upload: $host"
  scp -r build/$host/* $(try_var ssh):/opt/provsn/
done
host=""
