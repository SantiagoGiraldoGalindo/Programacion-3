defmodule Parqueadero do
  def main do
    horas_Permanencia =
      "Ingresar horas de permanencia"
      |> Util.ingresar(:entero)

      cliente=tipo_Cliente= "ingresar que tipo de cliente es (frecuente o regular)"
      |> Util.ingresar(:texto)

      carro=tipo_Carro= "ingresar tipo de carro (electrico o convencional)"
      |> Util.ingresar(:texto)

      fecha_Ingreso= "ingresar fecha de ingreso (Sabado, Domingo o entre semana)"
      |> Util.ingresar(:texto)

      tarifa=calcular_Tarifa(horas_Permanencia)
      descuento=calcular_Descuento(cliente, carro,fecha_Ingreso, tarifa)
      mensaje= generar_Mensaje(horas_Permanencia, cliente, carro, tarifa, descuento)
  end

  defp calcular_Tarifa(horas_Permanencia) do
    cond do
      horas_Permanencia <= 2 ->
        3000

      horas_Permanencia > 2 and horas_Permanencia <= 5 ->
        2500

      horas_Permanencia > 5 and horas_Permanencia <= 8 ->
        2000

      true ->
        1800
    end
  end

  defp calcular_Descuento(cliente,carro,fecha_Ingreso,tarifa) do
    cond do
      cliente == "frecuente" ->
        tarifa * 0.15

      carro == "electrico" ->
        tarifa * 0.2

      fecha_Ingreso == "Sabado" or fecha_Ingreso == "Domingo" ->
        tarifa * 0.1

      cliente == "frecuente" and carro == "electrico" ->
        tarifa * 0.25

      cliente == "frecuente" and fecha_Ingreso == "Sabado" or fecha_Ingreso == "Domingo" ->
        tarifa * 0.25

      carro== "electrico" and fecha_Ingreso == "Sabado" or fecha_Ingreso == "Domingo" ->
        tarifa * 0.3

      carro=="electrico" and cliente == "frecuente" and fecha_Ingreso == "Sabado" or fecha_Ingreso == "Domingo" ->
        tarifa * 0.45
      true ->
        0
    end
  end

  defp generar_Mensaje(horas_Permanencia, cliente, carro, tarifa, descuento) do
    tarifa_Final = tarifa - descuento

    IO.puts("
    Horas de permanencia: #{horas_Permanencia}
    Tipo de cliente: #{cliente}
    Tipo de carro: #{carro}
    Tarifa sin descuento: #{tarifa}
    Descuento aplicado: #{descuento}
    Tarifa final a pagar: #{tarifa_Final}
    ")
  end
end
Parqueadero.main()
