defmodule CRUDimentary.Ecto.Filter do
  import Ecto.Query

  def call(queriable, [], _, _), do: queriable

  def call(queriable, filters, mapping, custom_filters) when is_list(filters) do
    dynamic =
      Enum.reduce(
        filters,
        dynamic([q], 1 == 0),
        &build_filter(&1, &2, mapping, custom_filters)
      )

    from(
      queriable,
      where: ^dynamic
    )
  end

  def call(queriable, _, _, _), do: queriable

  defp build_filter(filter_input, dynamic, mapping, filters) do
    dynamic(
      [q],
      ^dynamic or ^process_filter_input(filter_input, mapping, filters)
    )
  end

  defp process_filter_input(filter_input, mapping, filters) do
    if List.first(Map.keys(filter_input)) do
      Enum.reduce(
        filter_input,
        dynamic([q], 1 == 1),
        &process_filter_attribute(&1, &2, mapping, filters)
      )
    else
      dynamic([q], 1 == 0)
    end
  end

  defp process_filter_attribute(
         {attribute, input},
         acc_dynamic,
         mapping,
         filters
       ) do
    Enum.reduce(
      input,
      acc_dynamic,
      &build_dynamic_matcher(attribute, &1, &2, mapping, filters)
    )
  end

  defp build_dynamic_matcher(
         attribute,
         {matcher, value},
         dynamic,
         mapping,
         filters
       ) do
    attribute = resolve_attribute(attribute, mapping)

    case matcher do
      :null ->
        if value do
          dynamic([e], ^dynamic and is_nil(field(e, ^attribute)))
        else
          dynamic([e], ^dynamic and not is_nil(field(e, ^attribute)))
        end

      :eq ->
        if value do
          dynamic([e], ^dynamic and field(e, ^attribute) == ^value)
        else
          build_dynamic_matcher(
            attribute,
            {:null, true},
            dynamic,
            mapping,
            filters
          )
        end

      :ne ->
        if value do
          dynamic([e], ^dynamic and field(e, ^attribute) != ^value)
        else
          build_dynamic_matcher(
            attribute,
            {:null, false},
            dynamic,
            mapping,
            filters
          )
        end

      :cont ->
        dynamic([e], ^dynamic and ilike(field(e, ^attribute), ^"%#{value}%"))

      :not_cont ->
        dynamic(
          [e],
          ^dynamic and not ilike(field(e, ^attribute), ^"%#{value}%")
        )

      :starts_with ->
        dynamic(
          [e],
          ^dynamic and ilike(field(e, ^attribute), ^"#{value}%")
        )

      :ends_with ->
        dynamic(
          [e],
          ^dynamic and ilike(field(e, ^attribute), ^"%#{value}")
        )

      :gt ->
        dynamic([e], ^dynamic and field(e, ^attribute) > ^value)

      :gte ->
        dynamic([e], ^dynamic and field(e, ^attribute) >= ^value)

      :lt ->
        dynamic([e], ^dynamic and field(e, ^attribute) < ^value)

      :lte ->
        dynamic([e], ^dynamic and field(e, ^attribute) <= ^value)

      :in ->
        dynamic([e], ^dynamic and field(e, ^attribute) in ^value)

      :not_in ->
        dynamic([e], ^dynamic and field(e, ^attribute) not in ^value)

      _ ->
        extract_custom_filter(filters, attribute, matcher).(
          attribute,
          value,
          dynamic
        )
    end
  end

  defp resolve_attribute(attribute, mapping) when is_map(mapping) do
    if Map.has_key?(mapping, attribute) do
      mapping[attribute] |> String.split("/") |> List.last() |> String.to_atom()
    else
      attribute
    end
  end

  defp resolve_attribute(attribute, _), do: attribute

  defp extract_custom_filter(filters, attribute, matcher) do
    filters = filters || %{}
    filters = filters[attribute] || %{}
    filters[matcher] || fn _, _, dynamic -> dynamic end
  end
end
