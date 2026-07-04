defmodule MedplumElixir.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/CodeDuckers-LLC/medplum_elixir"

  def project do
    [
      app: :medplum_elixir,
      version: @version,
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:req, "~> 0.5"},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false}
    ]
  end

  defp description do
    "A lightweight Elixir client for Medplum's FHIR API."
  end

  defp package do
    [
      name: "medplum_elixir",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Medplum" => "https://www.medplum.com"
      },
      maintainers: ["CodeDuckers, LLC"]
    ]
  end

  defp docs do
    [
      main: "Medplum",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
