defmodule Analyzer do
  def read_auction_data(filepath) do
    filepath
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(fn s -> s != "" end)
    |> Enum.map(fn row -> String.split(row, ",") end)
    |> Enum.map(fn [lvl, voc, world, status, price] ->
      %{
        lvl: String.to_integer(lvl),
        voc: voc,
        world: world,
        status: status,
        price: String.to_integer(price)
      }
    end)
  end

  def avg_price_for_lvl_span(auction_data, min_lvl, max_lvl, worlds \\ []) do
    auction_data
    |> Enum.filter(fn a -> a.status == "sold" and (a.world in worlds or worlds == []) end)
    |> Enum.filter(fn a -> a.lvl >= min_lvl and a.lvl <= max_lvl end)
    |> Enum.group_by(fn a -> a.voc end, fn a -> a.price end)
    |> Enum.map(fn {voc, tc} ->
      %{
        voc: voc,
        avg: Enum.sum(tc) / Enum.count(tc),
        count: Enum.count(tc),
        min_max: Enum.min_max(tc)
      }
    end)
  end
end
