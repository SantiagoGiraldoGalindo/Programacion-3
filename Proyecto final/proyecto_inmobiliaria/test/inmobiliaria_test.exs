defmodule InmobiliariaTest do
  use ExUnit.Case, async: false

  alias Inmobiliaria.{UserManager, PropertyManager, MessageManager}

  # Directorio temporal para tests
  @test_data_dir "test/data_tmp"

  setup do
    # Crear directorio temporal
    File.mkdir_p!(@test_data_dir)

    # Limpiar y configurar archivos de test
    Application.put_env(:inmobiliaria, :data_dir, @test_data_dir)

    on_exit(fn ->
      File.rm_rf!(@test_data_dir)
    end)

    :ok
  end

  # ── Tests de UserManager ──────────────────────────────────────────────────────

  describe "UserManager" do
    test "registra un nuevo usuario automáticamente" do
      {:ok, user, :registered} = UserManager.connect("testuser1", "pass123", "cliente")
      assert user.username == "testuser1"
      assert user.role == "cliente"
      assert user.score == 0
    end

    test "hace login de un usuario existente con contraseña correcta" do
      UserManager.connect("testuser2", "pass456", "vendedor")
      {:ok, user, :logged_in} = UserManager.connect("testuser2", "pass456")
      assert user.username == "testuser2"
      assert user.role == "vendedor"
    end

    test "rechaza contraseña incorrecta" do
      UserManager.connect("testuser3", "correctpass", "cliente")
      assert {:error, _} = UserManager.connect("testuser3", "wrongpass")
    end

    test "asigna rol por defecto 'cliente' si no se especifica" do
      {:ok, user, :registered} = UserManager.connect("testuser4", "pass", nil)
      assert user.role == "cliente"
    end

    test "suma puntos a un usuario" do
      UserManager.connect("testuser5", "pass", "cliente")
      {:ok, new_score} = UserManager.add_points("testuser5", 10)
      assert new_score == 10

      {:ok, new_score2} = UserManager.add_points("testuser5", 5)
      assert new_score2 == 15
    end

    test "genera ranking ordenado por puntaje descendente" do
      UserManager.connect("rank_a", "p", "cliente")
      UserManager.connect("rank_b", "p", "vendedor")
      UserManager.connect("rank_c", "p", "cliente")

      UserManager.add_points("rank_a", 30)
      UserManager.add_points("rank_b", 50)
      UserManager.add_points("rank_c", 10)

      ranking = UserManager.ranking()
      names = Enum.map(ranking, & &1.username)

      b_pos = Enum.find_index(names, &(&1 == "rank_b"))
      a_pos = Enum.find_index(names, &(&1 == "rank_a"))
      c_pos = Enum.find_index(names, &(&1 == "rank_c"))

      assert b_pos < a_pos
      assert a_pos < c_pos
    end

    test "ranking filtrado por rol" do
      UserManager.connect("cli_rank1", "p", "cliente")
      UserManager.connect("vend_rank1", "p", "vendedor")
      UserManager.add_points("vend_rank1", 100)

      clientes = UserManager.ranking("cliente")
      assert Enum.all?(clientes, &(&1.role == "cliente"))

      vendedores = UserManager.ranking("vendedor")
      assert Enum.all?(vendedores, &(&1.role == "vendedor"))
    end
  end

  # ── Tests de PropertyManager ──────────────────────────────────────────────────

  describe "PropertyManager" do
    test "publica una nueva propiedad con ID único" do
      {:ok, prop} =
        PropertyManager.publish(%{
          tipo: "casa",
          modalidad: "venta",
          ubicacion: "Armenia",
          precio: 300_000_000,
          habitaciones: 4,
          area: 180,
          owner: "carlos"
        })

      assert prop.id =~ ~r/^prop\d+/
      assert prop.tipo == "casa"
      assert prop.status == "disponible"
      assert prop.owner == "carlos"
    end

    test "lista todas las propiedades" do
      PropertyManager.publish(%{
        tipo: "apartamento",
        modalidad: "arriendo",
        ubicacion: "Bogota",
        precio: 2_000_000,
        habitaciones: 2,
        area: 60,
        owner: "juan"
      })

      props = PropertyManager.list(%{})
      assert length(props) >= 1
    end

    test "filtra propiedades por tipo" do
      PropertyManager.publish(%{
        tipo: "oficina",
        modalidad: "venta",
        ubicacion: "Medellin",
        precio: 500_000_000,
        habitaciones: 0,
        area: 120,
        owner: "empresa"
      })

      oficinas = PropertyManager.list(%{tipo: "oficina"})
      assert Enum.all?(oficinas, &(&1.tipo == "oficina"))
    end

    test "filtra propiedades por modalidad" do
      arriendos = PropertyManager.list(%{modalidad: "arriendo"})
      assert Enum.all?(arriendos, &(&1.modalidad == "arriendo"))
    end

    test "filtra por rango de precio" do
      PropertyManager.publish(%{
        tipo: "lote",
        modalidad: "venta",
        ubicacion: "Armenia",
        precio: 50_000_000,
        habitaciones: 0,
        area: 500,
        owner: "vendedor_test"
      })

      baratas = PropertyManager.list(%{precio_min: 0, precio_max: 100_000_000})
      assert Enum.all?(baratas, &(&1.precio <= 100_000_000))
    end

    test "devuelve propiedad por id" do
      {:ok, published} =
        PropertyManager.publish(%{
          tipo: "casa",
          modalidad: "venta",
          ubicacion: "Cali",
          precio: 200_000_000,
          habitaciones: 3,
          area: 100,
          owner: "propietario"
        })

      {:ok, found} = PropertyManager.get(published.id)
      assert found.id == published.id
    end

    test "retorna error para id inexistente" do
      assert {:error, _} = PropertyManager.get("prop_inexistente_xyz")
    end
  end

  # ── Tests de operaciones (concurrencia) ────────────────────────────────────────

  describe "Operaciones inmobiliarias" do
    test "compra exitosa de propiedad disponible" do
      {:ok, prop} =
        PropertyManager.publish(%{
          tipo: "casa",
          modalidad: "venta",
          ubicacion: "Armenia",
          precio: 250_000_000,
          habitaciones: 3,
          area: 120,
          owner: "carlos"
        })

      assert {:ok, updated} = PropertyManager.operate(prop.id, "ana", "compra")
      assert updated.status == "vendida"
      assert updated.client == "ana"
    end

    test "arriendo exitoso de propiedad en arriendo" do
      {:ok, prop} =
        PropertyManager.publish(%{
          tipo: "apartamento",
          modalidad: "arriendo",
          ubicacion: "Bogota",
          precio: 1_500_000,
          habitaciones: 2,
          area: 55,
          owner: "luis"
        })

      assert {:ok, updated} = PropertyManager.operate(prop.id, "maria", "arriendo")
      assert updated.status == "arrendada"
    end

    test "no permite comprar propiedad ya vendida" do
      {:ok, prop} =
        PropertyManager.publish(%{
          tipo: "casa",
          modalidad: "venta",
          ubicacion: "Pereira",
          precio: 180_000_000,
          habitaciones: 2,
          area: 80,
          owner: "vendedor1"
        })

      PropertyManager.operate(prop.id, "cliente1", "compra")
      assert {:error, _} = PropertyManager.operate(prop.id, "cliente2", "compra")
    end

    test "concurrencia: solo un cliente puede comprar cuando hay solicitudes simultáneas" do
      {:ok, prop} =
        PropertyManager.publish(%{
          tipo: "oficina",
          modalidad: "venta",
          ubicacion: "Medellin",
          precio: 800_000_000,
          habitaciones: 0,
          area: 200,
          owner: "empresa_x"
        })

      # Lanzar múltiples solicitudes concurrentes
      tasks =
        Enum.map(1..5, fn i ->
          Task.async(fn ->
            PropertyManager.operate(prop.id, "cliente#{i}", "compra")
          end)
        end)

      results = Enum.map(tasks, &Task.await/1)

      successes = Enum.count(results, fn r -> match?({:ok, _}, r) end)
      errors = Enum.count(results, fn r -> match?({:error, _}, r) end)

      # Solo UNA operación debe tener éxito
      assert successes == 1
      assert errors == 4
    end

    test "no permite comprar propiedad de arriendo" do
      {:ok, prop} =
        PropertyManager.publish(%{
          tipo: "apartamento",
          modalidad: "arriendo",
          ubicacion: "Cali",
          precio: 2_000_000,
          habitaciones: 3,
          area: 90,
          owner: "arrendador1"
        })

      assert {:error, reason} = PropertyManager.operate(prop.id, "cliente1", "compra")
      assert reason =~ "arriendo"
    end

    test "no permite arrendar propiedad en venta" do
      {:ok, prop} =
        PropertyManager.publish(%{
          tipo: "casa",
          modalidad: "venta",
          ubicacion: "Armenia",
          precio: 200_000_000,
          habitaciones: 3,
          area: 100,
          owner: "vendedor2"
        })

      assert {:error, reason} = PropertyManager.operate(prop.id, "cliente1", "arriendo")
      assert reason =~ "venta"
    end
  end

  # ── Tests de mensajería ───────────────────────────────────────────────────────

  describe "MessageManager" do
    test "envía y recupera mensajes de una propiedad" do
      :ok = MessageManager.send_message("prop001", "ana", "Hola, ¿sigue disponible?")
      :ok = MessageManager.send_message("prop001", "pedro", "¿Acepta negociación?")

      messages = MessageManager.get_messages("prop001")
      assert length(messages) >= 2

      senders = Enum.map(messages, & &1.from)
      assert "ana" in senders
      assert "pedro" in senders
    end

    test "los mensajes de diferentes propiedades están separados" do
      MessageManager.send_message("prop_a", "user1", "Mensaje para A")
      MessageManager.send_message("prop_b", "user2", "Mensaje para B")

      msgs_a = MessageManager.get_messages("prop_a")
      msgs_b = MessageManager.get_messages("prop_b")

      assert Enum.all?(msgs_a, &(&1.property_id == "prop_a"))
      assert Enum.all?(msgs_b, &(&1.property_id == "prop_b"))
    end
  end

  # ── Tests de Location ─────────────────────────────────────────────────────────

  describe "Location" do
    test "lista ubicaciones válidas" do
      locs = Inmobiliaria.Location.list()
      assert is_list(locs)
      assert length(locs) > 0
    end

    test "valida ubicación existente (case-insensitive)" do
      assert Inmobiliaria.Location.valid?("Armenia")
      assert Inmobiliaria.Location.valid?("armenia")
      assert Inmobiliaria.Location.valid?("ARMENIA")
    end

    test "rechaza ubicación inexistente" do
      refute Inmobiliaria.Location.valid?("CiudadInventada123")
    end
  end
end
