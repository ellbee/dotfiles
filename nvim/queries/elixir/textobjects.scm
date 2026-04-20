; extends

; Catch-all for def/defp/defmacro/defmacrop with any argument structure and a do block.
; This handles cases like `defp foo() do...end` (empty args) which the plugin's patterns miss.
(call
  target: ((identifier) @_identifier
    (#any-of? @_identifier "def" "defp" "defmacro" "defmacrop"))
  (do_block
    "do"
    _+ @function.inner
    "end")) @function.outer

(call
  target: ((identifier) @_identifier
    (#any-of? @_identifier "def" "defp" "defmacro" "defmacrop"))
  (do_block
    "do"
    .
    ((_) @function.inner) @function.inner
    .
    "end")) @function.outer
