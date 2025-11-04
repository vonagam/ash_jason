# SPDX-FileCopyrightText: 2023 ash_jason contributors <https://github.com/vonagam/ash_jason/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshJason.Resource do
  @moduledoc """
  `Ash.Resource` extension for implementing `Jason.Encoder` protocol.
  """

  use Spark.Dsl.Extension,
    sections: [AshJason.ExtensionHelpers.jason_section(Ash.Resource)],
    transformers: [AshJason.Resource.Transformer]
end
