#!/usr/local/bin/bash

isNumberMatcher='^[+-]?[0-9]+([.][0-9]+)?$'
typeset -A sumVars

main() {
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
    if [[ "$line" == "="* ]]; then
      operator="${line#=}"
    fi
  else
    if [[ "$line" == "=="* ]]; then
      handleSumTotalLine
    else
      handleLineFromMultilineCalc
    fi
  fi
}

handleLineFromMultilineCalc() {
  numberOnLine=${line%%;*}
  numberOnLine=${numberOnLine// /} # remove spaces
  [[ "$numberOnLine" =~ $isNumberMatcher ]] || return # only handle if it is actually a number

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
  unset operator
  unset total
}

handleInlineCalc() {
  # if line matches ((1+1))==
  if [[ "$line" =~ \(\((.*)\)\)== ]]; then
    # put the the containing string through bc and add it to the end of the line
    formula=${BASH_REMATCH[1]}
    if [[ "$formula" =~  \[(.*)\] ]];then
      echo ${BASH_REMATCH[1]}
      formula="$( echo "$formula" | sed "s/\[.*\]/${}/" )"

    fi
    result="$(bc -l <<< "$formula")"
    result="$(printf %.2f "$result")"
    sed -i '' "${currentLineNumber}s/\(((.*))==\).*/\1 $result/" $file
  fi
}

if [[ "$0" == "$BASH_SOURCE" ]]; then
  main $@
fi
