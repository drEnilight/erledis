defmodule ErledisSpec do
  use ESpec

  describe "set" do
    let server: Erledis.generate_gen_server

    before do: server().start_link

    context "correct key" do
      it "with single element" do
        server().set("set_1", {1,2,3})
        expect(server().exists?("set_1")) |> to(be_true())
        expect(server().get("set_1")) |> to(eq [{1,2,3}])
      end

      it "with multiple elements" do
        server().set("set_2", "word")
        expect(server().exists?("set_2")) |> to(be_true())
        expect(server().get("set_2")) |> to(eq ["word"])
        server().set("set_2", [1,2,3])
        expect(server().get("set_2")) |> to(eq ["word", [1,2,3]])
      end
    end

    context "element with incorrect key" do
      it do: expect(server().set(1, 2)) |> to(eq "key argument must be a string")
      it do: expect(server().set([1], 2)) |> to(eq "key argument must be a string")
    end
  end

  describe "get" do
    let server: Erledis.generate_gen_server

    before do: server().start_link

    context "value by key" do
      before do
        server().set("get_1", "word")
        server().set("get_1", {1,2,3})
        server().set("get_2", [1,2,3])
      end

      it do
        expect(server().get("get_1")) |> to(eq ["word", {1,2,3}])
        expect(server().get("get_2")) |> to(eq [[1,2,3]])
      end
    end

    context "element with incorrect key" do
      it do: expect(server().get(1)) |> to(eq "key argument must be a string")
      it do: expect(server().get([1])) |> to(eq "key argument must be a string")
    end

    context "undefined element" do
      it do: expect(server().get("atom")) |> to(eq [])
      it do: expect(server().get("string")) |> to(eq [])
    end
  end

  describe "push" do
    let server: Erledis.generate_gen_server

    before do: server().start_link

    context "with correct key" do
      context "where key is defined" do
        before do
          server().set("push", "word")
        end

        it do
          expect(server().push("push", 10)) |> to(eq [10, "word"])
          expect(server().push("push", {1,2,3})) |> to(eq [{1,2,3}, 10, "word"])
        end
      end

      context "where key is undefined" do
        it do: expect(server().push("atom", :atom)) |> to(eq [:atom])
        it do: expect(server().push("tuple", {1,2,3})) |> to(eq [{1,2,3}])
      end
    end

    context "with incorrect key" do
      it do: expect(server().push(1, 2)) |> to(eq "key argument must be a string")
      it do: expect(server().push([1], 2)) |> to(eq "key argument must be a string")
    end
  end

  describe "pop" do
    let server: Erledis.generate_gen_server

    before do: server().start_link

    context "with correct key" do
      context "where key is defined" do
        before do
          server().set("pop", "word")
          server().set("pop", [1,2,3])
          server().set("pop", {1,2,3})
        end

        it do
          expect(server().pop("pop")) |> to(eq {1,2,3})
          expect(server().get("pop")) |> to(eq ["word", [1,2,3]])
          expect(server().pop("pop")) |> to(eq [1,2,3])
          expect(server().get("pop")) |> to(eq ["word"])
        end
      end

      context "where key is undefined" do
        it do: expect(server().pop("atom")) |> to(eq nil)
        it do: expect(server().pop("tuple")) |> to(eq nil)
      end
    end

    context "with incorrect key" do
      it do: expect(server().pop(1)) |> to(eq "key argument must be a string")
      it do: expect(server().pop([1])) |> to(eq "key argument must be a string")
    end
  end

  describe "delete" do
    let server: Erledis.generate_gen_server

    before do: server().start_link

    context "element with correct key" do
      before do
        server().set("hello", "word")
        server().set("list", [1,2,3])
      end

      it do
        server().del("hello")
        expect(server().exists?("hello")) |> to(be_false())
        expect(server().get("hello")) |> to(eq [])
      end

      it do
        server().del("list")
        expect(server().exists?("list")) |> to(be_false())
        expect(server().get("list")) |> to(eq [])
      end
    end

    context "element with incorrect key" do
      it do: expect(server().del(1)) |> to(eq "key argument must be a string")
      it do: expect(server().del([1])) |> to(eq "key argument must be a string")
    end

    context "undefined element" do
      it do: expect(server().del("atom")) |> to(be_false())
      it do: expect(server().del("string")) |> to(be_false())
    end
  end

  describe "exists?" do
    let server: Erledis.generate_gen_server

    before do: server().start_link

    context "element with correct key" do
      before do
        server().set("hello", "word")
        server().set("list", [1,2,3])
      end

      it do: expect(server().exists?("hello")) |> to(be_true())
      it do: expect(server().exists?("list")) |> to(be_true())
    end

    context "element with incorrect key" do
      it do: expect(server().exists?(1)) |> to(eq "key argument must be a string")
      it do: expect(server().exists?([1])) |> to(eq "key argument must be a string")
    end

    context "undefined element" do
      it do: expect(server().exists?("atom")) |> to(be_false())
      it do: expect(server().exists?("string")) |> to(be_false())
    end
  end

  describe "flushall" do
    let server: Erledis.generate_gen_server

    before do
      server().start_link()
      server().set("hello", "word")
      server().set("list", [1,2,3])
    end

    context "should delete all elements" do
      it do
        server().flushall()
        expect(server().exists?("hello")) |> to(be_false())
        expect(server().exists?("list")) |> to(be_false())
      end
    end
  end
end
