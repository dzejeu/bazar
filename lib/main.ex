defmodule Main do
  require Bazar

  def run do
    links =
      File.read!("historical_auctions.txt")
      |> String.split("\n")
      |> Enum.filter(fn x -> x != "" end)

    total = length(links)

    header = [
      "dist",
      "name",
      "lvl",
      "voc",
      "sex",
      "world",
      "auction_status",
      "price",
      "axe",
      "club",
      "fish",
      "fist",
      "mlvl",
      "shield",
      "sword",
      "charms"
    ]

    File.write!("historical_data.csv", Enum.join(header, ",") <> "\n", [:write])

    for {link, n} <- Enum.with_index(links, 1) do
      IO.puts("Fetching page #{n}/#{total}")

      data =
        Bazar.parse_auction_page(link)
        |> Map.update!(:charms, fn charms -> Enum.join(charms, ";") end)

      File.write!("historical_data.csv", (data |> Map.values() |> Enum.join(",")) <> "\n", [
        :append
      ])
    end
  end
end
