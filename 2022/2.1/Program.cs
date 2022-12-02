System.Console.WriteLine(
    System.IO.File
        .ReadAllLines("input.txt")
        .Select(line => (Opponent: line.Split(" ")[0], Me: line.Split(" ")[1]))
        .Select(game => (game.Opponent, game.Me) switch
        {
            (_, "X") => 1,
            (_, "Y") => 2,
            (_, "Z") => 3
        } + (game.Opponent, game.Me) switch
        {
            ("A", "X") or ("B", "Y") or ("C", "Z") => 3,
            ("C", "X") or ("A", "Y") or ("B", "Z") => 6,
            _ => 0
        })
        .Sum()
);

