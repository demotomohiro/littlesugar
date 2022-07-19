import std/macros

proc deSym(x: NimNode): NimNode =
  if x.kind==nnkSym:
    return ident(x.strval)
  result = x
  for i,n in x.pairs:
    result[i] = n.desym

macro setLambda*(procVar: var proc; body: untyped): untyped =
  ## Assign an anonymous procedure to a procedual type variable easily.
  runnableExamples:
    var someProc: proc (x: int): int
    setLambda someProc, x * 3 + 1
    doAssert someProc(1) == 4
    setLambda someProc:
      if x == 0:
        result = -1
      else:
        result = x
    doAssert someProc(0) == -1

  #echo procVar.getTypeImpl().treeRepr
  let
    typeImpl = procVar.getTypeImpl()
    formalParams = typeImpl[0].deSym
    pragma = typeImpl[1].copyNimTree
    empty = newEmptyNode()
  
  newAssignment(procVar,
                newTree(nnkLambda,
                        empty, empty, empty,
                        formalParams,
                        pragma,
                        empty,
                        body))

when isMainModule:
  var global = 0

  var gfoo: proc (x, y: int): int
  setLambda gfoo, x + y * 3
  doAssert gfoo(2, 3) == 11

  proc main =
    block:
      var foo: proc ()

      global = 0
      setLambda foo:
        global = 123
      foo()
      doAssert global == 123

      var tmp = 0
      setLambda foo:
        tmp = 321
      foo()
      doAssert tmp == 321

    block:
      type
        FooProc = proc (x: int): int
      var foo: FooProc
      setLambda foo, 123
      doAssert foo(0) == 123
      setLambda foo, x
      doAssert foo(456) == 456
      setLambda foo:
        if x == 0:
          100
        else:
          x * 100
      doAssert foo(0) == 100
      doAssert foo(10) == 1000

    block:
      type
        Foo = object
          foo: proc(): tuple[x: int, y: string] {.cdecl.}

      var foo: Foo
      setLambda foo.foo, (x: 12345, y: "foo")
      doAssert foo.foo() == (12345, "foo")

    block:
      var foo: tuple[p: proc (a: string; b: float; c: int): string {.nimcall.}, x: int]
      foo.p.setLambda(a & $b & $c)
      doAssert foo.p("nim", 1.0, 111) == "nim1.0111"

  main()
