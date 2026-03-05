defmodule Aerolinea do

  def main do

    destino =
      "ingresar destino(bogota, medellin, cartagena y san_andres)"
      |> Util.ingresar(:texto)
      |> String.to_atom()

    seleccion_silla =
      "desea seleccionar silla? (si/no)"
      |> Util.ingresar(:texto)

    maleta_bodega =
      "desea llevar maleta de bodega? (si/no)"
      |> Util.ingresar(:texto)

    seguro_viaje =
      "desea contratar seguro de viaje? (si/no)"
      |> Util.ingresar(:texto)

    tarifa_base = calcular_Tarifa(destino)
    tarifa_silla = calcular_Silla(seleccion_silla, tarifa_base)
    tarifa_maleta = calcular_Maleta(maleta_bodega, destino)
    tarifa_seguro = calcular_Seguro(seguro_viaje)
    tarifa_total = calcular_tarifa_total(tarifa_base, tarifa_silla, tarifa_maleta, tarifa_seguro)

    mensaje = generar_Mensaje(destino, seleccion_silla, maleta_bodega, seguro_viaje, tarifa_total)

    IO.puts(mensaje)

  end

  defp calcular_Tarifa(destino) do
    cond do
      destino == :bogota -> 500000
      destino == :medellin -> 400000
      destino == :cartagena -> 450000
      destino == :san_andres -> 600000
      true -> 0
    end
  end




  defp calcular_Silla(seleccion_silla, tarifa_base) do
    if seleccion_silla == "si" do
      15000
    else
      0
    end
  end

  defp calcular_Maleta(maleta_bodega, destino) do
    if maleta_bodega == "si" or destino == :san_andres do
      45000
    else
      0
    end
  end

  defp calcular_Seguro(seguro_viaje) do
    if seguro_viaje == "si" do
      12000
    else
      0
    end
  end




  defp calcular_tarifa_total(tarifa_base, tarifa_silla, tarifa_maleta, tarifa_seguro) do
    IO.puts("Tarifa base: #{tarifa_base}")
    IO.puts("Tarifa silla: #{tarifa_silla}")
    IO.puts("Tarifa maleta: #{tarifa_maleta}")
    IO.puts("Tarifa seguro: #{tarifa_seguro}")

    tarifa_base + tarifa_silla + tarifa_maleta + tarifa_seguro
  end




  defp generar_Mensaje(destino, seleccion_silla, maleta_bodega, seguro_viaje, tarifa_total) do
    "Su destino es #{destino}, seleccion silla: #{seleccion_silla}, maleta bodega: #{maleta_bodega}, seguro viaje: #{seguro_viaje}. El total a pagar es: #{tarifa_total}"
  end

end

Aerolinea.main()
