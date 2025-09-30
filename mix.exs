defmodule AshJason.MixProject do
  use Mix.Project

  @name :ash_jason
  @version "2.0.0"
  @description "Ash extension for implementing Jason protocol"
  @github_url "https://github.com/vonagam/ash_jason"

  def project() do
    [
      app: @name,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      package: package(),
      deps: deps(),
      docs: &docs/0,
      aliases: aliases(),
    ]
  end

  def application() do
    [extra_applications: [:logger]]
  end

  defp package() do
    [
      maintainers: ["Dmitry Maganov"],
      description: @description,
      licenses: ["MIT"],
      links: %{Github: @github_url},
      files: ~w(mix.exs lib .formatter.exs LICENSE.md  README.md),
    ]
  end

  defp deps() do
    [
      {:jason, "~> 1.4"},
      {:ash, "~> 3.5.36"},
      {:spark, ">= 2.1.21 and < 3.0.0"},
      {:igniter, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sourceror, "~> 1.7", only: [:dev, :test], runtime: false},
      {:freedom_formatter, "~> 2.1", only: [:dev, :test], runtime: false},
    ]
  end

  def docs() do
    [
      homepage_url: @github_url,
      source_url: @github_url,
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md": [title: "Guide"],
        "LICENSE.md": [title: "License"],
        "documentation/dsls/DSL-AshJason.Resource.md": [
          title: "DSL: AshJason.Resource",
          search_data: Spark.Docs.search_data_for(AshJason.Resource),
        ],
        "documentation/dsls/DSL-AshJason.TypedStruct.md": [
          title: "DSL: AshJason.TypedStruct",
          search_data: Spark.Docs.search_data_for(AshJason.TypedStruct),
        ],
      ],
    ]
  end

  defp aliases() do
    [
      docs: ["spark.cheat_sheets", "docs", "spark.replace_doc_links"],
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshJason.Resource,AshJason.TypedStruct",
      "spark.formatter": [
        "spark.formatter --extensions AshJason.Resource,AshJason.TypedStruct",
        "format .formatter.exs",
      ],
    ]
  end
end
