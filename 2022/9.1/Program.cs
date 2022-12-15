using MoreLinq;

var visitedTailPositions = new HashSet<(int, int)>() { (0, 0) };
var tailPosition = (X: 0, Y: 0);
var headPosition = (X: 0, Y: 0);
File.ReadAllLines("input.txt")
    .Select(line => line.Split(' '))
    .SelectMany(tokens => Enumerable.Repeat(
        tokens[0] switch
        {
            "L" => (X: -1, Y: 0),
            "R" => (X: 1, Y: 0),
            "U" => (X: 0, Y: 1),
            "D" => (X: 0, Y: -1)
        },
        int.Parse(tokens[1])))
    .ForEach(step =>
    {
        headPosition.X += step.X;
        headPosition.Y += step.Y;
        var tailDistanceToHeadX = Math.Abs(headPosition.X - tailPosition.X);
        var tailDistanceToHeadY = Math.Abs(headPosition.Y - tailPosition.Y);
        if (tailDistanceToHeadX > 1 || tailDistanceToHeadY > 1)
        {
            // tailPosition.X += step.X;
            // tailPosition.Y += step.Y;
            tailPosition.X = headPosition.X - step.X;
            tailPosition.Y = headPosition.Y - step.Y;
            visitedTailPositions.Add(tailPosition);
        }
        Console.WriteLine($"H=({headPosition.X};{headPosition.Y});T=({tailPosition.X};{tailPosition.Y})");
    });
Console.WriteLine(visitedTailPositions.Count());
