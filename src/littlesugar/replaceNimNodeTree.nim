import std/macros

proc replace*(node, target, dest: NimNode): NimNode =
  ## Recursively replaces all `NimNode` trees in `node` that matches `target` with `dest`.
  runnableExamples:
    macro foo(target, dest, body: untyped): untyped =
      replace(body, target, dest)

    doAssert foo(min, max, min(3, 7)) == 7

  if node == target:
    result = dest.copyNimTree
  else:
    result = node.copyNimNode
    for n in node:
      result.add replace(n, target, dest)

when isMainModule:
  macro replaceAST(src, dest, body: untyped): untyped = 
    body.replace(src, dest)

  proc main =
    block:
      let
        a = 1
        b = 2
      replaceAST(a, b):
        doAssert a == 2

      replaceAST(a == 10, b == 2):
        doAssert a == 10
        doAssert a == 10

      replaceAST(echo, doAssert):
        echo a == 1 and b == 2

    block:
      var a, b: int

      replaceAST(a, a + 2):
        b = a
      doAssert b == 2

      replaceAST(max, min):
        a = max(3, 7)
        a = max(3, 8)

      doAssert a == 3

      proc foo(): int = 123
      proc foo(x: int): int = x
      proc bar(): int = 321

      replaceAST(foo(), bar()):
        a = foo()
        b = foo(111)

      doAssert a == 321
      doAssert b == 111

    discard

  main()
