defmodule Snake.Player do
  @moduledoc "Gestión de jugadores y puntajes"

  def list do
    file_path = "players.db"
    if File.exists?(file_path) do
      File.read!(file_path) |> :erlang.binary_to_term()
    else
      %{}
    end
  end

  def create(name) do
    players = list()
    if Map.has_key?(players, name) do
      {:error, :exists}
    else
      players = Map.put(players, name, 0)
      save_players(players)
      {:ok, name}
    end
  end

  def delete(name) do
    players = list()
    if Map.has_key?(players, name) do
      players = Map.delete(players, name)
      save_players(players)
      {:ok, :deleted}
    else
      {:error, :not_found}
    end
  end

  def get_score(name) do
    players = list()
    Map.get(players, name, nil)
  end

  def update_score(name, score) do
    players = list()
    if Map.has_key?(players, name) do
      players = Map.put(players, name, score)
      save_players(players)
      {:ok, score}
    else
      {:error, :not_found}
    end
  end

  def list_all do
    list()
    |> Enum.sort_by(fn {_name, score} -> -score end)
  end

  defp save_players(players) do
    File.write!("players.db", :erlang.term_to_binary(players))
  end
end
