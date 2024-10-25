func reinterpretPtr*[T: ptr or cstring](src: ptr or pointer): T {.inline.} =
  ## Reinterpret the given pointer to a different pointer type.
  ##
  ## This is same to cast, but only accepts a pointer type for safer type convertion.
  ## But it still can be unsafe.
  runnableExamples:
    var
      x: int = 12345
      px: pointer = x.addr
    doAssert reinterpretPtr[ptr int](px)[] == 12345
  cast[T](src)

when isMainModule:
  var
    a = 123
    pa = a.addr
    pa2: pointer = pa

  doAssert reinterpretPtr[ptr int](pa2) is ptr int
  doAssert reinterpretPtr[ptr int](pa2)[] == 123
  doAssert not compiles(reinterpretPtr[ptr int](a))
  doAssert reinterpretPtr[ptr int](nil) is ptr int
  doAssert reinterpretPtr[ptr int](nil) == nil

  var
    s = "Hello"
    cs = s.cstring
    ps: pointer = cs
  doAssert reinterpretPtr[cstring](ps) is cstring
  doAssert reinterpretPtr[cstring](ps) == "Hello"
