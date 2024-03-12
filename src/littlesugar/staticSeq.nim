template minimumSizeInt*(N: static range[1 .. int.high]): untyped =
  # In nim-2.0.2, if this template was not exported, causes compile error.
  # It is fix in nim-2.1.1.
  when N <= int8.high:
    int8
  elif N <= int16.high:
    int16
  elif N <= int32.high:
    int32
  else:
    int64

type
  StaticSeq*[N: static Natural; T] = object
    ## This is similar to seq, but internal storage size is fixed to `N`
    ## and it can be allocated on stack.
    ## So you can add only `N` items to this.
    ## Uses array as internal storage.
    privateLen: minimumSizeInt(N)
    data: array[N, T]

func high*(x: StaticSeq): int {.inline.} =
  x.privateLen - 1

func len*(x: StaticSeq): int {.inline.} =
  x.privateLen

func isFull*(x: StaticSeq): bool {.inline.} =
  x.privateLen == x.N

func add*(x: var StaticSeq; item: sink x.T) =
  assert not x.isFull
  x.data[x.privateLen] = item
  inc x.privateLen

template boundsCheck(x, i) =
  when compileOption("boundChecks"):
    if unlikely(i >= x.privateLen):
      raise newException(IndexDefect,
                         "Out of bounds: " & $i & " > " & $(x.len - 1))

func `[]`*(x: StaticSeq; i: Natural): lent x.T {.inline.} =
  boundsCheck(x, i)
  x.data[i]

func `[]`*(x: var StaticSeq; i: Natural): var x.T {.inline.} =
  boundsCheck(x, i)
  x.data[i]

func `[]=`*(x: var StaticSeq; i: Natural; val: sink x.T) {.inline.} =
  boundsCheck(x, i)
  x.data[i] = val

template boundsCheck2(x, i) =
  when compileOption("boundChecks"):
    if unlikely(i >= x.N):
      raise newException(IndexDefect,
                         "Out of bounds: " & $i & " > " & $(x.N - 1))

func `{}=`*(x: var StaticSeq; i: Natural; val: sink x.T) {.inline.} =
  ## This is similar to `[]=`, but you can assign with `i` larger than or
  ## equal to len. But `i` must be smaller than `x.N`.
  ## When you assign with `i` larger than or equal to `len`,
  ## `len` is automatically extended to `i + 1`,
  ## and elements in between old `len` to new `len` has default values.
  boundsCheck2(x, i)
  if x.privateLen <= i:
    x.privateLen = minimumSizeInt(x.N)(i + 1)
  x.data[i] = val

iterator items*(x: StaticSeq): lent x.T =
  for i in 0 ..< x.privateLen:
    yield x.data[i]

iterator mitems*(x: var StaticSeq): var x.T =
  for i in 0 ..< x.privateLen:
    yield x.data[i]

func clear*(x: var StaticSeq) {.inline.} =
  for i in x.mitems:
    reset i
  x.privateLen = 0

func `==`*[N: static int](x: StaticSeq; y: array[N, x.T]): bool =
  when x.N < N:
    {.error: "Array size must be equal or smaller than StaticSeq.N".}
  else:
    if x.len != N:
      return false

    for i in 0 ..< x.len:
      if x[i] != y[i]:
        return false

    true

when isMainModule:
  proc testRun[N: static Natural]() =
    block:
      var x: StaticSeq[N, int]
      doAssert x.high == -1
      doAssert x.len == 0
      doAssert not x.isFull
      doAssertRaises(IndexDefect):
        discard x[0]
      x.add 100
      doAssert x.high == 0
      doAssert x.len == 1
      doAssert x[0] == 100
      doAssert x == [100]
      doAssert not x.isFull
      doAssertRaises(IndexDefect):
        discard x[1]
      dec x[0]
      doAssert x[0] == 99
      doAssert x.len == 1
      inc x[0]
      x{2} = 102
      doAssert x.high == 2
      doAssert x.len == 3
      doAssert not x.isFull
      doAssert x[0] == 100 and x[1] == 0 and x[2] == 102
      doAssert x == [100, 0, 102]
      doAssertRaises(IndexDefect):
        discard x[3]
      x{3} = 103
      doAssert x.high == 3
      doAssert x.len == 4
      doAssert x[0] == 100 and x[1] == 0 and x[2] == 102 and x[3] == 103
      var s = 0
      for i in x:
        s = s * 100 + i
      doAssert s == 100010303
      doAssert x.len == 4

      for i in x.mitems:
        i = 123
        break
      doAssert x.len == 4
      doAssert x[0]  == 123 and x[1] == 0 and x[2] == 102 and x[3] == 103
      doAssert x == [123, 0, 102, 103]

      for i in x.mitems:
        i = 321
      doAssert x.len == 4
      doAssert x[0] == 321 and x[1] == 321 and x[2] == 321 and x[3] == 321
      doAssert x == [321, 321, 321, 321]

      x.clear()
      doAssert x.len == 0

    block:
      var x: StaticSeq[N, int]
      for i in 0 ..< N:
        doAssert not x.isFull
        x.add i
      doAssert x.isFull
      doAssert x.high == N - 1
      doAssert x.len == N
      for i in 0 ..< N:
        doAssert x[i] == i

  proc test[N: static Natural; T: SomeInteger]() =
    var x: StaticSeq[N, int]
    doAssert sizeof(x.data) == sizeof(int) * N
    doAssert x.privateLen is T
    testRun[N]()

  test[126, int8]()
  test[127, int8]()
  test[128, int16]()
  test[32766, int16]()
  test[32767, int16]()
  test[32768, int32]()
