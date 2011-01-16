import termcolor

termcolor.echo(termcolor.ok, true)
termcolor.echo(termcolor.ok, "success")
echo("")

termcolor.echo(termcolor.warning, false)
termcolor.echo(termcolor.warning, "did you mean X?")
echo("")

termcolor.echo(termcolor.error, false)
termcolor.echo(termcolor.error, "Don't do that.")
echo("")

termcolor.echo(termcolor.hint, "Hint: try this")
termcolor.echo(termcolor.hint, "X is the default option")
echo("")

var fatalError = termcolor.newAnsiStyle(textColor = TEXT_MAGENTA, intensity = INTENSITY_BOLD, underline = UNDERLINE_YES)
termcolor.echo(fatalError, "SOMETHING WENT REALLY WRONG!")