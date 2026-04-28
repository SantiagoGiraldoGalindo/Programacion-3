defmodule Restaurante do

  def atender_pedido(plato) do
    IO.puts("Preparando #{plato} en el proceso #{inspect self()}")
  end

  def main do
    spawn(fn -> atender_pedido("Hamburguesa") end)
    spawn(fn -> atender_pedido("Pizza") end)
    spawn(fn -> atender_pedido("Ensalada") end)

    :timer.sleep(1000) # ⬅️ Espera 1 segundo
  end

end

Restaurante.main()
