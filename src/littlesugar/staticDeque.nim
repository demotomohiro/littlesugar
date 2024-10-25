const MaxBitSize = sizeof(pointer) * 8 - 1
template minimumSizeUint(N: static range[1 .. MaxBitSize]): untyped =
  # Although Nim doesn't recommend using uint, StaticDeque use it.
  # Because wrap around doesn't cause problems in this use case.
  # And `tail` - `head` returns correct buffer size even if `tail` < `head`.
  #
  # `tail` and `head` requires N + 1 or larger uint size,
  # so that `tail` - `head` returns correct length
  # even if buffer is full (length == 1 shl N).
  when N < 8:
    uint8
  elif N < 16:
    uint16
  elif N < 32:
    uint32
  else:
    uint64

type
  StaticDeque*[N: static range[1 .. MaxBitSize]; T] = object
    ## This is similar to std/deques, but has fixed size storage
    ## that can be allocated on stack.
    ##
    ## This has an array to hold 2^N elements.
    tail, head: minimumSizeUint(N)
    buf: array[1 shl N, T]

func high*(x: StaticDeque): int =
  x.buf.high

func maxLen*(T: typedesc[StaticDeque]): int {.compileTime.} =
  T.buf.len

template maxLen*(x: StaticDeque): int =
  x.typeof.maxLen

func len*(x: StaticDeque): int =
  (x.tail - x.head).int

func isFull*(x: StaticDeque): bool =
  x.len == x.buf.len

func mask(x: StaticDeque): auto {.inline.} =
  minimumSizeUint(x.N)(x.buf.high)

proc addLast*(x: var StaticDeque; item: sink x.T) =
  assert not x.isFull
  x.buf[x.tail and x.mask] = item
  inc x.tail

proc popFirst*(x: var StaticDeque): x.T {.inline, discardable.} =
  assert x.head != x.tail
  result = x.buf[x.head and x.mask]
  inc x.head

template xBoundsCheck(deq, i) =
  # Bounds check for the array like accesses.
  when compileOption("boundChecks"):
    if unlikely(i >= deq.len): # x < deq.low is taken care by the Natural parameter
      raise newException(IndexDefect,
                         "Out of bounds: " & $i & " > " & $(deq.len - 1))
    if unlikely(i < 0): # when used with BackwardsIndex
      raise newException(IndexDefect,
                         "Out of bounds: " & $i & " < 0")

proc `[]`*(x: StaticDeque; i: Natural): lent x.T {.inline.} =
  ## Accesses the `i`-th element of `deq`.
  runnableExamples:
    var a: StaticDeque[2, int]
    a.addLast 10
    a.addLast 20
    a.addLast 30
    a.addLast 40
    assert a[0] == 10
    assert a[3] == 40
    doAssertRaises(IndexDefect, echo a[8])

  xBoundsCheck(x, i)
  x.buf[(x.head + minimumSizeUint(x.N)(i)) and x.mask]

proc `[]`*(x: var StaticDeque; i: Natural): var x.T {.inline.} =
  ## Accesses the `i`-th element of `deq` and returns a mutable
  ## reference to it.
  runnableExamples:
    var a: StaticDeque[2, int]
    a.addLast 10
    inc(a[0])
    assert a[0] == 11

  xBoundsCheck(x, i)
  x.buf[(x.head + minimumSizeUint(x.N)(i)) and x.mask]

iterator items*(x: StaticDeque): x.T =
  var i = x.head
  while i != x.tail:
    yield x.buf[i and x.mask]
    inc i

iterator mitems*(x: var StaticDeque): var x.T =
  var i = x.head
  while i != x.tail:
    yield x.buf[i and x.mask]
    inc i

when isMainModule:
  proc test[N: static range[1 .. MaxBitSize]]() =
    var x: StaticDeque[N, int]
    doAssert not x.isFull
    doAssert x.len == 0
    x.addLast 123
    doAssert not x.isFull
    doAssert x.len == 1
    doAssert x[0] == 123
    doAssertRaises(IndexDefect, echo x[1])
    doAssert x.popFirst == 123
    doAssert not x.isFull
    doAssert x.len == 0
    x.addLast 1
    doAssert not x.isFull
    x.addLast 2
    doAssert x.len == 2
    doAssert not x.isFull
    doAssert x[0] == 1 and x[1] == 2
    inc x[0], 10
    doAssert x.popFirst == 11
    x.addLast 3
    doAssert x.len == 2
    doAssert x[0] == 2 and x[1] == 3
    inc x[0], 100
    doAssert x[0] == 102
    doAssert x.popFirst == 102
    doAssert not x.isFull
    doAssert x.len == 1
    doAssert x.popFirst == 3
    doAssert not x.isFull
    doAssert x.len == 0
    x.addLast 4
    doAssert x.len == 1
    doAssert not x.isFull
    doAssert x.popFirst == 4
    doAssert x.len == 0
    doAssert not x.isFull
    for i in 0 .. x.high:
      x.addLast i
    doAssert x.len == (x.high + 1)
    doAssert x.isFull
    for i in 0 .. x.high:
      doAssert x.popFirst == i
    doAssert x.len == 0
    doAssert not x.isFull
    for i in 0 .. x.high:
      x.addLast i
    doAssert x.len == (x.high + 1)
    doAssert x.isFull
    doAssert x.popFirst == 0
    x.addLast 54321
    doAssert x.popFirst == 1
    for i in 2 .. x.high:
      doAssert x.popFirst == i
    doAssert x.len == 1
    doAssert not x.isFull
    doAssert x.popFirst == 54321
    doAssert x.len == 0
    doAssert not x.isFull

    block:
      proc testIterator(x: var StaticDeque) =
        doAssert x.len == 0
        var c = 0
        for i in x:
          inc c
        doAssert c == 0

        x.addLast 123
        c = 0
        for i in x:
          doAssert i == 123
          inc c
        doAssert c == 1
        doAssert x.popFirst == 123
        c = 0
        for i in x:
          inc c
        doAssert c == 0

        x.addLast 111
        x.addLast 222
        c = 0
        for i in x:
          if c == 0:
            doAssert i == 111
          elif c == 1:
            doAssert i == 222
          inc c
        doAssert c == 2

        doAssert x.popFirst == 111
        c = 0
        for i in x:
          doAssert i == 222
          inc c
        doAssert c == 1
        doAssert x.popFirst == 222
        c = 0
        for i in x:
          inc c
        doAssert c == 0

        x.addLast 100
        for i in x.mitems:
          doAssert i == 100
          i = 1000
        doAssert x.popFirst == 1000
        x.addLast 123
        x.addLast 321
        c = 0
        for i in x.mitems:
          if c == 0:
            doAssert i == 123
          elif c == 1:
            doAssert i == 321
          inc c
          dec i
        doAssert c == 2
        doAssert x.popFirst == 122
        doAssert x.popFirst == 320

      var
        x: StaticDeque[N, int]
        c = 0
      testIterator(x)
      for i in 0 .. x.high:
        x.addLast i + 123
      for i in x:
        doAssert i == c + 123
        inc c
      doAssert c == x.high + 1
      for i in 0 .. x.high:
        x.popFirst
      testIterator(x)
      doAssert x.len == 0
      testIterator(x)
      doAssert x.len == 0

  block:
    var x: StaticDeque[2, int]
    assert sizeof(x.buf) == sizeof(int) * 4
    assert x.tail is uint8
    test[2]()

  block:
    var x: StaticDeque[7, int]
    assert sizeof(x.buf) == sizeof(int) * 128
    assert x.tail is uint8
    test[7]()

  block:
    var x: StaticDeque[8, int]
    assert sizeof(x.buf) == sizeof(int) * 256
    assert x.tail is uint16
    test[8]()

  block:
    var x: StaticDeque[15, int]
    doAssert sizeof(x.buf) == sizeof(int) * 32768
    doAssert x.tail is uint16
    test[15]()

  block:
    var x: StaticDeque[16, int]
    doAssert sizeof(x.buf) == sizeof(int) * 65536
    doAssert x.tail is uint32
    test[16]()

  block:
    var x: StaticDeque[8, int]
    static: doAssert compiles(array[x.typeof.maxLen, int])
    static: doAssert compiles(array[x.maxLen, int])
