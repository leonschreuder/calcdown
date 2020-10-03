#!/usr/local/bin/bash

isNumberMatcher='^[+-]?[0-9]+([.][0-9]+)?'
isVarMatcher='^\$([a-zA-Z0-9_-]+)'
typeset -A sumVars

printHelp() {
  echo '
  calcdown
  Simple script to run calculations in markdown files.

  The script scanns the provided file and performs simple calculations.
  2 separate types of syntaxes are supported: multiline and inline.


  ## Multiline syntax

  Running calcdown on a file will scan each line for a `=<operator>` line,
  and performs that oparation on the "first" number on each of the following
  lines till the `== n ==` line. It then updates the number on that line
  with the correct sum. Example:

  ```
  =+
  3 ; Fist number to add
  2.0  some other number
  == 4 ==
  ```


  ## Inline syntax

  The second syntax is `{ <calc> }==`, which performs the calculation
  inside the curly braces and writes the result after the double equals
  sign. Example:

  ```
  { (1 + 1) * 2 }== 4.00
  ```

  ## Variables

  The result of an operation can be saved in a variable by providing the
  variable name in braces directly following the double equals. Previously
  defined Variables can be used with a dollar sign in stead of a number.

  ```
  ...
  ==[var] 4==
  { $var + 1 }== 5
  ```
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
  if [[ "$line" =~ $isNumberMatcher ]]; then
    numberOnLine=$BASH_REMATCH

  elif [[ "$line" =~ $isVarMatcher ]]; then
    varName=${BASH_REMATCH[1]}
    numberOnLine=${sumVars[$varName]}
  else
    return # no valid syntax. Just skip.
  fi

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
  if [[ "$line" =~ {(.*)}==(\[(.+)\])? ]]; then
    calculation="$(resolveVars "${BASH_REMATCH[1]}")"
    result="$(bc -l <<< "$calculation")"
    result="$(printf %.2f "$result")"
    [[ "${BASH_REMATCH[3]}" != "" ]] && sumVars[${BASH_REMATCH[3]}]=$result
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
