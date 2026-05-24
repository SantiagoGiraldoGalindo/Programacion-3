defmodule Inmobiliaria.UserManager do
  @moduledoc """
  GenServer que gestiona usuarios: registro, login, puntajes y rankings.
  Persiste en data/users.dat
  """
  use GenServer

  @users_file "data/users.dat"

  # ── API pública ──────────────────────────────────────────────────────────────

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "Conecta/registra un usuario. Devuelve {:ok, user} | {:error, reason}"
  def connect(username, password, role \\ nil) do
    GenServer.call(__MODULE__, {:connect, username, password, role})
  end

  @doc "Desconecta un usuario activo."
  def disconnect(username) do
    GenServer.call(__MODULE__, {:disconnect, username})
  end

  @doc "Devuelve el mapa del usuario o nil."
  def get_user(username) do
    GenServer.call(__MODULE__, {:get_user, username})
  end

  @doc "Suma puntos a un usuario."
  def add_points(username, points) do
    GenServer.call(__MODULE__, {:add_points, username, points})
  end

  @doc "Devuelve lista de usuarios ordenados por puntaje desc."
  def ranking(role \\ nil) do
    GenServer.call(__MODULE__, {:ranking, role})
  end

  @doc "Lista los usuarios conectados actualmente."
  def connected_users do
    GenServer.call(__MODULE__, :connected_users)
  end

  # ── Callbacks ────────────────────────────────────────────────────────────────

  @impl true
  def init(_) do
    users = load_users()
    {:ok, %{users: users, connected: MapSet.new()}}
  end

  @impl true
  def handle_call({:connect, username, password, role}, _from, state) do
    case Map.get(state.users, username) do
      nil ->
        # Registro automático
        effective_role = role || "cliente"
        new_user = %{
          username: username,
          password: password,
          role: effective_role,
          score: 0
        }
        users = Map.put(state.users, username, new_user)
        connected = MapSet.put(state.connected, username)
        save_users(users)
        {:reply, {:ok, new_user, :registered},
         %{state | users: users, connected: connected}}

      user ->
        if user.password == password do
          connected = MapSet.put(state.connected, username)
          {:reply, {:ok, user, :logged_in},
           %{state | connected: connected}}
        else
          {:reply, {:error, "Contraseña incorrecta"}, state}
        end
    end
  end

  @impl true
  def handle_call({:disconnect, username}, _from, state) do
    connected = MapSet.delete(state.connected, username)
    {:reply, :ok, %{state | connected: connected}}
  end

  @impl true
  def handle_call({:get_user, username}, _from, state) do
    {:reply, Map.get(state.users, username), state}
  end

  @impl true
  def handle_call({:add_points, username, points}, _from, state) do
    case Map.get(state.users, username) do
      nil ->
        {:reply, {:error, "Usuario no encontrado"}, state}

      user ->
        updated = Map.update!(user, :score, &(&1 + points))
        users = Map.put(state.users, username, updated)
        save_users(users)
        {:reply, {:ok, updated.score}, %{state | users: users}}
    end
  end

  @impl true
  def handle_call({:ranking, role}, _from, state) do
    list =
      state.users
      |> Map.values()
      |> then(fn users ->
        if role, do: Enum.filter(users, &(&1.role == role)), else: users
      end)
      |> Enum.sort_by(& &1.score, :desc)

    {:reply, list, state}
  end

  @impl true
  def handle_call(:connected_users, _from, state) do
    {:reply, MapSet.to_list(state.connected), state}
  end

  # ── Persistencia ─────────────────────────────────────────────────────────────

  defp load_users do
    File.mkdir_p!("data")

    case File.read(@users_file) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.reduce(%{}, fn line, acc ->
          case parse_user_line(line) do
            {:ok, user} -> Map.put(acc, user.username, user)
            _ -> acc
          end
        end)

      {:error, _} ->
        %{}
    end
  end

  defp save_users(users) do
    File.mkdir_p!("data")

    content =
      users
      |> Map.values()
      |> Enum.map(fn u ->
        "#{u.username}|#{u.role}|#{u.password}|#{u.score}"
      end)
      |> Enum.join("\n")

    File.write!(@users_file, content <> "\n")
  end

  defp parse_user_line(line) do
    case String.split(line, "|") do
      [username, role, password, score] ->
        {:ok,
         %{
           username: username,
           role: role,
           password: password,
           score: String.to_integer(score)
         }}

      _ ->
        :error
    end
  end
end
