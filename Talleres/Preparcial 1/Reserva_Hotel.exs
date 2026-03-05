defmodule Reserva_Hotel do

  def main do
    numero_noches =
      "Ingrese el numero de noches: "
      |> Util.ingresar(:entero)

    tipo_cliente =
      "Ingrese el tipo de cliente (frecuente, corporativo, ocasional): "
      |> Util.ingresar(:texto)

    temporada =
      "Ingrese la temporada (Alta, Baja): "
      |> Util.ingresar(:texto)

    tarifa = tarifa_base(numero_noches)

    recargo = recargo_temporada(temporada, tarifa)

    descuento = descuento_tipo(tipo_cliente, recargo)

    descuento=round(tarifa)

    generar_mensaje(descuento, numero_noches, tipo_cliente, temporada, tarifa, recargo)
  end



  def tarifa_base(numero_noches) when numero_noches <= 2, do: 120000
  def tarifa_base(numero_noches) when numero_noches <= 5, do: 100000
  def tarifa_base(_numero_noches), do: 85000



  defp recargo_temporada(temporada,tarifa_base) do

    cond do
      temporada=="Alta" ->
        tarifa_base *1.25

      temporada=="Baja" ->
        tarifa_base *1

        true-> "ingrese correctamente la temporada: "
    end

  end





  defp descuento_tipo(:frecuente, total) do
    total * 0.80
  end

  defp descuento_tipo(:corporativo, total) do
    total * 0.85
  end

  defp descuento_tipo(_, total) do
    total
  end



  defp generar_mensaje(total, numero_noches, tipo_cliente, temporada, tarifa_base, recargo) do
    IO.puts("""
    ----- RESUMEN RESERVA -----
    Noches: #{numero_noches}
    Tipo cliente: #{tipo_cliente}
    Temporada: #{temporada}
    Tarifa base por noche: #{tarifa_base}
    Total con recargo: #{recargo}
    Total a pagar con descuento: #{total}
    """)
  end

end

Reserva_Hotel.main()
