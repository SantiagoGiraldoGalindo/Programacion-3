defmodule Hora do
  def main do
    nombre =
      "Ingresar nombre"
      |> Util.ingresar(:texto)

    hora_actual = obtener_hora_actual()

    generar_mensaje(nombre, hora_actual)
  end

  defp obtener_hora_actual do
    {{_anio, _mes, _dia}, {hora, _min, _seg}} =
      :calendar.local_time()

    cond do
      hora >= 0 and hora < 12 ->
        "Buenos días"

      hora >= 12 and hora < 18 ->
        "Buenas tardes"

      true ->
        "Buenas noches"
    end
  end


  defp generar_mensaje(nombre, saludo) do
    IO.puts("#{saludo} #{nombre}")
  end
end

Hora.main()
