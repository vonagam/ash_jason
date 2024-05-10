defmodule AshJason.MixProject do
  use Mix.Project

  @name :ash_jason
  @version "0.3.1"
  @description "Ash resource extension for implementing Jason protocol"
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
      docs: docs(),
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
      {:ash, ">= 3.0.0-rc.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
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
        "documentation/dsls/DSL:-AshJason.Extension.md": [title: "DSL: AshJason.Extension"],
      ],
    ]
  end

  defp aliases() do
    [
      docs: ["spark.cheat_sheets", "docs", "spark.replace_doc_links", "spark.cheat_sheets_in_search"],
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshJason.Extension",
      "spark.cheat_sheets_in_search": "spark.cheat_sheets_in_search --extensions AshJason.Extension",
      "spark.formatter": ["spark.formatter --extensions AshJason.Extension", "format .formatter.exs"],
    ]
  end
end
