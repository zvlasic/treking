%{
  configs: [
    %{
      files: %{
        excluded: [~r"/_build/", ~r"/deps/", ~r"/lib/treking_web/components/", ~r"/test/support/"]
      },
      name: "default",
      requires: [],
      strict: true,
      color: true,
      checks: [
        {Credo.Check.Readability.AliasAs, []},
        {Credo.Check.Readability.SinglePipe, []},
        {Credo.Check.Readability.ModuleDoc, false}
      ]
    }
  ]
}
