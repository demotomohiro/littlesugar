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
    ## This is similar to std/deques, but has fixed size storage.
    ##
    ## This has a buffer to hold 2^N elements.
    tail, head: minimumSizeUint(N)
    buf: array[1 shl N, T]

func high*(x: StaticDeque): int =
  x.buf.high

func len*(x: StaticDeque): int =
  (x.tail - x.head).int

func isFull*(x: StaticDeque): bool =
  x.len == x.buf.len

proc addLast*(x: var StaticDeque; item: sink x.T) =
  assert not x.isFull
  x.buf[x.tail.int and x.buf.high] = item
  inc x.tail

proc popFirst*(x: var StaticDeque): x.T {.inline, discardable.} =
  assert x.head != x.tail
  result = x.buf[x.head.int and x.buf.high]
  inc x.head

when isMainModule:
  proc test[N: static range[1 .. MaxBitSize]]() =
    var x: StaticDeque[N, int]
    doAssert not x.isFull
    doAssert x.len == 0
    x.addLast 123
    doAssert not x.isFull
    doAssert x.len == 1
    doAssert x.popFirst == 123
    doAssert not x.isFull
    doAssert x.len == 0
    x.addLast 1
    doAssert not x.isFull
    x.addLast 2
    doAssert x.len == 2
    doAssert not x.isFull
    doAssert x.popFirst == 1
    x.addLast 3
    doAssert x.len == 2
    doAssert x.popFirst == 2
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
