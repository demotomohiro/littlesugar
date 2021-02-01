import macros

type
  WithAliasesFlag* = enum
    waSideEffect
    waCompileTime

macro withAliases*(flags: static[set[WithAliasesFlag]]; args: varargs[untyped]): untyped =
  ## Creates new scope with aliases so that you can use them safely.
  ##
  ## When you use an alias of an element of seq or other collection type,
  ## that alias can become invalid pointer when you add or delete an element to it or resize it.
  ## These operation might move some elements in it or reallocate internal heap.
  ## Aliases are actually pointer and it might become pointer to wrong object or
  ## freed memory after that.
  ## This macro prevends modification of the collection after creating aliases by
  ## creating a new scope that cannot access local variables declared in outside of the scope.
  ## You can access only aliases specified in arguments.
  ##
  ## You can still declare both an alias of seq and an alias of that seq at same time
  ## and modify the seq without generating compile errors.
  ## But you can find such error easily by checking arguments.
  ## When Nim implements "Aliasing restrictions in parameter passing",
  ## that should become compile error.
  ## See:
  ## https://nim-lang.org/docs/manual_experimental.html#aliasing-restrictions-in-parameter-passing
  ##
  ## You can declare aliases in 3 ways.
  ## - Specify identifier as is
  ##   It creates immutable alias with same name.
  ## - aliasname = expression
  ##   It creates immutable alias with name specified in left side of `=` operator.
  ## - aliasname from expression
  ##   It creates mutable alias with specified name
  ##
  ## You can also declare small function that can be used as alias of function/procedure.
  ##
  ## Restrictions:
  ##   - You cannot use break or continue for a loop/block outside of `withAliases`
  ##   - Return statements within `withAliases` block does not exit from a outside proc.
  ##     It exits from `withAliases` block and returned value become value of `withAliases`.
  ##
  ## For example:
  ##
  ## .. code-block:: nim
  ##   var
  ##     a = 1
  ##     b = @[1, 2]
  ##   let r = withAliases({}, a, x from b[0], y = b[1], da(x) = doAssert(x), f(x, y) = x + y):
  ##     x = a + y
  ##     da(x == 3)
  ##     da(f(a, y) == 3)
  ##     x + a + y
  ##
  ##   doAssert r == 6
  ##
  ## transforms to the code like this:
  ##
  ## .. code-block:: nim
  ##   var
  ##     a = 1
  ##     b = @[1, 2]
  ##   func genSym1234(a: auto; x: var auto; y: auto): auto {.inline.} =
  ##     func da(x {.inject.}: auto): auto {.inline.} =
  ##       doAssert(x)
  ##
  ##     func f(x {.inject.}: auto; y {.inject.}: auto): auto {.inline.} =
  ##       x + y
  ##
  ##     x = a + y
  ##     da(x == 3)
  ##     da(f(a, y) == 3)
  ##     x + a + y
  ##
  ##   let r = genSym1234(a, b[0], b[1])
  ##   doAssert r == 6
  runnableExamples:
    let
      foo = 1
      bar = 2
    let  a = withAliases({}, x = foo, bar):
      x + bar
    doAssert a == 3

    var b = [(n: 1, s: "aaa"), (n: 2, s: "b")]
    withAliases({waSideEffect}, x from b[0].n, y = b[0].s, z from b[1]):
      x += y.len
      z.s &= $z.n
    doAssert b == [(n: 4, s: "aaa"), (n: 2, s: "b2")]

  func newIdentDefs(name: NimNode; isVar: bool): NimNode =
    newIdentDefs(
      newTree(
        nnkPragmaExpr,
        name,
        newTree(nnkPragma, ident"inject")),
      if isVar:
        newTree(nnkVarTy, ident"auto")
      else:
        ident"auto")

  func newProcPragma(flags: set[WithAliasesFlag]): NimNode =
    newTree(nnkPragma, ident(if waCompileTime in flags: "compileTime" else: "inline"))

  let
    procSym = genSym(if (waSideEffect in flags): nskProc else: nskFunc)
    procDefKind = if (waSideEffect in flags): nnkProcDef else: nnkFuncDef

  var
    identDefs = @[ident"auto"]
    callProc = newTree(nnkCall, procSym)
    userProcs: seq[NimNode]

  for i in 0..(args.len - 2):
    let arg = args[i]
    arg.expectKind {nnkInfix, nnkExprEqExpr, nnkIdent}
    case arg.kind
    of nnkInfix:
      arg.expectLen 3
      arg[0].expectIdent "from"
      arg[1].expectKind nnkIdent
      identDefs.add newIdentDefs(arg[1], true)
      callProc.add arg[2]
    of nnkExprEqExpr:
      arg.expectLen 2
      if arg[0].kind == nnkIdent:
        identDefs.add newIdentDefs(arg[0], false)
        callProc.add arg[1]
      elif arg[0].kind == nnkCall:
        arg[0].expectMinLen 1
        arg[0][0].expectKind nnkIdent
        var params = @[ident"auto"]
        for j in 1..(arg[0].len - 1):
          arg[0][j].expectKind nnkIdent
          params.add newIdentDefs(arg[0][j], false)
        userProcs.add newProc(arg[0][0], params, arg[1], procDefKind, newProcPragma(flags))
      else:
        error("left side of `=` must be identifier", arg[0])
    of nnkIdent:
      identDefs.add newIdentDefs(arg, false)
      callProc.add arg
    else:
      error("Invalid argument type", arg)
      doAssert false

  var procBody = newStmtList()
  procBody.add userProcs
  procBody.add args[^1]
  let procDecl = newProc(procSym, identDefs, procBody, procDefKind, newProcPragma(flags))
  result = newTree(nnkStmtListExpr, procDecl, callProc)

template doWithAliases*(args: varargs[untyped]): untyped =
  withAliases({waSideEffect}, args)

when isMainModule:
  func testFunc(a, b: int): int = a + b

  proc testWithAliases(sideEffect: static[bool]) =
    const flag = if sideEffect: {waSideEffect} else: {}
    withAliases(flag):
      doAssert true

    var a1 = 1
    withAliases(flag, a from a1):
      doAssert a == 1
      inc a
      doAssert a == 2
    doAssert a1 == 2

    block:
      var
        s = @[0, 1]
        b = 1
        c = 2
      let d = withAliases(flag, a from s[0], x = b + 2, c):
        a = testFunc(x, c)
        a + 10
      doAssert d == 15
      doAssert s == [5, 1]

    block:
      var
        a = 1
        b = 2
      withAliases(flag, da(x) = doAssert(x), a, b, f(x) = testFunc(x, 7)):
        da a == 1
        da b == 2
        da f(a) == 8

    block:
      var
        a = 0
        b = 1
        c = [0, 1]
      a += (withAliases(flag, b, d = c[0], e from c[1]) do:
        debugEcho b
        b + d + e)
      doAssert a == 2

  proc testMustBeCompileTimeError() =
    block:
      when false:
        #Using `s` inside `withAliases` is compile error.
        var s = @["a", "b"]
        withAliases({waSideEffect}, a from s[0]):
          a = "x"
          s[0] = "y"

    block:
      when false:
        #Calling procs that can have side effects is compile error if `waSideEffect` flag was not set.
        withAliases {}:
          echo "foo"

    block:
      when false:
        # This is dangerous code.
        # pointer to an element of container can become invalid after adding new element to it.
        # withAliases protect you by blocking access to local variables.
        var myseq = @[0, 1]
        let r = withAliases({waSideEffect}, a from myseq[1], f(x) = add(myseq, x)):
          f(2)
          doAssert a == 1
          inc a
          doAssert a == 2
          a
        doAssert r == myseq[1]

    block:
      when false:
        # You can still write dangerous code like this.
        # This code will become compile error when "Aliasing restrictions in parameter passing" is implemented.
        # https://nim-lang.github.io/Nim/manual_experimental.html#aliasing-restrictions-in-parameter-passing
        var myseq = @[0, 1]
        withAliases({waSideEffect}, s from myseq, x from myseq[0]):
          s.add 0
          x = 2
        doAssert myseq == @[2, 1, 0]

    block:
      when false:
        # You cannot break or continue blocks or loops outside of `withAliases`.
        # It is implementation limit.
        for i in 0..2:
          withAliases:
            break

  proc testDoWithAliases =
    withAliases({waSideEffect}):
      echo "foo"

    doWithAliases(a = 1):
      echo a
      doAssert a == 1
 
    doWithAliases(f(x) = echo(x)):
      f("foo")

    block:
      let a = 0
      var b = 0
      doWithAliases(f(x, y) = (echo(x);y), a, x from b):
        x = f(a, a + 1)
        doAssert x == 1
      doAssert b == 1

  proc testCompileTime =
    block:
      const r = withAliases({}, NimVersion & "foo")
      when r != NimVersion & "foo":
        {.error: "Test failed ", r.}

    block:
      const
        a = 123
        b = "foo"
        x = withAliases({waCompileTime}, a, b2 = b):
          "test" & $a & b2
      when x != "test123foo":
        {.error: "test faild " & x.}

    block:
      const a = 0
      const r = withAliases({waCompileTime, waSideEffect}, a2 = a, f(x) = testFunc(x, 2)):
        echo f(a2)
        f(a2)
      when r != 2:
        {.error: "Test failed".}

    when false:
      # Calling a proc that have a side effect is compile error.
      withAliases({waCompileTime}):
        echo "Eat side effect!"

  testWithAliases(false)
  testWithAliases(true)
  testMustBeCompileTimeError()
  testDoWithAliases()
  testCompileTime()

