#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 James Fisher
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module makes it easy to use ANSI escape sequences in terminal output.
## Expected usage is to call `write` or `echo` on the objects `ok`, `warning`,
## `error`, or `hint`.  The user may alternatively define her own style
## using `newAnsiStyle`.

type
  AnsiCode* = int
    ## We're giving this a type for clarity: we deal with integers below, but
    ## not all of them are ANSI codes.  (The AnsiColor type is an example).

proc write(code: AnsiCode) =
  ## Print an AnsiCode.  They are represented as decimal-formatted ASCII.
  write(cast[int](code))


## Printing a sequence of AnsiCodes
## --------------------------------

const
  CODE_START = "\27["
    ## These two characters begin an ANSI escape sequence.
    ## There is also a single-character sequence, \155.
    ## However, only the two-character sequence is recognized by
    ## devices that support just ASCII (7-bit bytes)
    ## or devices that support 8-bit bytes but use the
    ## 0x80–0x9F control character range for other purposes.

  CODE_MIDDLE = ";"
    ## Signals another code is coming.

  CODE_END = "m"
    ## The final byte is technically any character
    ## in the range 64 to 126.  'm' seems to be standard, though.

  ANSI_INVALID_CODE: AnsiCode = 256
    ## Used to indicate that no code should be printed.

  RESET: AnsiCode = 0
    ## Resets all styles to their defaults.


proc writeGluedCodeSequence(f: TFile, codes: seq[AnsiCode]) =
  ## Given zero or more AnsiCodes `codes`, print them to `f`.
  ## They are printed using write(AnsiCode) defined above,
  ## and glued together with semicolons.

  for i in low(codes)..high(codes)-1:  ## Don't append CODE_MIDDLE to the last
    var code = codes[i]
    if code != ANSI_INVALID_CODE:
      write(f, code)
      write(f, CODE_MIDDLE) ## Signal another AnsiCode is coming

  write(f, codes[high(codes)])  ## Print the final code (no trailing semicolon)


proc writeCodeSequence(f: TFile, codes: seq[AnsiCode]) =
  ## Given zero or more AnsiCodes `codes`, activate them:
  ## signal a start of sequence, print the sequence, then end the sequence.

  write(f, CODE_START)  ## Begin the escape sequence.

  ## "Private mode characters" could come here,
  ## but we don't support them.

  writeGluedCodeSequence(f, codes)

  write(f, CODE_END)    ## Terminate the escape sequence.


## ANSI-aware replacements for write() and echo()
## ----------------------------------------------

proc writeReset(f: TFile) =
  ## Reset output to whatever is defined to be normal
  writeCodeSequence(f, @[RESET])


proc writeANSI*[T](f: TFile, s: T, codes: seq[AnsiCode]) =
  ## Given `s` of writable type `T`, write it to `f`
  ## using the formatting in `codes`.

  writeCodeSequence(f, codes)  ## Specify the style with which to print `s`,
  write(f, s)                  ## write `s` in the normal fashion,
  writeReset(f)                ## then go back to default output.


proc echoANSI*[T](s: T, codes: seq[AnsiCode]) =
  ## In the same manner as the `write` vs. `echo` distinction,
  ## this does the same as `write` above, followed by a newline and flush.
  writeANSI(stdout, s, codes)
  echo("")  ## Make the normal `echo` do the hard work



################################################################################
##                          ANSI STYLE CLASSES                                ##
##----------------------------------------------------------------------------##


## Text color
## ----------

type
  AnsiTextColor* = enum  ## Add these to TEXT_COLOR_BASE or BG_COLOR_BASE.
    TEXT_BLACK,
    TEXT_RED,
    TEXT_GREEN,
    TEXT_YELLOW,
    TEXT_BLUE,
    TEXT_MAGENTA,
    TEXT_CYAN,
    TEXT_WHITE

const
  TEXT_COLOR_BASE = 30
    ## Add this to an COLOR to obtain a text-color code.

proc toAnsiCode(c: AnsiTextColor): AnsiCode = # {.noSideEffect.} 
  ## Obtain the code for text color of this color.
  return cast[AnsiCode](cast[int](c) + TEXT_COLOR_BASE)

proc defaultSetting(c: AnsiTextColor): bool =
  return c == TEXT_BLACK


## Background color
## ----------------

type
  AnsiBackgroundColor* = enum  ## Add these to TEXT_COLOR_BASE or BG_COLOR_BASE.
    BACKGROUND_BLACK,
    BACKGROUND_RED,
    BACKGROUND_GREEN,
    BACKGROUND_YELLOW,
    BACKGROUND_BLUE,
    BACKGROUND_MAGENTA,
    BACKGROUND_CYAN,
    BACKGROUND_WHITE

const
  BG_COLOR_BASE = 40
    ## Add this to an COLOR to obtain a background-color code.

proc toAnsiCode*(c: AnsiBackgroundColor): AnsiCode = # {.noSideEffect.} 
  ## Obtain the code for background color of this color.
  return cast[AnsiCode](cast[int](c) + BG_COLOR_BASE)

proc defaultSetting(c: AnsiBackgroundColor): bool =
  return c == BACKGROUND_WHITE

## Intensity
## ---------

## FEINT is not widely supported.

type
  AnsiIntensity* = enum INTENSITY_NORMAL, INTENSITY_BOLD, INTENSITY_FEINT

proc toAnsiCode(c:AnsiIntensity): AnsiCode =
  case c
  of INTENSITY_NORMAL: return 22
  of INTENSITY_BOLD: return 1
  of INTENSITY_FEINT: return 2

proc defaultSetting(c: AnsiIntensity): bool =
  return c == INTENSITY_NORMAL


## Inversion
## ---------

## Note: YES can also mean: swap FG and BG.

type
  AnsiInversion* = enum INVERSION_NO, INVERSION_YES

proc toAnsiCode(c: AnsiInversion): AnsiCode =
  case c
  of INVERSION_NO: return 27
  of INVERSION_YES: return 7

proc defaultSetting(c: AnsiInversion): bool =
  return c == INVERSION_NO


## Concealment
## -----------

## Not widely supported.

type
  AnsiConcealment* = enum CONCEALMENT_NO, CONCEALMENT_YES

proc toAnsiCode(c: AnsiConcealment): AnsiCode =
  case c
  of CONCEALMENT_NO: return 28
  of CONCEALMENT_YES: return 8

proc defaultSetting(c: AnsiConcealment): bool =
  return c == CONCEALMENT_NO


## Font style
## ----------

## Italic and Fraktur are not widely supported.

type
  AnsiFontStyle* = enum FONTSTYLE_DEFAULT, FONTSTYLE_ITALIC, FONTSTYLE_FRAKTUR

proc toAnsiCode(c: AnsiFontStyle): AnsiCode =
  case c
  of FONTSTYLE_DEFAULT: return 23
  of FONTSTYLE_ITALIC: return 3
  of FONTSTYLE_FRAKTUR: return 20

proc defaultSetting(c: AnsiFontStyle): bool =
  return c == FONTSTYLE_DEFAULT


## Font
## ----

## Select the nth alternate font.

type
  AnsiFont* = enum
    FONT_PRIMARY,
    FONT_ALT_1,
    FONT_ALT_2,
    FONT_ALT_3,
    FONT_ALT_4,
    FONT_ALT_5,
    FONT_ALT_6,
    FONT_ALT_7,
    FONT_ALT_8,
    FONT_ALT_9

proc toAnsiCode(c: AnsiFont): AnsiCode =
  return cast[AnsiCode](cast[int](c)+10)

proc defaultSetting(c: AnsiFont): bool =
  return c == FONT_PRIMARY


## Underlining
## -----------

type
  AnsiUnderline* = enum UNDERLINE_NO, UNDERLINE_YES

proc toAnsiCode(c: AnsiUnderline): AnsiCode =
  case c 
  of UNDERLINE_NO: return 24
  of UNDERLINE_YES: return 4

proc defaultSetting(c: AnsiUnderline): bool =
  return c == UNDERLINE_NO


## Overlining
## ----------

type
  AnsiOverline* = enum OVERLINE_NO, OVERLINE_YES

proc toAnsiCode(c: AnsiOverline): AnsiCode =
  case c
  of OVERLINE_NO: return 55
  of OVERLINE_YES: return 53

proc defaultSetting(c: AnsiOverline): bool =
  return c == OVERLINE_NO


## Crossing out
## ------------

## Marked for deletion; NWS.

type
  AnsiCrossedOut* = enum CROSSEDOUT_NO, CROSSEDOUT_YES

proc toAnsiCode(c: AnsiCrossedOut): AnsiCode =
  case c
  of CROSSEDOUT_NO: return 29
  of CROSSEDOUT_YES: return 9

proc defaultSetting(c: AnsiCrossedOut): bool =
  return c == CROSSEDOUT_NO


## Ideogram underlining
## --------------------

## Or on right side; NWS.

type
  AnsiIdeogramUnderline* = enum
    IDEOGRAMUNDERLINE_NO,
    IDEOGRAMUNDERLINE_SINGLE,
    IDEOGRAMUNDERLINE_DOUBLE

proc toAnsiCode(c: AnsiIdeogramUnderline): AnsiCode =
  case c
  of IDEOGRAMUNDERLINE_NO:     return ANSI_INVALID_CODE  ## ???
  of IDEOGRAMUNDERLINE_SINGLE: return 60
  of IDEOGRAMUNDERLINE_DOUBLE: return 61

proc defaultSetting(c: AnsiIdeogramUnderline): bool =
  return c == IDEOGRAMUNDERLINE_NO


## Ideogram overlining
## -------------------

## Or on left side; NWS.

type
  AnsiIdeogramOverline* = enum
    IDEOGRAMOVERLINE_NO,
    IDEOGRAMOVERLINE_SINGLE,
    IDEOGRAMOVERLINE_DOUBLE

proc toAnsiCode(c: AnsiIdeogramOverline): AnsiCode =
  case c
  of IDEOGRAMOVERLINE_NO: return ANSI_INVALID_CODE  ## ???
  of IDEOGRAMOVERLINE_SINGLE: return 62
  of IDEOGRAMOVERLINE_DOUBLE: return 63

proc defaultSetting(c: AnsiIdeogramOverline): bool =
  return c == IDEOGRAMOVERLINE_NO


## Ideogram stress
## ---------------

## NWS.

type
  AnsiIdeogramStress* = enum IDEOGRAMSTRESS_NO, IDEOGRAMSTRESS_YES

proc toAnsiCode(c: AnsiIdeogramStress): AnsiCode =
  case c
  of IDEOGRAMSTRESS_NO: return ANSI_INVALID_CODE
  of IDEOGRAMSTRESS_YES: return 64

proc defaultSetting(c: AnsiIdeogramStress): bool =
  return c == IDEOGRAMSTRESS_NO


## Blinking
## --------

## Slow is less than 150 per minute.
## Rapid is 150 per minute or more; NWS.

type
  AnsiBlink* = enum BLINK_NO, BLINK_SLOW, BLINK_RAPID

proc toAnsiCode(c: AnsiBlink): AnsiCode =
  case c
  of BLINK_NO: return 25
  of BLINK_SLOW: return 5
  of BLINK_RAPID: return 6

proc defaultSetting(c: AnsiBlink): bool =
  return c == BLINK_NO


## Framing
## -------

type
  AnsiFrame* = enum FRAME_NO, FRAME_YES, FRAME_ENCIRCLE

proc toAnsiCode(c: AnsiFrame): AnsiCode =
  case c
  of FRAME_NO: return 54
  of FRAME_YES: return 51
  of FRAME_ENCIRCLE: return 52

proc defaultSetting(c: AnsiFrame): bool =
  return c == FRAME_NO


## Other ANSI style codes
## ----------------------

## Codes 26, 50, and 56-59 are reserved.
## 30-37 are text color codes.
## 40-47 are background color codes.

## 38 is 256-color text-color. Dubious?
## 48 is 256-color background-color. Dubious?  

## 90–99: set foreground color, high intensity	aixterm (not in standard)
## 100–109: set background color, high intensity	aixterm (not in standard)

## NWS: Not Widely Supported.

const
  DEFAULT_TEXT_COLOR*:         AnsiCode = 39  ## Implementation defined
  DEFAULT_BACKGROUND_COLOR*:   AnsiCode = 49  ## Implementation defined.
  BOLD_OFF*:                   AnsiCode = 21  ## Or double underline; NWS.



################################################################################
##                  ENCAPSULATION OF ORTHOGONAL ANSI CLASSES                  ##
## ---------------------------------------------------------------------------##

type
  AnsiStyle* = object
    # This class encapsulates all of the style classes above
    # into one style that can be given a semantic association;
    # e.g. red+bold+underlined may indicate a fatal error.
    textColor:          AnsiTextColor
    backgroundColor:    AnsiBackgroundColor
    intensity*:         AnsiIntensity
    inversion*:         AnsiInversion
    concealment*:       AnsiConcealment
    fontStyle*:         AnsiFontStyle
    font*:              AnsiFont
    underline*:         AnsiUnderline
    overline*:          AnsiOverline
    crossedOut*:        AnsiCrossedOut
    ideogramUnderline*: AnsiIdeogramUnderline
    ideogramOverline*:  AnsiIdeogramOverline
    ideogramStress*:    AnsiIdeogramStress
    blink*:             AnsiBlink
    frame*:             AnsiFrame


proc newAnsiStyle*(
      textColor:         AnsiTextColor         = TEXT_BLACK,
      backgroundColor:   AnsiBackgroundColor   = BACKGROUND_WHITE,
      intensity:         AnsiIntensity         = INTENSITY_NORMAL,
      inversion:         AnsiInversion         = INVERSION_NO,
      concealment:       AnsiConcealment       = CONCEALMENT_NO,
      fontStyle:         AnsiFontStyle         = FONTSTYLE_DEFAULT,
      font:              AnsiFont              = FONT_PRIMARY,
      underline:         AnsiUnderline         = UNDERLINE_NO,
      overline:          AnsiOverline          = OVERLINE_NO,
      crossedOut:        AnsiCrossedOut        = CROSSEDOUT_NO,
      ideogramUnderline: AnsiIdeogramUnderline = IDEOGRAMUNDERLINE_NO,
      ideogramOverline:  AnsiIdeogramOverline  = IDEOGRAMOVERLINE_NO,
      ideogramStress:    AnsiIdeogramStress    = IDEOGRAMSTRESS_NO,
      blink:             AnsiBlink             = BLINK_NO,
      frame:             AnsiFrame             = FRAME_NO): ref AnsiStyle =
  # Create a new AnsiStyle object.
  new(result)
  result.textColor = textColor
  result.backgroundColor = backgroundColor
  result.intensity = intensity
  result.inversion = inversion
  result.concealment = concealment
  result.fontStyle = fontStyle
  result.font = font
  result.underline = underline
  result.overline = overline
  result.crossedOut = crossedOut
  result.ideogramUnderline = ideogramUnderline
  result.ideogramOverline = ideogramOverline
  result.ideogramStress = ideogramStress
  result.blink = blink
  result.frame = frame


proc getCodes(style: ref AnsiStyle): seq[AnsiCode] =
  # Create a list of ANSI codes that will generate the desired effect.
  # If a style is the default, we don't omit it.
  result = @[]
  if not defaultSetting(style.textColor):
    result.add(toAnsiCode(style.textColor))

  if not defaultSetting(style.backgroundColor):
    result.add(toAnsiCode(style.backgroundColor))

  if not defaultSetting(style.intensity):
    result.add(toAnsiCode(style.intensity))

  if not defaultSetting(style.inversion):
    result.add(toAnsiCode(style.inversion))

  if not defaultSetting(style.concealment):
    result.add(toAnsiCode(style.concealment))

  if not defaultSetting(style.fontStyle):
    result.add(toAnsiCode(style.fontStyle))

  if not defaultSetting(style.font):
    result.add(toAnsiCode(style.font))

  if not defaultSetting(style.underline):
    result.add(toAnsiCode(style.underline))

  if not defaultSetting(style.overline):
    result.add(toAnsiCode(style.overline))

  if not defaultSetting(style.crossedOut):
    result.add(toAnsiCode(style.crossedOut))

  if not defaultSetting(style.ideogramUnderline):
    result.add(toAnsiCode(style.ideogramUnderline))

  if not defaultSetting(style.ideogramOverline):
    result.add(toAnsiCode(style.ideogramOverline))

  if not defaultSetting(style.ideogramStress):
    result.add(toAnsiCode(style.ideogramStress))

  if not defaultSetting(style.blink):
    result.add(toAnsiCode(style.blink))

  if not defaultSetting(style.frame):
    result.add(toAnsiCode(style.frame))


proc write*[T](style: ref AnsiStyle, f: TFile, s: T) =
  # The same as system's write(), but prepends the ANSI style
  # and appends a reset.
  writeANSI(f, s, getCodes(style))

proc echo*[T](style: ref AnsiStyle, s: T) =
  # Analogous to system's echo().
  style.write(stdout, s)
  write(stdout, "\n") # echo("") fails???


################################################################################
##                             SOME USEFUL STYLES                             ##
## ---------------------------------------------------------------------------##

var
  ok* = newAnsiStyle(textColor = TEXT_GREEN)
  warning* = newAnsiStyle(textColor = TEXT_YELLOW, intensity = INTENSITY_BOLD)
  error* = newAnsiStyle(textColor = TEXT_RED, intensity = INTENSITY_BOLD)
  hint* = newAnsiStyle(textColor = TEXT_CYAN)