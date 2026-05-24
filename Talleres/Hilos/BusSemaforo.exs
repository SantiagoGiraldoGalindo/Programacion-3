defmodule Bus do
  def start(asientos) do
    spawn(fn -> loop(asientos) end)
  end

  defp loop(asientos_disponibles) do
    receive do
      {:subir, persona} ->
        if asientos_disponibles > 0 do
          IO.puts("#{persona} subió al bus 🚌")
          loop(asientos_disponibles - 1)
        else
          IO.puts("#{persona} no pudo subir ❌ (bus lleno)")
          loop(asientos_disponibles)
        end

      {:bajar, persona} ->
        IO.puts("#{persona} se bajó del bus ⬇️")
        loop(asientos_disponibles + 1)
    end
  end
end

defmodule Main do
  def run do
    bus = Bus.start(2) # solo 2 asientos

    spawn(fn -> send(bus, {:subir, "Persona 1"}) end)
    spawn(fn -> send(bus, {:subir, "Persona 2"}) end)
    spawn(fn -> send(bus, {:subir, "Persona 3"}) end)

    :timer.sleep(1000)

    send(bus, {:bajar, "Persona 1"})

    :timer.sleep(1000)

    spawn(fn -> send(bus, {:subir, "Persona 4"}) end)
  end
end

Main.run()
