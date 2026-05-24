defmodule Inmobiliaria.Property do
  @moduledoc """
  GenServer que representa una propiedad individual.
  Cada propiedad es un proceso independiente gestionado por PropertySupervisor.
  Maneja el estado de la propiedad y serializa operaciones concurrentes.
  """
  use GenServer

  # ── API pública ──────────────────────────────────────────────────────────────

  def start_link(property) do
    GenServer.start_link(__MODULE__, property,
      name: via(property.id))
  end

  @doc "Devuelve el estado actual de la propiedad."
  def get(property_id) do
    GenServer.call(via(property_id), :get)
  end

  @doc "Intenta comprar/arrendar la propiedad. Devuelve :ok | {:error, reason}."
  def operate(property_id, client, operation) do
    GenServer.call(via(property_id), {:operate, client, operation})
  end

  @doc "Actualiza campos de la propiedad (solo el propietario)."
  def update(property_id, changes) do
    GenServer.call(via(property_id), {:update, changes})
  end

  # ── Registro via ─────────────────────────────────────────────────────────────

  defp via(property_id) do
    {:via, Registry, {Inmobiliaria.PropertyRegistry, property_id}}
  end

  # ── Callbacks ────────────────────────────────────────────────────────────────

  @impl true
  def init(property) do
    {:ok, property}
  end

  @impl true
  def handle_call(:get, _from, property) do
    {:reply, property, property}
  end

  @impl true
  def handle_call({:operate, client, operation}, _from, property) do
    cond do
      property.status != "disponible" ->
        {:reply, {:error, "La propiedad no está disponible (estado: #{property.status})"}, property}

      operation == "compra" and property.modalidad != "venta" ->
        {:reply, {:error, "Esta propiedad es de arriendo, no de venta"}, property}

      operation == "arriendo" and property.modalidad != "arriendo" ->
        {:reply, {:error, "Esta propiedad es de venta, no de arriendo"}, property}

      true ->
        new_status =
          case operation do
            "compra" -> "vendida"
            "arriendo" -> "arrendada"
          end

        updated = Map.merge(property, %{status: new_status, client: client})
        {:reply, {:ok, updated}, updated}
    end
  end

  @impl true
  def handle_call({:update, changes}, _from, property) do
    updated = Map.merge(property, changes)
    {:reply, {:ok, updated}, updated}
  end
end
