System.Console.WriteLine(
    System.IO.File
        .ReadAllText("input.txt")
        .Split("\n\n")
        .Select(groupLines => groupLines
            .Split("\n")
            .Where(line => !line.IsNullOrEmpty())
            .Select(int.Parse)
            .Sum())
        .OrderByDescending()
        .Take(3)
        .Sum()
);
