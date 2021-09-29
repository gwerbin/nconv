## nconv: Convert numbers between base systems and formats.
##
## ISC License: \
##   Copyright 2021 Greg Werbin
##
##   Permission to use, copy, modify, and/or distribute this software for any
##   purpose with or without fee is hereby granted, provided that the above
##   copyright notice and this permission notice appear in all copies.
##
##   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
##   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
##   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
##   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
##   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
##   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
##   IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# TODO: figure out the CLI
# TODO: figure out Nim tooling
# TODO: decimal, hex, octal, binary
# TODO: thousands and decimal separators
# TODO: scientific notation
# TODO: natural language inflection

import os
import parseopt
import strformat
import strutils
import sugar
import tables
import unicode


type
  NumberFormat = enum
    Binary,
    Octal,
    Decimal,
    Hexadecimal


const formatAliases = {
  "b"          : Binary,
  "bin"        : Binary,
  "binary"     : Binary,
  "o"          : Octal,
  "oct"        : Octal,
  "octal"      : Octal,
  "d"          : Decimal,
  "dec"        : Decimal,
  "decimal"    : Decimal,
  "h"          : Hexadecimal,
  "hex"        : Hexadecimal,
  "hexadecimal": Hexadecimal,
}.toTable()


type
  UsageError = object of CatchableError
  InvalidInputFormatError = object of UsageError
  InvalidOutputFormatError = object of UsageError


func formatIntBin(i: int): string = return fmt"0b{i:b}"
func formatIntOct(i: int): string = return fmt"0o{i:o}"
func formatIntDec(i: int): string = return fmt"{i:d}"
func formatIntHex(i: int): string = return fmt"0x{i:X}"


proc getInputConverter(key: string): (string) -> int {.raises: [InvalidInputFormatError].}=
  var numberFormat: NumberFormat
  try:
    numberFormat = formatAliases[key]
  except KeyError:
    raise newException(InvalidInputFormatError, "Unknown input format: " & $key)
  return case numberFormat
  of Binary:      parseBinInt
  of Octal:       parseOctInt
  of Decimal:     parseInt
  of Hexadecimal: parseHexInt


proc getOutputConverter(key: string): (int) -> string {.raises: [InvalidOutputFormatError].} =
  var numberFormat: NumberFormat
  try:
    numberFormat = formatAliases[key]
  except KeyError:
    raise newException(InvalidOutputFormatError, "Unknown output format: " & $key)
  return case numberFormat
  of Binary:      formatIntBin
  of Octal:       formatIntOct
  of Decimal:     formatIntDec
  of Hexadecimal: formatIntHex


proc handleOptFrom(optFrom: string): (string) -> int {.raises: [InvalidInputFormatError].} =
  return getInputConverter(optFrom)


proc handleOptTo(optTo: string): (int) -> string {.raises: [InvalidOutputFormatError].} =
  return getOutputConverter(optTo)


proc handleOptUnknown(optKind: CmdLineKind, optKey: string) {.raises: [UsageError].} =
  var optFlag: string
  case optKind
  of cmdLongOption:
    optFlag = "--" & $optKey
  of cmdShortOption:
    optFlag = "-" & $optKey
  else:
    # This should not happen.
    doAssert false
  raise newException(UsageError, "Unknown option: " & $optFlag)


func getReturnCode(exception: UsageError): int = return 1
func getReturnCode(exception: InvalidInputFormatError): int = return 2
func getReturnCode(exception: InvalidOutputFormatError): int = return 2


proc die(returnCode: int = 0, message: string = "") {.noReturn, raises: [IOError].} =
  if message != "":
    stderr.writeline(message)
  quit(returnCode)

proc die(exception: UsageError) {.noReturn, raises: [IOError].}
  = die(getReturnCode(exception), exception.msg)

proc die(exception: ref UsageError) {.noReturn, raises: [IOError].}
  = die(exception[])


proc main() {.raises: [IOError].} =
  # -f/--from and -t/--to options given by the user
  var optFrom: string = ""
  var optTo: string = ""

  # Conversion functions derived from user args
  # var inputConverter: (string) -> int
  # var outputConverter: (int) -> string
  var inputConverter: (string) -> int = parseHexInt    # -f hex
  var outputConverter: (int) -> string = formatIntDec  # -t dec

  # Args to parse and convert
  var args = newSeq[string]()

  var argParser = initOptParser(commandLineParams(), shortNoVal = {'h'}, longNoVal = @["help"])

  for optKind, optKey, optVal in argParser.getopt():
    case optKind
    of cmdEnd: assert(false)
    of cmdArgument:
      args.add(optKey)
    of cmdShortOption, cmdLongOption:
      case optKey
      of "h", "help":
        echo "Todo :)"
        die(0)
      of "f", "from":
        if optFrom != "":
          stderr.write("Multiple values of -f/--from provided. Using only the last one.")
        optFrom = optVal.toLower()
        try:
          inputConverter = handleOptFrom(optFrom)
        except InvalidInputFormatError as e:
          die(e)
      of "t", "to":
        if optTo != "":
          stderr.write("Multiple values of -t/--to provided. Using only the last one.")
        optTo = optVal.toLower()
        try:
          outputConverter = handleOptTo(optTo)
        except InvalidOutputFormatError as e:
          die(e)
      else:
        try:
          handleOptUnknown(optKind, optVal)
        except UsageError as e:
          die(e)

  # if optFrom == "":
  #   inputConverter = getInputConverter("h")
  # if optTo == "":
  #   outputConverter = getOutputConverter("d")

  var output: string
  var number: int

  for arg in args:
    try:
      number = inputConverter(arg)
    except Exception as e:
      stderr.writeline(e.msg)
      #let optFromFull = formatAliases.getOrDefault(optFrom, optFrom)
      #stderr.writeline("Failed to parse as " & optFromFull & ": " & $arg & "\n" & e.msg)
      continue

    try:
      output = outputConverter(number)
    except Exception as e:
      stderr.writeline(e.msg)
      #let optToFull = formatAliases.getOrDefault(optTo, optTo)
      #stderr.writeline("Failed to format as " & optToFull & ": " & $number & "\n" & e.msg)
      continue

    stdout.write(output)
    stdout.write(" ")

  stdout.write("\n")
  stdout.flushFile()

when isMainModule:
  main()

