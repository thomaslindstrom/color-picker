/** @babel */
// ---------------------------------------------------------------------------
//  color-picker.js
// ---------------------------------------------------------------------------

    // -------------------------------------
    //  Configuration
    // -------------------------------------
        const config = {
            // Random color on open
            randomColor: {
                title: 'Serve a random color on open',
                description: 'If the Color Picker doesn\'t get an input color, it serves a completely random color.',
                type: 'boolean',
                default: true
            },

            // Automatically update color value when it changes
            automaticReplace: {
                title: 'Automatically Replace Color',
                description: 'Replace selected color automatically on change. Works well with as-you-type CSS reloaders.',
                type: 'boolean',
                default: false
            },

            // Abbreviate colors if possible: “0.3” becomes “.3”
            // TODO More abbreviation?
            abbreviateValues: {
                title: 'Abbreviate Color Values',
                description: 'If possible, abbreviate color values, like for example “0.3” to “.3”, “#ffffff” to “#fff” and “rgb(0, 0, 0)” to “rgb(0,0,0)”.',
                type: 'boolean',
                default: false
            },


            // Uppercase color values
            // TODO: Does it make sense to uppercase anything other than HEX colors?
            uppercaseColorValues: {
                title: 'Uppercase Color Values',
                description: 'Uppercase the color value: “#aaa” becomes “#AAA”.',
                type: 'boolean',
                default: false
            },

            // Preferred initial color format
            preferredFormat: {
                title: 'Preferred Color Format',
                description: 'On open, the Color Picker will show a color in this format.',
                type: 'string',
                enum: ['RGB', 'HEX', 'HSL', 'HSV', 'VEC'],
                default: 'RGB'
            },

            // Select the key that opens the Color Picker
            triggerKey: {
                title: 'Trigger key',
                description: 'Decide what trigger key should open the Color Picker. `CMD-SHIFT-{TRIGGER_KEY}` and `CTRL-ALT-{TRIGGER_KEY}`. Requires a restart.',
                type: 'string',
                enum: ['C', 'E', 'H', 'K'],
                default: 'C'
            }
        };

    // -------------------------------------
    //  Activation function
    // -------------------------------------
        function activate() {
            console.log('color-picker');
        }

    export default {
        activate
    };
