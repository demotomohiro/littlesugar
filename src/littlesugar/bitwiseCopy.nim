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

proc bitwiseCast*[T](source: auto): T =
  ## Same to `cast` in Nim but slightly safer.
  ##
  ## Unlike `cast` operator, if sizeof(T) > sizeof(source),
  ## all bits in return value after first sizeof(source) bytes are 0.
  runnableExamples:
    doAssert bitwiseCast[float32](1'i32 shl 30'i32) == 2.0
    doAssert bitwiseCast[array[3, int]](100) == [100, 0, 0]

  bitwiseCopy(result, source)

when isMainModule:
  proc main =
    template testSameTypes(testSameTypeAndValue: proc): untyped =
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
      proc testSameTypeAndValue(a: auto) =
        var d: typeof(a)
        bitwiseCopy(d, a)
        doAssert d == a

      testSameTypes(testSameTypeAndValue)

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

    # Test bitwiseCast[T, U](source: U)
    block:
      proc testSameTypeAndValue(a: auto) =
        doAssert bitwiseCast[typeof(a)](a) == a

      testSameTypes(testSameTypeAndValue)

    block:
      let
        x = 0x10203040'i32
        y = bitwiseCast[int16](x)
      when cpuEndian == littleEndian:
        doAssert y == 0x3040'i16
      else:
        doAssert y == 0x1020'i16

    block:
      let
        x = 0x5566'i16
        y = bitwiseCast[int32](x)
      when cpuEndian == littleEndian:
        doAssert y == 0x5566'i32
      else:
        doAssert y == 0x55660000'i32

    block:
      let
        x = 0x10203040'u32
        y = bitwiseCast[uint8](x)
      when cpuEndian == littleEndian:
        doAssert y == 0x40'u8     
      else:
        doAssert y == 0x10'u8

    block:
      let
        x = 0xff'u8
        y = bitwiseCast[uint64](x)
      when cpuEndian == littleEndian:
        doAssert y == 0xff'u64
      else:
        doAssert y == 0xff00_0000_0000_0000'u64

    block:
      type
        Obj1 = object
          x: int

        Obj2 = object
          x: int
          y: int

      let
        x = Obj1(x: 11)
        y = bitwiseCast[Obj2](x)
      doAssert y == Obj2(x: 11, y: 0)

      let
        x2 = Obj2(x: 3, y: 7)
        y2 = bitwiseCast[Obj1](x2)
      doAssert y2 == Obj1(x: 3)

    block:
      let
        x = [1, 2, 3]
        y1 = bitwiseCast[array[1, int]](x)
        y2 = bitwiseCast[array[2, int]](x)
        y3 = bitwiseCast[array[3, int]](x)
        y4 = bitwiseCast[array[4, int]](x)
      doAssert y1 == [1]
      doAssert y2 == [1, 2]
      doAssert y3 == [1, 2, 3]
      doAssert y4 == [1, 2, 3, 0]

    block:
      let
        x = 2.0'f64
        y = bitwiseCast[int64](x)
      doAssert y == 1'i64 shl 62'i64

      let z = bitwiseCast[float64](y)
      doAssert z == x

  main()
