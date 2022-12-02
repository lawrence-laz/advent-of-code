System.Console.WriteLine(
    System.IO.File
        .ReadAllLines("input.txt")
        .Select(line => (Opponent: line.Split(" ")[0], Outcome: line.Split(" ")[1]))
        .Select(game => (Outcome: game.Outcome, Me: (game.Opponent, game.Outcome) switch
        {
            ("A", "X") => "C",
            ("B", "X") => "A",
            ("C", "X") => "B",
            (_, "Y") => game.Opponent,
            ("A", "Z") => "B",
            ("B", "Z") => "C",
            ("C", "Z") => "A",
        }))
        .Select(game => game.Me switch
        {
            "A" => 1,
            "B" => 2,
            "C" => 3
        } + game.Outcome switch
        {
            "X" => 0,
            "Y" => 3,
            "Z" => 6,
        })
        .Sum()
);

