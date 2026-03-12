defmodule Snake.Player do
  @moduledoc "Gestión de jugadores y puntajes"

  def list do
    #Esta función carga todos los jugadores guardados.
    file_path = "players.db"
    if File.exists?(file_path) do
      File.read!(file_path) |> :erlang.binary_to_term()
    else
      %{}
    end
  end

  def create(name) do
    #crear jugador
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
    #eliminar jugador
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
    #obtener puntaje
    players = list()
    Map.get(players, name, nil)
  end

  def update_score(name, score) do
    #Actualizar puntaje
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
    #listar jugadores por puntaje
    list()
    |> Enum.sort_by(fn {_name, score} -> -score end)
  end

  defp save_players(players) do
    #guardar jugadores en un archivo
    File.write!("players.db", :erlang.term_to_binary(players))
  end
end
