defmodule CRUDimentary.Absinthe.Middleware.HandleErrors do
  @moduledoc """
  Detetcs Ecto.Changeset errors in Absinthe resolution and makes them user friendly
  """
  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution

  def call(%{errors: [%Ecto.Changeset{} = cs]} = resolution, _config) do
    Resolution.put_result(resolution, {
      :error,
      format_changeset(cs)
    })
  end

  def call(resolution, _config) do
    resolution
  end

  defp format_changeset(cs) do
    formatter = fn {key, {value, context}} ->
      human_key =
        key
        |> to_string()
        |> String.capitalize()

      [message: "#{human_key} #{translate_error({value, context})}"]
    end

    Enum.map(cs.errors, formatter)
  end

  def translate_error({msg, opts}) do
    Gettext.dgettext(PapaPal.Gettext, "errors", msg, opts)
  end
end
