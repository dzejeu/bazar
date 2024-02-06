defmodule Bazar do
  @request_delay 600

  def get_trade_history_page(page_num) do
    resp =
      Req.get!(
        "https://www.tibia.com/charactertrade/?subtopic=pastcharactertrades&currentpage=#{page_num}"
      )

    :timer.sleep(@request_delay)
    resp.body
  end

  def history_page_to_auction_urls(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find(".AuctionCharacterName a")
    |> Enum.map(fn {"a", [{"href", link}], _} -> link end)
  end

  def parse_auction_page(auction_link) do
    html = Req.get!(auction_link).body |> Floki.parse_document!()
    :timer.sleep(@request_delay)

    parse_fns = [
      &get_char_name/1,
      &get_char_main_info/1,
      &get_server/1,
      &get_auction_price/1,
      &get_skills/1,
      &get_gold/1,
      &get_available_charms/1,
      &get_charms/1
    ]

    results =
      for parse_fn <- parse_fns, into: [] do
        parse_fn.(html)
      end

    Enum.reduce(results, &Map.merge/2)
  end

  defp get_char_name(html_tree) do
    html_tree
    |> Floki.find(".AuctionCharacterName")
    |> Enum.map(fn {"div", _, [char_name]} -> char_name end)
    |> Map.new(fn v -> {:name, v} end)
  end

  defp get_char_main_info(html_tree) do
    # TODO: simplify parsing if possible

    # get all div content
    # there has to be only one match
    {"div", _, children} = html_tree |> Floki.find(".AuctionHeader") |> Enum.at(0)

    # find div's text
    main_info_str =
      children
      |> Enum.filter(fn child -> is_bitstring(child) and String.starts_with?(child, "Level") end)
      |> Enum.at(0)

    # parse main char info text
    [lvl, voc, sex, _] = main_info_str |> String.split("|")

    %{
      lvl: lvl |> String.replace("Level:", "") |> String.trim() |> String.to_integer(),
      voc:
        voc
        |> String.replace(["Vocation:", "Royal", "Elite", "Master", "Elder"], "")
        |> String.trim(),
      sex: sex |> String.trim()
    }
  end

  defp get_server(html_tree) do
    # TODO: simplify Floki find to ".AuctionHeader href"
    html_tree
    |> Floki.find(".AuctionHeader a")
    |> Floki.attribute("href")
    |> Enum.at(0)
    |> String.split("&world=")
    |> Map.new(fn v -> {:world, v} end)
  end

  defp get_auction_price(html_tree) do
    {"div", _, [auction_label]} = html_tree |> Floki.find(".ShortAuctionDataLabel") |> Enum.at(2)

    [{"b", _, [auction_price]}] =
      html_tree |> Floki.find(".ShortAuctionDataValue") |> Floki.find("b")

    status =
      case auction_label do
        "Winning Bid:" -> "sold"
        "Minimum Bid:" -> "expired"
        "Current Bid:" -> "processing"
        _ -> "unknown"
      end

    %{
      auction_status: status,
      price: auction_price |> String.replace(",", "") |> String.to_integer()
    }
  end

  defp get_skills(html_tree) do
    skills = [:axe, :club, :dist, :fish, :fist, :mlvl, :shield, :sword]

    html_tree
    |> Floki.find("#General .LevelColumn")
    |> Enum.map(fn {_, _, [skill]} -> String.to_integer(skill) end)
    |> Enum.zip(skills)
    |> Map.new(fn {v, k} -> {k, v} end)
  end

  defp get_gold(html_tree) do
    %{gold: 0}
  end

  defp get_available_charms(html_tree) do
    %{available_charms: 0}
  end

  defp get_charms(html_tree) do
    all_charms = [
      "Parry",
      "Dodge",
      "Wound",
      "Zap",
      "Freeze",
      "Gut",
      "Poison",
      "Cripple",
      "Curse",
      "Enflame",
      "Divine Wrath",
      "Low Blow",
      "Numb",
      "Adrenaline Burst",
      "Cleanse",
      "Scavenge",
      "Bless",
      "Vampiric Embrace",
      "Void's Call"
    ]

    charms =
      html_tree
      |> Floki.find("#Charms .TableContent")
      |> Floki.find("td")
      |> Enum.map(fn {_, _, [td_val]} -> td_val end)
      |> Enum.filter(fn td_val -> td_val in all_charms end)

    %{charms: charms}
  end

  def parse_auction_history_page(page_num) do
    auction_urls =
      page_num
      |> get_trade_history_page()
      |> history_page_to_auction_urls()

    for auction_url <- auction_urls do
      parse_auction_page(auction_url) |> IO.inspect()
    end
  end
end
