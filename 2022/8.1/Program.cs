using MoreLinq;

var id = 1;
var rows = File
    .ReadAllLines("input.txt")
    .Select(line => line
        .Select(character => (Height: int.Parse(character.ToString()), Id: id++))
        .ToArray())
    .ToArray();
var visibleTrees = new HashSet<int>();

rows.ForEach(row => RayCastForVisibleTrees(row)); // From left
rows.ForEach(row => RayCastForVisibleTrees(row.Reverse())); // From right
rows.Transpose().ForEach(row => RayCastForVisibleTrees(row)); // From top
rows.Transpose().ForEach(row => RayCastForVisibleTrees(row.Reverse())); // From bottom

void RayCastForVisibleTrees(IEnumerable<(int Height, int Id)> row)
{
    var highestTreeHeight = -1;
    row.ForEach(tree =>
    {
        if (tree.Height > highestTreeHeight)
        {
            visibleTrees.Add(tree.Id);
        }
        highestTreeHeight = Math.Max(highestTreeHeight, tree.Height);
    });
}

Console.WriteLine(visibleTrees.Count());
