proc bitwiseCopy*[T, U](dest: var T, source: U) =
  ## Copy the bit pattern of `source` to `dest`.
  ##
  ## Unlike `cast` operator, if sizeof(T) > sizeof(U), it doesn't change bits of `dest` after first sizeof(U) bytes.
  ##
  ## When T or U are `ref`, `seq`, `string` or array/object/tuple type that contains these type,
  ## it is compile error.
  runnableExamples:
    var
      x: float32
      y = 1'i32 shl 30'i32
    bitwiseCopy(x, y)
    doAssert x == 2.0

    var
      ary = [1, 2, 3]
      src = 100
    bitwiseCopy(ary, src)
    doAssert ary == [100, 2, 3]

  # There is a proc or macro that checks if given type can be safely bit wise copied.
  # But I forget where it is :(
  # This type check is not good enough.
  type Uncopyable = ref or seq or string
  when T is Uncopyable:
    {.fatal: "Overwriting " & $T & " is unsafe.".}
  when U is Uncopyable:
    {.fatal: "Bitwise copying " & $U & " is unsafe.".}

  copyMem(addr dest, unsafeAddr source, min(sizeof(T), sizeof(U)))

when isMainModule:
  proc main =
    proc testSameTypeAndValue(a: auto) =
      var d: typeof(a)
      bitwiseCopy(d, a)
      doAssert d == a

    proc testSameType(T: typedesc[SomeNumber]) =
      testSameTypeAndValue(T.low)
      testSameTypeAndValue(T.low + T(1))
      when T is SomeSignedInt:
        testSameTypeAndValue(T(-1))
      testSameTypeAndValue(T(0))
      testSameTypeAndValue(T(1))
      testSameTypeAndValue(T.high - T(1))

    testSameType(int8)
    testSameType(uint8)
    testSameType(int16)
    testSameType(uint16)
    testSameType(int32)
    testSameType(uint32)
    testSameType(int64)
    testSameType(uint64)
    testSameType(float32)
    testSameType(float)

    block:
      var
        x = 0x10201020'i32
        y = 0x3040'i16
      bitwiseCopy(x, y)
      # Result depends endianness 
      when cpuEndian == littleEndian:
        doAssert x == 0x10203040'i32
      else:
        doAssert x == 0x30401020'i32
      doAssert y == 0x3040'i16

    block:
      var
        x = 0x5566'i16
        y = 0x01020304'i32
      bitwiseCopy(x, y)
      when cpuEndian == littleEndian:
        doAssert x == 0x0304'i16
      else:
        doAssert x == 0x0102'i16
      doAssert y == 0x01020304'i32

    block:
      var
        x = 0x10203040'u32
        y = 0xff'u8
      bitwiseCopy(x, y)
      when cpuEndian == littleEndian:
        doAssert x == 0x102030ff'u32
      else:
        doAssert x == 0xff203040'u32
      doAssert y == 0xff'u8

    block:
      type
        Obj1 = object
          x: int

        Obj2 = object
          x: int
          y: int

      var
        x1 = Obj1(x: 1)
        x2 = Obj2(x: 3, y: 5)

      bitwiseCopy(x2, x1)
      doAssert x2 == Obj2(x: 1, y: 5)
      doAssert x1 == Obj1(x: 1)

      x1 = Obj1(x: 7)
      x2 = Obj2(x: 11, y: 13)

      bitwiseCopy(x1, x2)
      doAssert x1 == Obj1(x: 11)
      doAssert x2 == Obj2(x: 11, y: 13)

    block:
      var
        x = [1, 2, 3]
        y = [10, 11]
      bitwiseCopy(x, y)
      doAssert x == [10, 11, 3]
      doAssert y == [10, 11]

    block:
      var
        x = [1, 2]
        y = [10, 11, 12]
      bitwiseCopy(x, y)
      doAssert x == [10, 11]
      doAssert y == [10, 11, 12]

    block:
      var
        x = ['a', 'b', 'c', 'd']
        y = ['x']
      bitwiseCopy(x, y)
      doAssert x == ['x', 'b', 'c', 'd']
      doAssert y == ['x']

    block:
      var
        x = ['a']
        y = ['x', 'y', 'z', 'w']
      bitwiseCopy(x, y)
      doAssert x == ['x']
      doAssert y == ['x', 'y', 'z', 'w']

    block:
      var
        x = 2.0
        y = 1
      bitwiseCopy(x, y)
      doAssert x == cast[float](y)
      doAssert y == 1

    block:
      var
        x = 1
        y = 2.0
      bitwiseCopy(x, y)
      doAssert x == cast[int](y)
      doAssert y == 2.0

    when false:
      block:
        var
          s: seq[int]
          str: string
          ri: ref int
          x: int

        doAssert not compiles(bitwiseCopy(s, 1))
        doAssert not compiles(bitwiseCopy(x, s))
        doAssert not compiles(bitwiseCopy(str, 1))

  main()
