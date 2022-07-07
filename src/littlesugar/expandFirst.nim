import std/macros
import replaceNimNodeTree

template expandFirst*(macroOrTemplateCall, body: untyped): untyped =
  ## Expand `macroOrTemplateName` inside `body` before expanding other macros or templates.
  ##
  ## `macroOrTemplateCall` cannot take template or macro call
  ## that takes non-compile time arguments.
  runnableExamples:
    import macros

    macro putEcho(body: untyped): untyped =
      # This sample macro replace `e args` to `echo args`
      result = body.copyNimNode
      for i in body:
        if i.kind == nnkCommand and i.len > 0 and i[0].eqIdent("e"):
          var c = newCall bindSym"echo"
          c.add i[1..^1]
          result.add c
        else:
          result.add i

    putEcho:
      e "Hello"

    template someCode(): untyped =
      e "Hello"

    #[
    # This doesn't work as someCode template is expanded after putEcho is expanded.
    putEcho:
      someCode()
    ]#

    expandFirst(someCode()):
      putEcho:
        someCode()

  macro innerMacro(macroOrTemplateCallNimNode, inBody: untyped): untyped {.genSym.} =
    replace(inBody, macroOrTemplateCallNimNode, getAst(macroOrTemplateCall))

  innerMacro(macroOrTemplateCall, body)

when isMainModule:
  proc main =
    macro doAssertHasIdent(ident: static string; body: untyped): untyped =
      doAssert eqIdent(body, ident)

    template testTemplate(): untyped =
      foo

    doAssertHasIdent("foo", foo)
    expandFirst(testTemplate()):
      doAssertHasIdent("foo", testTemplate())

    macro testMacro(a: static int): untyped =
      ident("bar" & $a)

    expandFirst(testMacro(123)):
      doAssertHasIdent("bar123", testMacro(123))

    when false:
      template testTemplate(ident: untyped): untyped =
        ident

      var bar = 1
      expandFirst(testTemplate(bar)):
        doAssertHasIdent("bar", testTemplate(bar))

  main()
