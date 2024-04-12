func reinterpretPtr*[T: ptr](src: ptr or pointer): T =
  ## Reinterpret the given pointer to a different pointer type.
  ##
  ## This is same to cast, but only accepts a pointer type for safer type convertion.
  ## But it still can be unsafe.
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
