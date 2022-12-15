using MoreLinq;

var visitedTailPositions = new HashSet<(int, int)>() { (0, 0) };
var ropeKnots = Enumerable.Range(0, 10).Select(_ => new Point()).ToArray();
File.ReadAllLines("input.txt")
    .Select(line => line.Split(' '))
    .SelectMany(tokens => Enumerable
        .Range(0, int.Parse(tokens[1]))
        .Select(_ => tokens[0] switch
        {
            "L" => new Point { X = -1, Y = 0 },
            "R" => new Point { X = 1, Y = 0 },
            "U" => new Point { X = 0, Y = 1 },
            "D" => new Point { X = 0, Y = -1 }
        }))
    .ForEach(step =>
    {
        ropeKnots
            .Window(2)
            .ForEach((pair, index) =>
            {
                pair[0].X += step.X;
                pair[0].Y += step.Y;

                var tailOffsetToHeadX = pair[0].X - pair[1].X;
                var tailOffsetToHeadY = pair[0].Y - pair[1].Y;
                var tailDistanceToHeadX = Math.Abs(tailOffsetToHeadX);
                var tailDistanceToHeadY = Math.Abs(tailOffsetToHeadY);
                if (tailDistanceToHeadX > 1 || tailDistanceToHeadY > 1)
                {
                    step.X = Math.Sign(tailOffsetToHeadX);
                    step.Y = Math.Sign(tailOffsetToHeadY);
                }
                else
                {
                    step.X = 0;
                    step.Y = 0;
                }
            });
        var tail = ropeKnots.Last();
        tail.X += step.X;
        tail.Y += step.Y;
        visitedTailPositions.Add((tail.X, tail.Y));
    });
Console.WriteLine(visitedTailPositions.Count);

public class Point { public int X; public int Y; };
