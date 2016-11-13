# ----------------------------------------------------------------------------
#  SmartVariable
# ----------------------------------------------------------------------------

    module.exports = ->
        path = require 'path'

    # -------------------------------------
    #  Variable Types
    # -------------------------------------
        VARIABLE_PATTERN = '\\{{ VARIABLE }}[\\s]*[:=][\\s]*([^\\;\\n]+)[\\;|\\n]'

        VARIABLE_TYPES = [
            # Matches Sass variable: eg.
            # $color-var
            {
                type: 'sass'
                extensions: ['.scss', '.sass']
                regExp: /([\$])([\w0-9-_]+)/i
            }

            # Matches LESS variable: eg.
            # @color-var
            {
                type: 'less'
                extensions: ['.less']
                regExp: /([\@])([\w0-9-_]+)/i
            }

            # Matches Stylus variable: eg.
            # $color-var
            {
                type: 'stylus'
                extensions: ['.stylus', '.styl']
                regExp: /([\$])([\w0-9-_]+)/i
            }
        ]

    # -------------------------------------
    #  Definition storage
    # -------------------------------------
        DEFINITIONS = {}

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        return {
        # -------------------------------------
        #  Find variables in string
        #  - string {String}
        #
        #  @return String
        # -------------------------------------
            find: (string, pathName) ->
                SmartVariable = this
                _variables = []

                for {type, extensions, regExp} in VARIABLE_TYPES
                    _matches = string.match (new RegExp regExp.source, 'ig')
                    continue unless _matches

                    # Make sure the file type matches possible extensions
                    if pathName
                        continue unless (path.extname pathName) in extensions

                    for _match in _matches then do (type, extensions, _match) ->
                        return if (_index = string.indexOf _match) is -1

                        _variables.push
                            match: _match
                            type: type
                            extensions: extensions
                            start: _index
                            end: _index + _match.length

                            getDefinition: -> SmartVariable.getDefinition this
                            isVariable: true

                        # Remove the match from the line content string to
                        # “mark it” as having been “spent”. Be careful to keep the
                        # correct amount of characters in the string as this is
                        # later used to see which match fits best, if any
                        string = string.replace _match, (new Array _match.length + 1).join ' '
                return _variables

        # -------------------------------------
        #  Find a variable definition in the project
        #  - name {String}
        #  - type {String}
        #
        #  @return Promise
        # -------------------------------------
            getDefinition: (variable, initial) ->
                {match, type, extensions} = variable

                # Figure out what to look for
                _regExp = new RegExp (VARIABLE_PATTERN.replace '{{ VARIABLE }}', match)

                # We already know where the definition is
                if _definition = DEFINITIONS[match]
                    # Save initial pointer value, if it isn't set already
                    initial ?= _definition
                    _pointer = _definition.pointer

                    # ... but check if it's still there
                    return atom.project.bufferForPath _pointer.filePath
                        .then (buffer) =>
                            _text = buffer.getTextInRange _pointer.range
                            _match = _text.match _regExp

                            # Definition not found, reset and try again
                            unless _match
                                DEFINITIONS[match] = null
                                return @getDefinition variable, initial

                            # Definition found, save it on the DEFINITION object
                            _definition.value = _match[1]

                            # ... but it might be another variable, in which
                            # case we must keep digging to find what we're after
                            _found = (@find _match[1], _pointer.filePath)[0]

                            # Run the search again, but keep the initial pointer
                            if _found and _found.isVariable
                                return @getDefinition _found, initial

                            return {
                                value: _definition.value
                                variable: _definition.variable
                                type: _definition.type

                                pointer: initial.pointer
                            }
                        .catch (error) => console.error error

                # ... we don't know where the definition is

                # Figure out where to look
                _options = paths: do ->
                    "**/*#{ _extension }" for _extension in extensions
                _results = []

                return atom.workspace.scan _regExp, _options, (result) ->
                    _results.push result
                .then =>
                    # Figure out what file is holding the definition
                    # Assume it's the one closest to the current path
                    _targetPath = atom.workspace.getActivePaneItem().getPath()
                    _targetFragments = _targetPath.split path.sep

                    _bestMatch = null
                    _bestMatchHits = 0

                    for result in _results
                        _thisMatchHits = 0
                        _pathFragments = result.filePath.split path.sep
                        _thisMatchHits++ for pathFragment, i in _pathFragments when pathFragment is _targetFragments[i]

                        if _thisMatchHits > _bestMatchHits
                            _bestMatch = result
                            _bestMatchHits = _thisMatchHits
                    return unless _bestMatch and _match = _bestMatch.matches[0]

                    # Save the definition on the DEFINITION object so that it
                    # can be accessed later
                    DEFINITIONS[match] = {
                        value: null
                        variable: match
                        type: type

                        pointer:
                            filePath: _bestMatch.filePath
                            range: _match.range
                    }

                    # Save initial pointer value, if it isn't set already
                    initial ?= DEFINITIONS[match]
                    return @getDefinition variable, initial
                .catch (error) => console.error error
        }
