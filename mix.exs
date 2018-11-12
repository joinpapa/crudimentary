defmodule CRUDimentary.MixProject do
  use Mix.Project

  def project do
    [
      app: :crudimentary,
      version: "0.2.2",
      elixir: "~> 1.7",
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
      {:absinthe, "~> 1.4"},
      {:ex_doc, "~> 0.16"},
      {:inflex, "~> 1.10.0"},
      {:odgn_json_pointer, "~> 2.3"},
      {:paginator, "~> 0.3"},
      {:phoenix, ">= 0.0.0"},
      {:confex, "~> 3.3.1"},
      {:dataloader, "~> 1.0.4"}
    ]
  end
end
