defmodule Usuario do

  def main do
    usuario =
      "Ingresar usuario"
      |> Util.ingresar(:texto)

    errores = []
    |> validar_longitud(usuario)
    |> validar_minusculas(usuario)
    |> validar_espacios(usuario)
    |> validar_caracteres_especiales(usuario)
    |> validar_letras(usuario)

    mensaje = generar_mensaje(errores)
    IO.inspect(mensaje)

  end

  defp validar_longitud(errores, usuario) do
    if String.length(usuario) >= 5 and String.length(usuario) <= 12 do
      errores
    else
      ["Debe tener entre 5 y 12 caracteres" | errores]
    end
  end

  defp validar_minusculas(errores, usuario) do
    if usuario == String.downcase(usuario) do
      errores
    else
      ["Debe estar completamente en minúscula" | errores]
    end
  end

  defp validar_espacios(errores, usuario) do
    if String.contains?(usuario, " ") do
      ["No debe contener espacios" | errores]
    else
      errores
    end
  end

  defp validar_caracteres_especiales(errores, usuario) do
    if Regex.match?(~r/[@#$%]/, usuario) do
      ["No debe contener caracteres especiales (@,#,$,%)" | errores]
    else
      errores
    end
  end

  defp validar_letras(errores, usuario) do
    if Regex.match?(~r/[a-z]/, usuario) do
      errores
    else
      ["Debe contener al menos una letra" | errores]
    end
  end


  defp generar_mensaje([]) do
    {:ok, "Usuario válido"}
  end


  defp generar_mensaje(errores) do
    {:error, Enum.reverse(errores)}
  end
end


Usuario.main()
