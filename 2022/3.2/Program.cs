using MoreLinq;

System.Console.WriteLine(
    System.IO.File
        .ReadAllLines("input.txt")
        .Batch(3)
        .SelectMany(groupOfThree => groupOfThree.ElementAt(0)
            .Intersect(groupOfThree.ElementAt(1))
            .Intersect(groupOfThree.ElementAt(2)))
        .Select(character => char.IsUpper(character)
            ? character - 0x40 + 26 // First char before 'A' in ASCII
            : character - 0x60) // First char before 'a' in ASCII
        .Sum()
);

