defmodule Estructuras do
def main do


"\nIngrese los datos del cliente: "
|> Cliente.ingresar(:clientes)
|> Cliente.escribir_csv("clientes.csv")
end


end
Estructuras.main()
