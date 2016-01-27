# ----------------------------------------------------------------------------
#  Color Picker
# ----------------------------------------------------------------------------

    module.exports =
        view: null

        activate: ->
            @view = (require './ColorPicker-view')()
            _command = 'color-picker:open'

        #  Set key bindings
        # ---------------------------
            _triggerKey = (atom.config.get 'color-picker.triggerKey').toLowerCase()
            _TriggerKey = _triggerKey.toUpperCase()

            # TODO this doesn't look too good
            _macSelector = '.platform-darwin atom-workspace'
            _windowsSelector = '.platform-win32 atom-workspace'
            _linuxSelector = '.platform-linux atom-workspace'

            _keymap = {}

            # Mac OS X
            _keymap["#{ _macSelector }"] = {}
            _keymap["#{ _macSelector }"]["cmd-#{ _TriggerKey }"] = _command
            # Windows
            _keymap["#{ _windowsSelector }"] = {}
            _keymap["#{ _windowsSelector }"]["ctrl-alt-#{ _triggerKey }"] = _command
            # Linux
            _keymap["#{ _linuxSelector }"] = {}
            _keymap["#{ _linuxSelector }"]["ctrl-alt-#{ _triggerKey }"] = _command

            # Add the keymap
            atom.keymaps.add 'color-picker:trigger', _keymap

        #  Add context menu command
        # ---------------------------
            atom.contextMenu.add 'atom-text-editor': [
                label: 'Color Picker'
                command: _command]

        #  Add color-picker:open command
        # ---------------------------
            _commands = {}; _commands["#{ _command }"] = =>
                return unless @view?.canOpen
                @view.open()
            atom.commands.add 'atom-text-editor', _commands

            return @view.activate()

        deactivate: -> @view?.destroy()

        provideColorPicker: ->
            return {
                open: (Editor, Cursor) =>
                    return unless @view?.canOpen
                    return @view.open Editor, Cursor
            }

        config:
            # Random color configuration: On Color Picker open, show a random color
            randomColor:
                title: 'Serve a random color on open'
                description: 'If the Color Picker doesn\'t get an input color, it serves a completely random color.'
                type: 'boolean'
                default: true
            # Automatic Replace configuration: Replace color value on change
            automaticReplace:
                title: 'Automatically Replace Color'
                description: 'Replace selected color automatically on change. Works well with as-you-type CSS reloaders.'
                type: 'boolean'
                default: false
            # Abbreviate values configuration: If possible, abbreviate color values. Eg. “0.3” to “.3”
            # TODO: Can we abbreviate something else?
            abbreviateValues:
                title: 'Abbreviate Color Values'
                description: 'If possible, abbreviate color values, like for example “0.3” to “.3”,  “#ffffff” to “#fff” and “rgb(0, 0, 0)” to “rgb(0,0,0)”.'
                type: 'boolean'
                default: false
            # Uppercase color value configuration: Uppercase for example HEX color values
            # TODO: Does it make sense to uppercase anything other than HEX colors?
            uppercaseColorValues:
                title: 'Uppercase Color Values'
                description: 'If sensible, uppercase the color value. For example, “#aaa” becomes “#AAA”.'
                type: 'boolean'
                default: false
            # Preferred color format configuration: Set what color format the color picker should display initially
            preferredFormat:
                title: 'Preferred Color Format'
                description: 'On open, the Color Picker will show a color in this format.'
                type: 'string'
                enum: ['RGB', 'HEX', 'HSL', 'HSV', 'VEC']
                default: 'RGB'
            # Trigger key: Set what trigger key opens the color picker
            # TODO more options?
            triggerKey:
                title: 'Trigger key'
                description: 'Decide what trigger key should open the Color Picker. `CMD-SHIFT-{TRIGGER_KEY}` and `CTRL-ALT-{TRIGGER_KEY}`. Requires a restart.'
                type: 'string'
                enum: ['C', 'E', 'H', 'K']
                default: 'C'
