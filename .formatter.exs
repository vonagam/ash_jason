spark_locals_without_parens = [
  fields: 1,
  pick: 1,
  omit: 1,
  merge: 1,
  customize: 1,
]

[
  import_deps: [:ash],
  plugins: [Spark.Formatter, FreedomFormatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120,
  trailing_comma: true,
  local_pipe_with_parens: true,
  single_clause_on_do: true,
  locals_without_parens: spark_locals_without_parens,
  export: [locals_without_parens: spark_locals_without_parens],
]
