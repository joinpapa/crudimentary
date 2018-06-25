defmodule CRUDimentary.MixProject do
  use Mix.Project

  def project do
    [
      app: :crudimentary,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "CRUDimentary",
      source_url: "https://github.com/stankec/crudimentary",
      docs: [
        main: "Crudimentary",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.16"},
      {:odgn_json_pointer, "~> 2.3"},
      {:inflex, "~> 1.10.0"},
      {:paginator, "~> 0.3"},
      {:phoenix, ">= 0.0.0"},
      {:absinthe, "~> 1.4"},
      {:delirium_tremex, github: "floatingpointio/delirium_tremex"}
    ]
  end
end
