using MoreLinq;

Console.WriteLine(
    File.ReadAllText("input.txt")
        .Window(4)
        .TakeUntil(lastFour => lastFour.Distinct().Count() == 4)
        .Count() + 3
);

