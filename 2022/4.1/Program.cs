System.Console.WriteLine(
    System.IO.File
        .ReadAllLines("input.txt")
        .Select(line => line.Split(","))
        .Select(pair => (First: pair[0].Split('-'), Second: pair[1].Split('-')))
        .Select(pair => (pair.First[0].ParseInt()..pair.First[1].ParseInt())
            .ContainsOrIsContainedBy(pair.Second[0].ParseInt()..pair.Second[1].ParseInt()))
        .Count(isContained => isContained is true)
);

