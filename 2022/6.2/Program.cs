using MoreLinq;

Console.WriteLine(
    File.ReadAllText("input.txt")
        .Window(14)
        .TakeUntil(lastFour => lastFour.Distinct().Count() == 14)
        .Count() + 13
);

