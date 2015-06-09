# A Color Picker for Atom

Right click and select `Color Picker`, or hit `CMD-SHIFT-C`/`CTRL-ALT-C` to open it. Currently reads `HEX`, `HEXa`, `RGB`, `RGBa`, `HSL`, `HSLa`, `HSV`, `HSVa`, `VEC3` and `VEC4` colors – and is able to convert between the formats.

It also inspects `Sass` and `LESS` color variables. Just open the `Color Picker` with the cursor at a variable and it'll look up the definition for you. From there, you can click the definition and go directly to where it's defined.

## Preview

![Color Picker in action](https://github.com/thomaslindstrom/color-picker/raw/master/preview.gif)

## Settings

Open `Atom Settings`, go to `Packages` in the left hand sidebar, and press `Settings` on `color-picker` to open the list of settings available for the Color Picker.

- **Abbreviate Color Values:** If possible, abbreviate color values, like for example “0.3” to “.3”,  “#ffffff” to “#fff” and “rgb(0, 0, 0)” to “rgb(0,0,0)”.
- **Automatically Replace Color:** Replace selected color automatically on change. Works well with as-you-type CSS reloaders.
- **Preferred Color Format:** On open, the Color Picker will show a color in this format.
- **Serve a random color on open:** If the Color Picker doesn't get an input color, it serves a completely random color.
- **Trigger key:** Decide what trigger key should open the Color Picker. `CMD-SHIFT-{TRIGGER_KEY}` and `CTRL-ALT-{TRIGGER_KEY}`. Requires a restart.
- **Uppercase Color Values:** If sensible, uppercase the color value. For example, “#aaa” becomes “#AAA”.

## To do

- Selectable list of the current project color variables
