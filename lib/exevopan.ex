defmodule Exevopan do
  def get_auction_links(max_pages \\ 117_952) do
    1..max_pages
    |> Enum.map(fn page ->
      "https://www.exevopan.com/pl?mode=history&descending=true&currentPage=#{page}"
    end)
    |> Enum.with_index(1)
    |> Task.async_stream(fn {link, page} ->
      IO.puts("Parsing page #{page} out of #{max_pages}...")

      Req.get!(link).body
      |> parse_page()
    end)
    |> Enum.flat_map(fn {:ok, links_list} -> links_list end)
  end

  defp parse_page(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find(".character-mini-card a")
    |> Enum.map(fn {"a", [{"href", link} | _tail], _} -> link end)
    |> Enum.filter(fn link ->
      String.starts_with?(link, "https://www.tibia.com/charactertrade")
    end)
  end

  def to_file(links) do
    File.write!("historical_auctions.txt", links |> Enum.join("\n"), [:write])
  end
end
