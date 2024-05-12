import std/macros

proc replaceWithChildren(node, targets: NimNode): NimNode =
  result = node.copyNimNode
  if node.kind in {nnkCall, nnkCommand, nnkBracket}:
    for n in node:
      var replaced = false
      for t in targets:
        if n.eqIdent t:
          let
            ttype = t.getType
            rang = if ttype[0].eqIdent("tuple"): (0 .. (ttype.len - 2)) else: (ttype[1][1].intVal.int .. ttype[1][2].intVal.int)
          for i in rang:
            result.add newTree(nnkBracketExpr, t.copyNimNode, newLit(i))
          replaced = true
          break
      if not replaced:
        result.add replaceWithChildren(n, targets)
  else:
    for n in node:
      result.add replaceWithChildren(n, targets)

macro unpackToArgsImpl(x: tuple; body: untyped): untyped =
  for t in x:
    let ty = t.getType
    ty.expectKind nnkBracketExpr
    doAssert ty[0].eqIdent("tuple") or ty[0].eqIdent("array")
    if ty[0].eqIdent("array"):
      doAssert ty[1][0].eqIdent("range")
  result = replaceWithChildren(body, x)

macro unpackToArgs*(args: varargs[untyped]): untyped =
  ## Unpack tuples or arrrays to arguments for a procedure call or
  ## an array constructor.
  ##
  ## All parameters excepts last one are tuple or array variable names,
  ## and the last parameter is a code block.
  runnableExamples:
    proc foo(x: int; y: string) =
      doAssert x == 123 and y == "foo"

    let t = (123, "foo")
    unpackToArgs(t):
      foo(t)

  args.expectMinLen(2)
  result = newCall(bindSym"unpackToArgsImpl")
  var tup = newNimNode nnkTupleConstr
  for i in 0 ..< (args.len - 1):
    tup.add args[i]

  result.add tup
  result.add args[^1]

when isMainModule:
  proc foo(x, y, z: int) =
    doAssert x == 1 and y == 2 and z == 3

  proc bar(x, y, z: int): int =
    x + y + z

  let
    s = (1, 2, 3)
    t = (1, 2)
    u = [3]
  unpackToArgs(s, t, u):
    foo(s)
    1.foo(t[1], u)
    foo(t, t[0] + 2)
    foo(t, bar(s) - 3)

  unpackToArgs(s, t, u):
    let ary = [s, t, u]
  doAssert ary == [1, 2, 3, 1, 2, 3]

  proc someproc(a: int; b: string; c: tuple[x: float; y: bool]) =
    doAssert a == 3 and b == "foo" and c == (x: 0.25, y: true)

  let v = (3, "foo", (x: 0.25, y: true))
  unpackToArgs(v):
    someproc v
