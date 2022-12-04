System.Console.WriteLine(
    System.IO.File
        .ReadAllLines("input.txt")
        .Select(line => line.Split(","))
        .Select(pair => (First: pair[0].Split('-'), Second: pair[1].Split('-')))
        .Select(pair => (
            First: (RangeStart: int.Parse(pair.First[0]), RangeEnd: int.Parse(pair.First[1])),
            Second: (RangeStart: int.Parse(pair.Second[0]), RangeEnd: int.Parse(pair.Second[1]))
        ))
        .Select(pair => Enumerable.Range(pair.First.RangeStart, pair.First.RangeEnd - pair.First.RangeStart + 1)
            .Intersect(Enumerable.Range(pair.Second.RangeStart, pair.Second.RangeEnd - pair.Second.RangeStart + 1))
            .Any() ? 1 : 0)
        .Sum()
);

