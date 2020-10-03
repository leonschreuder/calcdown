
TMP_FILE="$(mktemp)"
source ./extended_matchers.sh

setup() {
  source ./calcmark.sh
}

teardown() {
  rm $TMP_FILE
}

test__should_support_multiline_calculations() {
  echo '=+
        1
        1
        ==' | sed 's/^[[:space:]]*//g'  > $TMP_FILE

  main $TMP_FILE

  assertFileContains "== 2.00 ==" "$TMP_FILE"
}

test__should_ignore_after_colon_for_multiline_calculations() {
  echo '=-
        3 ; some discription
        1
        ==' | sed 's/^[[:space:]]*//g'  > $TMP_FILE

  main $TMP_FILE

  assertFileContains "== 2.00 ==" "$TMP_FILE"
}

test__should_save_named_variables() {
  echo '=-
        3 ; some discription
        1
        ==[t1]' | sed 's/^[[:space:]]*//g'  > $TMP_FILE

  main $TMP_FILE

  assertFileContains $'==[t1] 2.00 ==\n' "$TMP_FILE"
  assertEquals "2.00" "${sumVars[t1]}"
}


test__should_support_inline_math() {
  echo '(( 1 + 1 ))== ' > $TMP_FILE

  main $TMP_FILE

  assertFileContains "(( 1 + 1 ))== 2.00" "$TMP_FILE"
}

test__should_support_braces() {
  echo '(( (1 + 1) * 2 ))== ' > $TMP_FILE

  main $TMP_FILE

  assertFileContains $'(( (1 + 1) * 2 ))== 4.00\n' "$TMP_FILE"
}

test__should_support_variable_calculation_in_inline_math() {
  typeset -A sumVars
  sumVars[t1]=2.00
  echo '(( [t1] + 1 ))== ' > $TMP_FILE

  main $TMP_FILE

  assertFileContains $'(( [t1] + 1 ))== 3.00' "$TMP_FILE"
}
