defmodule Inmobiliaria.PropertyManager do
  @moduledoc """
  GenServer que administra el catálogo de propiedades.
  - Genera IDs únicos
  - Inicia procesos Property bajo PropertySupervisor
  - Carga y persiste properties.dat
  - Sincroniza el estado tras cada operación
  """
  use GenServer

  alias Inmobiliaria.{Property, PropertySupervisor}

  @properties_file "data/properties.dat"

  # ── API pública ──────────────────────────────────────────────────────────────

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "Publica una nueva propiedad. Devuelve {:ok, property} | {:error, reason}."
  def publish(attrs) do
    GenServer.call(__MODULE__, {:publish, attrs})
  end

  @doc "Lista propiedades con filtros opcionales."
  def list(filters \\ %{}) do
    GenServer.call(__MODULE__, {:list, filters})
  end

  @doc "Devuelve una propiedad por id."
  def get(property_id) do
    GenServer.call(__MODULE__, {:get, property_id})
  end

  @doc "Realiza operación (compra/arriendo) sobre una propiedad."
  def operate(property_id, client, operation) do
    GenServer.call(__MODULE__, {:operate, property_id, client, operation})
  end

  @doc "Persiste el estado actual de todas las propiedades."
  def sync_all do
    GenServer.call(__MODULE__, :sync_all)
  end

  # ── Callbacks ────────────────────────────────────────────────────────────────

  @impl true
  def init(_) do
    # Necesita el Registry antes de iniciar
    Registry.start_link(keys: :unique, name: Inmobiliaria.PropertyRegistry)
    properties = load_properties()

    # Inicia un proceso Property por cada propiedad persistida
    Enum.each(properties, fn {_id, prop} ->
      start_property_process(prop)
    end)

    {:ok, %{properties: properties, counter: map_size(properties)}}
  end

  @impl true
  def handle_call({:publish, attrs}, _from, state) do
    counter = state.counter + 1
    id = "prop#{String.pad_leading(Integer.to_string(counter), 3, "0")}"

    property = %{
      id: id,
      tipo: Map.get(attrs, :tipo, "casa"),
      modalidad: Map.get(attrs, :modalidad, "venta"),
      ubicacion: Map.get(attrs, :ubicacion, "Desconocida"),
      precio: Map.get(attrs, :precio, 0),
      habitaciones: Map.get(attrs, :habitaciones, 0),
      area: Map.get(attrs, :area, 0),
      status: "disponible",
      owner: Map.get(attrs, :owner, ""),
      client: nil
    }

    case start_property_process(property) do
      {:ok, _pid} ->
        properties = Map.put(state.properties, id, property)
        save_properties(properties)
        {:reply, {:ok, property}, %{state | properties: properties, counter: counter}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:list, filters}, _from, state) do
    # Sincroniza estado desde procesos vivos antes de filtrar
    live_properties =
      state.properties
      |> Map.values()
      |> Enum.map(fn prop ->
        case Property.get(prop.id) do
          p when is_map(p) -> p
          _ -> prop
        end
      end)

    result = apply_filters(live_properties, filters)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get, property_id}, _from, state) do
    case Map.get(state.properties, property_id) do
      nil ->
        {:reply, {:error, "Propiedad no encontrada"}, state}

      _prop ->
        live = Property.get(property_id)
        {:reply, {:ok, live}, state}
    end
  end

  @impl true
  def handle_call({:operate, property_id, client, operation}, _from, state) do
    case Map.get(state.properties, property_id) do
      nil ->
        {:reply, {:error, "Propiedad no encontrada"}, state}

      _prop ->
        # La operación se delega al proceso Property (serializa concurrencia)
        case Property.operate(property_id, client, operation) do
          {:ok, updated_prop} ->
            properties = Map.put(state.properties, property_id, updated_prop)
            save_properties(properties)
            {:reply, {:ok, updated_prop}, %{state | properties: properties}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call(:sync_all, _from, state) do
    properties =
      state.properties
      |> Enum.map(fn {id, prop} ->
        live =
          case Property.get(id) do
            p when is_map(p) -> p
            _ -> prop
          end

        {id, live}
      end)
      |> Map.new()

    save_properties(properties)
    {:reply, :ok, %{state | properties: properties}}
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp start_property_process(property) do
    DynamicSupervisor.start_child(
      PropertySupervisor,
      {Inmobiliaria.Property, property}
    )
  end

  defp apply_filters(properties, filters) do
    properties
    |> filter_by(:tipo, filters[:tipo])
    |> filter_by(:modalidad, filters[:modalidad])
    |> filter_by(:ubicacion, filters[:ubicacion])
    |> filter_by(:status, filters[:status])
    |> filter_price_range(filters[:precio_min], filters[:precio_max])
  end

  defp filter_by(list, _field, nil), do: list
  defp filter_by(list, field, value) do
    Enum.filter(list, fn p ->
      String.downcase(to_string(Map.get(p, field))) ==
        String.downcase(to_string(value))
    end)
  end

  defp filter_price_range(list, nil, nil), do: list
  defp filter_price_range(list, min, max) do
    Enum.filter(list, fn p ->
      price = p.precio
      (is_nil(min) or price >= min) and (is_nil(max) or price <= max)
    end)
  end

  # ── Persistencia ─────────────────────────────────────────────────────────────

  defp load_properties do
    File.mkdir_p!("data")

    case File.read(@properties_file) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.reduce(%{}, fn line, acc ->
          case parse_property_line(line) do
            {:ok, prop} -> Map.put(acc, prop.id, prop)
            _ -> acc
          end
        end)

      {:error, _} ->
        %{}
    end
  end

  defp save_properties(properties) do
    File.mkdir_p!("data")

    content =
      properties
      |> Map.values()
      |> Enum.map(&serialize_property/1)
      |> Enum.join("\n")

    File.write!(@properties_file, content <> "\n")
  end

  defp serialize_property(p) do
    "#{p.id}|#{p.tipo}|#{p.modalidad}|#{p.ubicacion}|#{p.precio}|" <>
      "#{p.habitaciones}|#{p.area}|#{p.status}|#{p.owner}|#{p.client || ""}"
  end

  defp parse_property_line(line) do
    case String.split(line, "|") do
      [id, tipo, modalidad, ubicacion, precio, habitaciones, area, status, owner, client] ->
        {:ok,
         %{
           id: id,
           tipo: tipo,
           modalidad: modalidad,
           ubicacion: ubicacion,
           precio: String.to_integer(precio),
           habitaciones: String.to_integer(habitaciones),
           area: String.to_integer(area),
           status: status,
           owner: owner,
           client: if(client == "", do: nil, else: client)
         }}

      _ ->
        :error
    end
  end
end
