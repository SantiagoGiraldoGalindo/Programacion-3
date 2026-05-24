# =============================================================
# ENUNCIADO 1 - Actor Carrito de Compras con Procesos Elixir
# =============================================================
# Modelo de Actores: estado privado, mensajes, aislamiento total

defmodule Item do
  # Struct que representa un producto dentro del carrito
  defstruct id: nil, nombre: "", cantidad: 0, precio_unitario: 0.0
end

defmodule Carrito do
  @archivo "carrito.csv"

  # -----------------------------------------------------------
  # PUNTO DE ENTRADA: inicia el proceso actor
  # Lee el CSV previo para restaurar estado persistido
  # -----------------------------------------------------------
  def iniciar do
    items_iniciales = cargar_csv()
    spawn(fn -> loop(items_iniciales) end)
  end

  # -----------------------------------------------------------
  # LOOP PRINCIPAL: el corazón del actor
  # Espera mensajes, los procesa UNO A LA VEZ (secuencial)
  # El estado `items` NUNCA se expone al exterior
  # -----------------------------------------------------------
  defp loop(items) do
    receive do
      # ── Agregar item ──────────────────────────────────────
      # Si el id ya existe → suma la cantidad
      # Si no existe       → lo agrega a la lista
      {:agregar_item, %Item{} = item} ->
        nuevo_estado =
          case Enum.find_index(items, fn i -> i.id == item.id end) do
            nil ->
              items ++ [item]

            idx ->
              List.update_at(items, idx, fn existente ->
                %Item{existente | cantidad: existente.cantidad + item.cantidad}
              end)
          end

        loop(nuevo_estado)

      # ── Quitar item por id ────────────────────────────────
      {:quitar_item, id} ->
        nuevo_estado = Enum.reject(items, fn i -> i.id == id end)
        loop(nuevo_estado)

      # ── Calcular total y enviarlo al pid solicitante ──────
      {:total, pid} ->
        total =
          Enum.reduce(items, 0.0, fn i, acc ->
            acc + i.cantidad * i.precio_unitario
          end)

        send(pid, {:total_resultado, total})
        loop(items)

      # ── Listar todos los items y enviarlos al pid ─────────
      {:listar, pid} ->
        send(pid, {:lista_resultado, items})
        loop(items)

      # ── Guardar en CSV ────────────────────────────────────
      :guardar_carrito ->
        guardar_csv(items)
        loop(items)

      # ── Vaciar el carrito ─────────────────────────────────
      :vaciar ->
        loop([])

      # ── Detener el actor ──────────────────────────────────
      # No llama a loop/1, por lo que el proceso termina
      :detener ->
        :ok
    end
  end

  # -----------------------------------------------------------
  # PERSISTENCIA: Guardar items en archivo CSV
  # Formato: id,nombre,cantidad,precio
  # -----------------------------------------------------------
  defp guardar_csv(items) do
    encabezado = "id,nombre,cantidad,precio\n"

    filas =
      Enum.map_join(items, "\n", fn i ->
        "#{i.id},#{i.nombre},#{i.cantidad},#{i.precio_unitario}"
      end)

    File.write!(@archivo, encabezado <> filas)
    IO.puts("💾 Carrito guardado en #{@archivo}")
  end

  # -----------------------------------------------------------
  # PERSISTENCIA: Leer items desde CSV al iniciar
  # Devuelve lista de %Item{} o [] si no existe el archivo
  # -----------------------------------------------------------
  defp cargar_csv do
    case File.read(@archivo) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> Enum.drop(1)  # saltar encabezado
        |> Enum.map(fn linea ->
          [id, nombre, cantidad, precio] = String.split(linea, ",")

          %Item{
            id: String.to_integer(id),
            nombre: nombre,
            cantidad: String.to_integer(cantidad),
            precio_unitario: String.to_float(precio)
          }
        end)

      {:error, _} ->
        []  # archivo no existe aún
    end
  end
end

# =============================================================
# DEMO DE USO
# =============================================================
defmodule CarritoDemo do
  def run do
    IO.puts("\n=== Demo Carrito de Compras ===\n")

    # 1. Iniciar el actor (devuelve el PID del proceso)
    pid = Carrito.iniciar()
    IO.puts("Actor iniciado con PID: #{inspect(pid)}")

    # 2. Agregar productos
    send(pid, {:agregar_item, %Item{id: 1, nombre: "Manzana",  cantidad: 3,  precio_unitario: 1.5}})
    send(pid, {:agregar_item, %Item{id: 2, nombre: "Pan",      cantidad: 2,  precio_unitario: 2.0}})
    send(pid, {:agregar_item, %Item{id: 3, nombre: "Leche",    cantidad: 1,  precio_unitario: 3.5}})

    # 3. Agregar mismo id → debe SUMAR cantidad (3 + 2 = 5 manzanas)
    send(pid, {:agregar_item, %Item{id: 1, nombre: "Manzana",  cantidad: 2,  precio_unitario: 1.5}})

    # 4. Listar items actuales
    send(pid, {:listar, self()})
    receive do
      {:lista_resultado, items} ->
        IO.puts("\n📋 Items en el carrito:")
        Enum.each(items, fn i ->
          IO.puts("  [#{i.id}] #{i.nombre} x#{i.cantidad} @ $#{i.precio_unitario}")
        end)
    after 1000 -> IO.puts("Timeout esperando lista")
    end

    # 5. Calcular total
    send(pid, {:total, self()})
    receive do
      {:total_resultado, total} ->
        IO.puts("\n💰 Total del carrito: $#{:erlang.float_to_binary(total, decimals: 2)}")
    after 1000 -> IO.puts("Timeout esperando total")
    end

    # 6. Quitar un item
    send(pid, {:quitar_item, 2})
    IO.puts("\n🗑️  Item 2 (Pan) eliminado")

    # 7. Guardar en CSV
    send(pid, :guardar_carrito)
    Process.sleep(100)

    # 8. Vaciar
    send(pid, :vaciar)

    # 9. Listar carrito vacío
    send(pid, {:listar, self()})
    receive do
      {:lista_resultado, items} ->
        IO.puts("🛒 Items tras vaciar: #{length(items)}")
    after 1000 -> :ok
    end

    # 10. Detener el actor
    send(pid, :detener)
    IO.puts("\n✅ Actor detenido")
  end
end



# =============================================================
# ENUNCIADO 3 - Análisis Concurrente de Sensores de Temperatura
# =============================================================
# Versión secuencial vs concurrente con Task.async / Task.await

# -----------------------------------------------------------
# STRUCT: representa una lectura de sensor
# -----------------------------------------------------------
defmodule Sensor do
  defstruct id: nil, zona: "", temperaturas: []
end

# -----------------------------------------------------------
# MÓDULO DE PROCESAMIENTO
# -----------------------------------------------------------
defmodule AnalizadorSensores do

  # ── Función lógica principal ──────────────────────────────
  # Recibe un %Sensor{} y devuelve {:ok, promedio}
  def procesar_sensor(%Sensor{temperaturas: temps}) when length(temps) > 0 do
    promedio = Enum.sum(temps) / length(temps)
    {:ok, Float.round(promedio, 2)}
  end

  def procesar_sensor(%Sensor{}) do
    {:error, "Sin lecturas disponibles"}
  end

  # ── Versión SECUENCIAL ────────────────────────────────────
  # Procesa cada sensor uno tras otro (bloqueante)
  def procesar_secuencial(sensores) do
    inicio = :os.system_time(:millisecond)

    resultados =
      Enum.map(sensores, fn sensor ->
        # Simular trabajo pesado (consulta DB, cálculo complejo...)
        Process.sleep(200)
        {:ok, promedio} = procesar_sensor(sensor)
        {sensor.id, sensor.zona, promedio}
      end)

    tiempo = :os.system_time(:millisecond) - inicio
    {resultados, tiempo}
  end

  # ── Versión CONCURRENTE ───────────────────────────────────
  # Lanza un Task por cada sensor → todos corren en PARALELO
  # Task.async  → crea proceso independiente
  # Task.await  → espera el resultado (timeout 5 seg)
  def procesar_concurrente(sensores) do
    inicio = :os.system_time(:millisecond)

    resultados =
      sensores
      |> Enum.map(fn sensor ->
           # Cada Task es un proceso separado del scheduler de Elixir
           Task.async(fn ->
             Process.sleep(200)  # mismo trabajo simulado
             {:ok, promedio} = procesar_sensor(sensor)
             {sensor.id, sensor.zona, promedio}
           end)
         end)
      |> Enum.map(&Task.await(&1, 5000))  # recoger todos los resultados

    tiempo = :os.system_time(:millisecond) - inicio
    {resultados, tiempo}
  end
end

# =============================================================
# DEMO
# =============================================================
defmodule SensoresDemo do
  def run do
    IO.puts("\n=== Análisis de Sensores DataSensor S.A. ===\n")

    # Datos de prueba: 6 sensores con lecturas de temperatura
    sensores = [
      %Sensor{id: "S01", zona: "Horno Principal",   temperaturas: [210, 215, 208, 220, 212]},
      %Sensor{id: "S02", zona: "Refrigeración",     temperaturas: [4, 5, 3, 6, 4, 5]},
      %Sensor{id: "S03", zona: "Sala de Control",   temperaturas: [22, 23, 21, 24, 22]},
      %Sensor{id: "S04", zona: "Almacén Externo",   temperaturas: [30, 35, 28, 33, 31, 29]},
      %Sensor{id: "S05", zona: "Cámara Fría",       temperaturas: [-5, -4, -6, -3, -5]},
      %Sensor{id: "S06", zona: "Zona de Carga",     temperaturas: [25, 27, 26, 28, 25, 24]}
    ]

    # ── Procesar UNA sola lectura con procesar_sensor/1 ──────
    IO.puts("── Test de procesar_sensor/1 ──")
    sensor_prueba = %Sensor{id: "TEST", zona: "Prueba", temperaturas: [100, 110, 90, 105]}
    IO.puts("Sensor de prueba: #{inspect(sensor_prueba.temperaturas)}")
    IO.puts("Resultado: #{inspect(AnalizadorSensores.procesar_sensor(sensor_prueba))}")

    IO.puts("\n── Procesamiento SECUENCIAL (#{length(sensores)} sensores) ──")
    {res_seq, t_seq} = AnalizadorSensores.procesar_secuencial(sensores)
    Enum.each(res_seq, fn {id, zona, prom} ->
      IO.puts("  [#{id}] #{zona}: #{prom}°C")
    end)
    IO.puts("⏱  Tiempo secuencial: #{t_seq} ms")

    IO.puts("\n── Procesamiento CONCURRENTE (#{length(sensores)} sensores) ──")
    {res_con, t_con} = AnalizadorSensores.procesar_concurrente(sensores)
    Enum.each(res_con, fn {id, zona, prom} ->
      IO.puts("  [#{id}] #{zona}: #{prom}°C")
    end)
    IO.puts("⏱  Tiempo concurrente: #{t_con} ms")

    ahorro = t_seq - t_con
    IO.puts("\n✅ Mejora: #{ahorro} ms menos con concurrencia")
    IO.puts("   (aprox. #{Float.round(t_seq / max(t_con, 1) * 1.0, 1)}x más rápido)\n")
  end
end


# =============================================================
# EJEMPLO COMPLETO: spawn + loop + struct en UN SOLO MÓDULO
# Caso: Sistema de pedidos de una pizzería
# =============================================================

defmodule Pizzeria do

  # -----------------------------------------------------------
  # STRUCT
  # -----------------------------------------------------------
  defstruct id: nil, cliente: "", pizza: "", cantidad: 0, precio: 0.0

  # -----------------------------------------------------------
  # ACTOR: iniciar y loop
  # -----------------------------------------------------------
  def iniciar do
    spawn(fn -> loop([]) end)
  end

  defp loop(pedidos) do
    receive do

      {:agregar, pedido} ->
        nuevo_estado = pedidos ++ [pedido]
        IO.puts("  [nuevo] Pedido #{pedido.id} agregado")
        loop(nuevo_estado)

      {:eliminar, id} ->
        nuevo_estado = Enum.reject(pedidos, fn p -> p.id == id end)
        IO.puts("  [eliminar] Pedido #{id} eliminado")
        loop(nuevo_estado)

      {:listar, pid} ->
        send(pid, {:respuesta_lista, pedidos})
        loop(pedidos)

      {:total, pid} ->
        total = Enum.reduce(pedidos, 0.0, fn p, acc ->
          acc + p.precio * p.cantidad
        end)
        send(pid, {:respuesta_total, total})
        loop(pedidos)

      :vaciar ->
        IO.puts("  [vaciar] Lista vaciada")
        loop([])

      :detener ->
        IO.puts("  [detener] Detenido")
        :ok
    end
  end

  # -----------------------------------------------------------
  # MAIN
  # -----------------------------------------------------------
  def main do
    IO.puts("\n=== Pizzería Elixir ===\n")

    pid = Pizzeria.iniciar()
    IO.puts("Actor iniciado: #{inspect(pid)}\n")

    # Agregar pedidos usando el struct del mismo módulo
    send(pid, {:agregar, %Pizzeria{id: 1, cliente: "Ana",    pizza: "Margarita", cantidad: 2, precio: 12.0}})
    send(pid, {:agregar, %Pizzeria{id: 2, cliente: "Luis",   pizza: "Pepperoni", cantidad: 1, precio: 15.0}})
    send(pid, {:agregar, %Pizzeria{id: 3, cliente: "Carlos", pizza: "Hawaiana",  cantidad: 3, precio: 13.5}})

    Process.sleep(100)

    # Listar
    send(pid, {:listar, self()})
    receive do
      {:respuesta_lista, lista} ->
        IO.puts("📋 Pedidos actuales:")
        Enum.each(lista, fn p ->
          IO.puts("  [#{p.id}] #{p.cliente} → #{p.pizza} x#{p.cantidad} @ $#{p.precio}")
        end)
    after 1000 -> IO.puts("timeout")
    end

    # Total
    send(pid, {:total, self()})
    receive do
      {:respuesta_total, total} ->
        IO.puts("\n💰 Total: $#{:erlang.float_to_binary(total * 1.0, decimals: 2)}")
    after 1000 -> IO.puts("timeout")
    end

    # Eliminar
    send(pid, {:eliminar, 2})
    Process.sleep(100)

    # Listar tras eliminar
    send(pid, {:listar, self()})
    receive do
      {:respuesta_lista, lista} ->
        IO.puts("\n📋 Pedidos tras eliminar #2:")
        Enum.each(lista, fn p ->
          IO.puts("  [#{p.id}] #{p.cliente} → #{p.pizza}")
        end)
    after 1000 -> IO.puts("timeout")
    end

    # Detener
    send(pid, :detener)
    IO.puts("\n✅ Fin\n")
  end
end

# =============================================================
# PUNTO DE ENTRADA
# =============================================================
Pizzeria.main()
