import macros

macro namedWhile*(expr, outerName, innerName, body: untyped): untyped =
  ## Creates a while statement with named blocks so that you can easily leave or continue the while loop in
  ## double (or deeper) loop.
  ##
  ## For example:
  ##
  ## .. code-block:: nim
  ##   namedWhile(c < 2, outer, inner):
  ##     while d < 2:
  ##       # Leave outer loop
  ##       break outer
  ##       # Continue outer loop
  ##       break inner
  ##
  ## This macro create a while loop with a block enclosing the loop and a block inside the loop like this:
  ##
  ## .. code-block:: nim
  ##   block outer:
  ##     while c < 2:
  ##       block inner:
  ##         while d < 2:
  ##           break outer
  ##           break inner
  ##
  ## Specify `nil` to the block name if you don't need to create a outer or inner block.

  outerName.expectKind {nnkIdent, nnkNilLit}
  innerName.expectKind {nnkIdent, nnkNilLit}

  var whileStmt = newTree(
    nnkWhileStmt,
    expr,
    if innerName.kind == nnkIdent:
      newBlockStmt(innerName, body)
    else:
      body)

  if outerName.kind == nnkIdent:
    result = newBlockStmt(outerName, whileStmt)
  else:
    result = whileStmt

when isMainModule:
  var c = 0
  namedWhile(c < 2, outer, inner):
    inc c
    if c == 1:
      break outer
    inc c

  doAssert c == 1
  c = 0

  namedWhile(c < 2, outer, inner):
    inc c
    if c == 1:
      break inner
    inc c

  doAssert c == 3
  c = 0

  namedWhile(c < 2, outer, nil):
    while c < 2:
      inc c
      break outer

  doAssert c == 1
  c = 0

  namedWhile(c == 0, nil, inner):
    inc c
    for i in 0..2:
      inc c
      break inner

  doAssert c == 2
  c = 0

  namedWhile(c < 2, outer, inner):
    namedWhile(c < 3, outer2, inner2):
      inc c
      break outer
    inc c

  doAssert c == 1
  c = 0

  namedWhile(c < 2, outer, inner):
    namedWhile(c < 3, outer2, inner2):
      inc c
      break inner
    inc c

  doAssert c == 2
  c = 0

  namedWhile(c < 2, outer, inner):
    namedWhile(c < 3, outer2, inner2):
      inc c
      break outer2
    inc c

  doAssert c == 2
  c = 0

  namedWhile(c < 2, outer, inner):
    namedWhile(c < 3, outer2, inner2):
      inc c
      break inner2
    inc c

  doAssert c == 4

