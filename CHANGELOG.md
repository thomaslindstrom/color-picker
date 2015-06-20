# Change log

https://github.com/thomaslindstrom/color-picker

## v2.0.0
- Completely rewritten source code
- Easily convert between color formats in the Color Picker UI
- Improved speed, performance and precision
- Improved design: Now properly handles awkward positions
- Add setting for preferred color format
- Add setting for deciding what trigger key should open the Color Picker
- Add setting for whether or not to serve a random color on open
- Add setting for, if possible, abbreviating color values
- Add setting for uppercasing color values
- Add setting for automatically updating the color value in editor on change

### v2.0.1
- Fix missing preview image

### v2.0.2
- Fix `keymap` deprecation
- Improve editor scroll binding

### v2.0.3
- `Return` element was being unnecessarily rendered
- Prevent sporadic `Format` element flicker
- Better output abbreviation
- Add Stylus variable support – *if they are preceded by `$`*
- Stop mistakingly assuming color variables in unrelated files
- *Behind the scenes* improvements

### v2.0.4
- Remove Atom Module Cache from `package.json`

### v2.0.5
- Set or replace color on key press `enter`

### v2.0.6
- Opacity values equaling `1.0` would in some cases not be read
- Fix issue where disabling the Shadow DOM would trigger a ton of bugs

### v2.0.7
- Fix issues with placement when using `Split View`

## v1.7.0
- Fix deprecations

## v1.6.0
- Fix deprecations

## v1.5.0
- Move stylesheets to `/styles` directory
- Replace deprecated `Atom View`, add dependency

## v1.4.4
- Fix a bug where clicking a color pointer that lead to the active file didn't scroll to the definition

## v1.4.3
- Remove `event-kit` dependency as it took a long time to activate
- Tidy up some bits of code

## v1.4.2
- Patch package. Uploading v.1.4.1 failed

## v1.4.1
- Close color picker on editor scroll
- Set up a `CHANGELOG.md`
