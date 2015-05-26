# ----------------------------------------------------------------------------
#  Color Picker
# ----------------------------------------------------------------------------

    module.exports =
        activate: ->
            atom.commands.add 'atom-text-editor',
                'color-picker:open': => @view?.open()
            atom.contextMenu.add 'atom-text-editor': [
                label: 'Color Picker'
                command: 'color-picker:open']
            return @view.activate()

        deactivate: -> @view?.destroy()

        config:
            # Random color configuration: On Color Picker open, show a random color
            randomColor:
                title: 'Serve a random color on open'
                description: 'If the Color Picker doesn\'t get an input color, it serves a completely random color.'
                type: 'boolean'
                default: true
            # TODO Automatic Replace configuration: Replace color value on change
            automaticReplace:
                title: 'Automatically Replace Color'
                description: 'Replace selected color automatically on change. Works well with as-you-type CSS reloaders.'
                type: 'boolean'
                default: false
            # Abbreviate values configuration: If possible, abbreviate color values. Eg. “0.3” to “.3”
            # TODO: Can we abbreviate something else?
            abbreviateValues:
                title: 'Abbreviate Color Values'
                description: 'If possible, abbreviate color values, like for example “0.3” to “.3” and “#ffffff” to “#fff”.'
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

        view: (require './ColorPicker-view')()
