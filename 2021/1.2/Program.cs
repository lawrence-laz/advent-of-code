using System.Globalization;

var input = File
    .ReadAllLines("input.txt")
    .Select(line => int.Parse(line, CultureInfo.InvariantCulture));

var sums = input
    .Zip(input.Skip(1), input.Skip(2))
    .Select(items => items.First + items.Second + items.Third);

var output = sums
    .Zip(sums.Skip(1))
    .Count(items => items.First < items.Second);

System.Console.WriteLine(output);

