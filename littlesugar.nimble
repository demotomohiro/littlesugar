# Package

version       = "0.1.0"
author        = "demotomohiro"
description   = "Nim macros that might help you writing nim code"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.2"

task test, "Run tests":
  selfExec "c -r src/littlesugar/namedWhile.nim"
  selfExec "c -r src/littlesugar/withAliases.nim"

task docgen, "Generate html documents":
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/namedWhile.nim"
  selfExec "doc --outdir:htmldocs --index:on src/littlesugar/withAliases.nim"
  selfExec "buildIndex -o:htmldocs/theindex.html htmldocs"
