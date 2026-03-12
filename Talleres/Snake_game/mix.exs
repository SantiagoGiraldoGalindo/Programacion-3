defmodule SnakeGame.MixProject do
  use Mix.Project

  def project do
    [
      app: :snake_game,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: mix_env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end

  defp mix_env do
    Mix.env()
  end
end
