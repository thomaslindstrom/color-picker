# ----------------------------------------------------------------------------
#  Emitter
#  a really lightweight take on an Emitter
# ----------------------------------------------------------------------------

    module.exports = ->
        bindings: {}

        emit: (event, args...) ->
            return unless _bindings = @bindings[event]
            _callback.apply null, args for _callback in _bindings
            return

        on: (event, callback) ->
            @bindings[event] = [] unless @bindings[event]
            @bindings[event].push callback
            return callback

        off: (event, callback) ->
            return unless _bindings = @bindings[event]

            _i = _bindings.length; while _i-- and _binding = _bindings[_i]
                if _binding is callback then _bindings.splice _i, 1
            return
