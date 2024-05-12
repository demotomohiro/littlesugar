# Package

version       = "0.2.0"
author        = "demotomohiro"
description   = "Nim macros that might help you writing nim code"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.2"

task test, "Run tests":
  selfExec "c -r src/littlesugar/namedWhile.nim"
  selfExec "c -r src/littlesugar/withAliases.nim"
  selfExec "c -r src/littlesugar/bitwiseCopy.nim"
  selfExec "c -r src/littlesugar/replaceNimNodeTree.nim"
  selfExec "c -r src/littlesugar/expandFirst.nim"
  selfExec "c -r src/littlesugar/setLambda.nim"
  selfExec "c -r src/littlesugar/staticDeque.nim"
  selfExec "c -r src/littlesugar/staticSeq.nim"
  selfExec "c -r src/littlesugar/unpackToArgs.nim"

task docgen, "Generate html documents":
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/namedWhile.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/withAliases.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/bitwiseCopy.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/replaceNimNodeTree.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/expandFirst.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/setLambda.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/staticDeque.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/staticSeq.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/reinterpretPtr.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/unpackToArgs.nim"
  selfExec "buildIndex -o:htmldocs/theindex.html htmldocs"
