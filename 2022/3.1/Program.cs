System.Console.WriteLine(
    System.IO.File
        .ReadAllLines("input.txt")
        .SelectMany(line => line.Take(line.Length / 2).Intersect(line.Skip(line.Length / 2)))
        .Select(character => char.IsUpper(character)
            ? character - 0x40 + 26 // First char before 'A' in ASCII
            : character - 0x60) // First char before 'a' in ASCII
        .Sum()
);

