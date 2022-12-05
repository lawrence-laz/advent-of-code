using MoreLinq;

System.Console.WriteLine(
    System.IO.File
        .ReadAllLines("input.txt")
        .Split("")
        .Lead(1, (firstHalf, secondHalf) => (
            Stacks: firstHalf
                .Reverse()
                .Skip(1)
                .Select(line => line
                    .Batch(4)
                    .Select(crate => string.Concat(crate.Except(new[] { '[', ']', ' ' }))))
                .Transpose()
                .Select(column => column
                    .Where(crate => !string.IsNullOrWhiteSpace(crate))
                    .ToList()
                    )
                .ToList(),
            Operations: secondHalf?
                .Select(line => (
                    Count: line.Split(' ')[1].ParseInt(),
                    FromStack: line.Split(' ')[3].ParseInt() - 1,
                    ToStack: line.Split(' ')[5].ParseInt() - 1))))
        .Take(1)
        .Select(input => input.Operations
            .ToList()
            .Aggregate(input.Stacks, (stacks, operation) =>
                {
                    stacks[operation.ToStack].AddRange(stacks[operation.FromStack].ToArray()[^operation.Count..]);
                    stacks[operation.FromStack].RemoveRange(stacks[operation.FromStack].Count - operation.Count, operation.Count);
                    return stacks;
                }))
        .First()
        .Aggregate("", (result, stack) => result + stack.Last())
);

