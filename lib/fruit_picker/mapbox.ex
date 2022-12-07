defmodule FruitPicker.Mapbox do
  @moduledoc """
  Uses the mapbox API to check if a postcode is roughly in the operating
  area for NFFTT.
  """

  @base_url "https://api.mapbox.com/geocoding/v5/mapbox.places/"
  @mapbox_api_key System.get_env("MAPBOX_API_KEY")

  # Eglinton Ave East at Birchmount Rd, Toronto, ON 43.730009, -79.277911 top right / north east
  # Birch Cliff Toronto, ON 43.690326, -79.261176 bottom right / south east
  # Long Branch, Toronto, ON 43.587528, -79.538135 bottom left / south west
  # Eringate, Etobicoke, ON 43.671022, -79.575729 top left / north west

  def check_in_bounds(postal_code) when byte_size(postal_code) > 0 do
    postal_code = String.replace(postal_code, " ", "")
    %{"features" => features} = fetch_address_list(postal_code)
    length(features) > 0
  end

  def check_in_bounds(_postal_code) do
    false
  end

  defp fetch_address_list(postal_code) do
    case HTTPoison.get(create_url(postal_code)) do
      {:ok, response} ->
        if response.status_code == 200 do
          Jason.decode!(response.body)
        else
          reason = "wrong response (#{response.status_code})"
          raise(reason)
        end

      {:error, %HTTPoison.Error{:reason => reason}} ->
        raise(reason)
    end
  end

  defp create_url(search_term) do
    "#{@base_url}#{search_term}.json?country=ca&bbox=#{bounding_box()}&fuzzyMatch=false&access_token=#{@mapbox_api_key}"
  end

  defp bounding_box() do
    # bounding box (bbox) is minLong, minLat, maxLong, maxLat
    "-79.575729,43.587528,-79.261176,43.730009"
  end
end
