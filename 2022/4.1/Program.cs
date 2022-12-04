System.Console.WriteLine(
    System.IO.File
        .ReadAllLines("input.txt")
        .Select(line => line.Split(","))
        .Select(pair => (First: pair[0].Split('-'), Second: pair[1].Split('-')))
        .Select(pair => (
            First: (RangeStart: int.Parse(pair.First[0]), RangeEnd: int.Parse(pair.First[1])),
            Second: (RangeStart: int.Parse(pair.Second[0]), RangeEnd: int.Parse(pair.Second[1]))
        ))
        .Select(pair => pair.First.RangeStart <= pair.Second.RangeStart && pair.First.RangeEnd >= pair.Second.RangeEnd
            ? 1
            : pair.Second.RangeStart <= pair.First.RangeStart && pair.Second.RangeEnd >= pair.First.RangeEnd
            ? 1
            : 0)
        .Sum()
);

