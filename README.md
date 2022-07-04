# littlesugar
This is Nim macros that might help writing simpler and safer code.

[document](https://demotomohiro.github.io/littlesugar/theindex.html)

## List of modules
### [namedWhile](https://demotomohiro.github.io/littlesugar/namedWhile.html)
Creates a while statement with named blocks so that you can easily leave or continue the while loop in double (or deeper) loop.

### [withAliases](https://demotomohiro.github.io/littlesugar/withAliases.html)
Creates a new scope with aliases so that you can use them safely.

### [bitwiseCopy](https://demotomohiro.github.io/littlesugar/bitwiseCopy.html)
It provides procedures work like `cast` in Nim, but slightly safer.

### [replaceNimNodeTree](https://demotomohiro.github.io/littlesugar/replaceNimNodeTree.html)
Recursively replaces all `NimNode` subtrees that matches given `NimNode` tree with specified `NimNode` tree.
