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
