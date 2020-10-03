#!/usr/local/bin/bash

isNumberMatcher='^[+-]?[0-9]+([.][0-9]+)?'
typeset -A sumVars

printHelp() {
  echo '
  calcmark - For calculations in markdown.

  Simple script to run calculations in markdown files. Example:

  =+
  3 ; Fist number to add
  1 ; Some other number
  == 4 ==

  '
}

main() {
  [[ "$1" == "-h" ]] && printHelp && exit
  file=$1

  currentLineNumber=0
  while read -r line; do
    ((currentLineNumber++))

    handleMultilineCalc

    handleInlineCalc

  done < $file
}

handleMultilineCalc() {
  # if a line starts with =+ or =- use the repective + or - to calculate the following lines
  if [[ "$operator" == "" ]]; then
    if [[ "$line" =~ ^=[+-/\*] ]]; then
      operator="${line:1:1}"
    fi
  else
    if [[ "$line" == "=="* ]]; then
      handleSumTotalLine
      unset operator
      unset total
    else
      handleLineFromMultilineCalc
    fi
  fi
}

handleLineFromMultilineCalc() {
  [[ "$line" =~ $isNumberMatcher ]] || return # Skip if doesn't start with number
  numberOnLine=$BASH_REMATCH

  if [[ "$total" == "" ]]; then
    total=$numberOnLine
  else
    total="$(bc -l <<< "$total $operator $numberOnLine" )"
  fi
}

handleSumTotalLine() {
  roundedTotal="$(printf %.2f "$total")"
  markMatcher='==\[(.*)\]'
  if [[ "$line" =~ $markMatcher ]]; then
    var="${BASH_REMATCH[1]}"
    sumVars[$var]=$roundedTotal
    sed -i '' "${currentLineNumber}s/.*/==[$var] $roundedTotal ==/" $file
  else
    sed -i '' "${currentLineNumber}s/.*/== $roundedTotal ==/" $file
  fi
}

handleInlineCalc() {
  # eg: {1+1}==
  if [[ "$line" =~ {(.*)}== ]]; then
    calculation="$(resolveVars "${BASH_REMATCH[1]}")"
    result="$(bc -l <<< "$calculation")"
    result="$(printf %.2f "$result")"
    sed -i '' "${currentLineNumber}s/\({.*}==\).*/\1 $result/" $file
  fi
}

# replace the variables in a string with the values: '$t1 + $t2' to '1.00 + 2.00'
resolveVars() {
  string="$1"
  while [[ "$string" =~  \$([a-zA-Z0-9_]*) ]];do
    varName=${BASH_REMATCH[1]}
    varValue="${sumVars[$varName]}"
    string="${string//\$$varName/$varValue}"
  done
  echo "$string"
}

if [[ "$0" == "$BASH_SOURCE" ]]; then
  main $@
fi
