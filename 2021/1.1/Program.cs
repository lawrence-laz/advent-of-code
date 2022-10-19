using System.Globalization;

var input = File
    .ReadAllLines("input.txt")
    .Select(line => int.Parse(line, CultureInfo.InvariantCulture));

var output = input
    .Zip(input.Skip(1))
    .Count(items => items.First < items.Second);

System.Console.WriteLine(output);

