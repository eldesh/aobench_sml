
val _ = PolyML.make "smlnjlib";
val _ = PolyML.make "aobench";

fun main' () = ignore
  (AObench.main (CommandLine.name(), CommandLine.arguments()))

val _ = PolyML.export ("aobench-poly", main')

