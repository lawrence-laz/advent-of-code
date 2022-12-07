using MoreLinq;
using static MoreLinq.MoreEnumerable;

Console.WriteLine(
    File.ReadAllLines("input.txt")
        .Skip(1)
        .Where(line => !line.EndsWith("ls"))
        .Select(line => line.TrimStart("$ ").Split(' '))
        .Select(tokens =>
            (
                ChangeDirectoryTo: tokens[0] == "cd" ? tokens[1] : ".",
                FileSize: int.TryParse(tokens[0], out var size) ? size : 0
            ))
        .Aggregate(
            (Stack: new Stack<string>(), CurrentPath: "/", Sizes: new Dictionary<string, int>()),
            (state, command) =>
            {
                if (command.ChangeDirectoryTo == "..")
                {
                    state.Stack.Pop();
                }
                else if (command.ChangeDirectoryTo != ".")
                {
                    state.CurrentPath = Path.GetFullPath(Path.Combine(state.CurrentPath, command.ChangeDirectoryTo));
                    state.Stack.Push(state.CurrentPath);
                }
                else
                {
                    state.Stack.ToList().ForEach(path => state.Sizes[path] = state.Sizes.GetOrAdd(path, () => 0) + command.FileSize);
                }

                return state;
            })
        .Sizes.Values
        .Where(size => size <= 100000)
        .Sum()
);

