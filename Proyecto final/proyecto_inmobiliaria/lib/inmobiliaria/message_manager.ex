defmodule Inmobiliaria.MessageManager do
  @moduledoc """
  GenServer que gestiona la mensajería entre clientes y propietarios.
  Persiste en data/messages.log
  """
  use GenServer

  @messages_file "data/messages.log"

  # ── API pública ──────────────────────────────────────────────────────────────

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc "Envía un mensaje de from_user al publicador de property_id."
  def send_message(property_id, from_user, text) do
    GenServer.call(__MODULE__, {:send, property_id, from_user, text})
  end

  @doc "Lista los mensajes de una propiedad."
  def get_messages(property_id) do
    GenServer.call(__MODULE__, {:get, property_id})
  end

  @doc "Lista todos los mensajes recibidos por un propietario."
  def get_owner_messages(owner) do
    GenServer.call(__MODULE__, {:get_owner, owner})
  end

  # ── Callbacks ────────────────────────────────────────────────────────────────

  @impl true
  def init(_) do
    messages = load_messages()
    {:ok, messages}
  end

  @impl true
  def handle_call({:send, property_id, from_user, text}, _from, messages) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    msg = %{
      property_id: property_id,
      from: from_user,
      text: text,
      timestamp: timestamp
    }

    new_messages = [msg | messages]
    append_message(msg)
    {:reply, :ok, new_messages}
  end

  @impl true
  def handle_call({:get, property_id}, _from, messages) do
    result =
      messages
      |> Enum.filter(&(&1.property_id == property_id))
      |> Enum.reverse()

    {:reply, result, messages}
  end

  @impl true
  def handle_call({:get_owner, owner}, _from, messages) do
    # Para mostrar mensajes, necesitamos saber qué propiedades son del owner
    # Delegamos la consulta al PropertyManager
    props =
      case Inmobiliaria.PropertyManager.list(%{}) do
        list when is_list(list) -> Enum.filter(list, &(&1.owner == owner))
        _ -> []
      end

    prop_ids = MapSet.new(Enum.map(props, & &1.id))

    result =
      messages
      |> Enum.filter(&MapSet.member?(prop_ids, &1.property_id))
      |> Enum.reverse()

    {:reply, result, messages}
  end

  # ── Persistencia ─────────────────────────────────────────────────────────────

  defp load_messages do
    File.mkdir_p!("data")

    case File.read(@messages_file) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.map(&parse_message_line/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.reverse()

      {:error, _} ->
        []
    end
  end

  defp append_message(msg) do
    File.mkdir_p!("data")
    line = "#{msg.timestamp}|#{msg.property_id}|#{msg.from}|#{msg.text}\n"
    File.write!(@messages_file, line, [:append])
  end

  defp parse_message_line(line) do
    case String.split(line, "|", parts: 4) do
      [timestamp, property_id, from, text] ->
        %{timestamp: timestamp, property_id: property_id, from: from, text: text}

      _ ->
        nil
    end
  end
end
