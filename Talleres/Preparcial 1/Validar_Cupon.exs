defmodule Validar_Cupon do
  def main do
    cupon="ingrese el cupon de descuento"
    |> Util.ingresar(:texto)

    errores=[]
    |> validar_longitud(cupon)
    |> validar_Mayuscula(cupon)
    |> validar_Numero(cupon)
    |> validar_Espacios(cupon)

    mensaje=generar_Mensaje(errores)
    IO.inspect(mensaje)
  end

  defp validar_longitud(errores, cupon) do
    if String.length(cupon) >= 10 do
      errores
    else
      ["El cupón debe tener al menos 10 caracteres" | errores]
    end

  end

  defp validar_Mayuscula(errores, cupon) do
    if cupon != String.downcase(cupon) do
      errores
    else
      ["El cupón debe contener al menos una letra mayúscula" | errores]
    end

  end

  defp validar_Numero(errores, cupon) do
    if cupon!= String.replace(cupon, ~r/[^0-9]/, "") do
      errores
    else
      ["El cupón debe contener al menos un número" | errores]
    end
  end

  defp validar_Espacios(errores, cupon) do
    if String.contains?(cupon, " ") do
      ["El cupón no debe contener espacios" | errores]
    else
      errores
    end
  end

  defp generar_Mensaje(errores) do
    if errores == [] do
      {:ok ,"El cupón es válido"}
    else
      {:error, "El cupón no es válido por las siguientes razones: #{errores}"}
    end
  end

end
Validar_Cupon.main()
