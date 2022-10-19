using System.Globalization;

var input = File
    .ReadAllLines("input.txt")
    .Select(line => (
        Direction: line.Split(' ')[0],
        Units: int.Parse(line.Split(' ')[1], CultureInfo.InvariantCulture)))
    .ToList();

var horizontal = 0;
var depth = 0;
var aim = 0;

input.ForEach(command =>
{
    aim += command switch
    {
        { Direction: "down" } => command.Units,
        { Direction: "up" } => -command.Units,
        _ => 0
    };

    horizontal += command switch
    {
        { Direction: "forward" } => command.Units,
        _ => 0
    };

    depth += command switch
    {
        { Direction: "forward" } => command.Units * aim,
        _ => 0
    };
});

System.Console.WriteLine(horizontal * depth);
