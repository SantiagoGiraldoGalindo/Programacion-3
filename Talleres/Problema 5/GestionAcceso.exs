defmodule GestionAcceso do
  def main do
    nombre =
      "Ingresar nombre"
      |> Util.ingresar(:texto)

    edad =
      "Ingresar edad"
      |> Util.ingresar(:entero)

    credenciales =
      "Ingresar credenciales (true/false)"
      |> Util.ingresar(:texto)

    intentos =
      "Ingresar intentos"
      |> Util.ingresar(:entero)

    verificar = verificar_acceso(edad, credenciales, intentos)

    generar_mensaje(nombre, edad, credenciales, verificar)
  end

  defp verificar_acceso(edad, credenciales, intentos) do
    if edad >= 18 and credenciales == "true" and intentos < 3 do
      {:ok, "Acceso permitido"}
    else
      {:error, "Acceso denegado"}
    end
  end

  defp generar_mensaje(nombre, edad, credenciales, verificar) do
    IO.puts("
    Usuario: #{nombre}
    Edad: #{edad}
    Credenciales: #{credenciales}
    Resultado: #{inspect(verificar)}
    ")
  end
end

GestionAcceso.main()
