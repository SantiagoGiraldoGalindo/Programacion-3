defmodule Inmobiliaria.Location do
  @moduledoc """
  Valida y gestiona ubicaciones válidas desde data/locations.dat.
  """

  @locations_file "data/locations.dat"

  @default_locations [
    "Armenia",
    "Bogota",
    "Medellin",
    "Cali",
    "Barranquilla",
    "Cartagena",
    "Pereira",
    "Manizales",
    "Ibague",
    "Bucaramanga",
    "Santa Marta",
    "Cucuta",
    "Villavicencio",
    "Pasto",
    "Monteria"
  ]

  @doc "Inicializa el archivo de ubicaciones si no existe."
  def init do
    File.mkdir_p!("data")

    unless File.exists?(@locations_file) do
      content = Enum.join(@default_locations, "\n") <> "\n"
      File.write!(@locations_file, content)
    end
  end

  @doc "Devuelve la lista de ubicaciones válidas."
  def list do
    init()

    case File.read(@locations_file) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.map(&String.trim/1)

      {:error, _} ->
        @default_locations
    end
  end

  @doc "Devuelve true si la ubicación es válida (case-insensitive)."
  def valid?(location) do
    valid_list = list() |> Enum.map(&String.downcase/1)
    String.downcase(location) in valid_list
  end

  @doc "Agrega una nueva ubicación."
  def add(location) do
    init()
    File.write!(@locations_file, location <> "\n", [:append])
  end
end
