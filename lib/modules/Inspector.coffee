# ----------------------------------------------------------------------------
#  Inspector
# ----------------------------------------------------------------------------

    module.exports = ->
        path = require 'path'

        # Store all definitions so they are easily returned later
        _definitions = {}

    # -------------------------------------
    #  Variable patterns
    # -------------------------------------
        _variablePattern = '\\{{ VARIABLE }}[\\s]*\\:[\\s]*(.+)[\\;|\\n]?'

    # -------------------------------------
    #  File path patterns
    # -------------------------------------
        _globPatterns =
            'variable:sass': ['**/*.scss', '**/*.sass']
            'variable:less': ['**/*.less']

    # -------------------------------------
    #  Find a variable definition in the project
    #  - name {String}
    #  - type {String}
    #
    #  @return Promise
    # -------------------------------------
        return findDefinition = (name, type) ->
            return unless name and type

            _regex = RegExp _variablePattern.replace '{{ VARIABLE }}', name
            _results = []

            # We already know where the definition is
            if _definition = _definitions[name]
                _pointer = _definition.pointer

                # ... but check if it's still there
                return (atom.project.bufferForPath _pointer.filePath).then (buffer) =>
                    _text = buffer.getTextInRange _pointer.range
                    _match = _text.match _regex

                    unless _match
                        _definitions[name] = null
                        return findDefinition name, type

                    _definition.definition = _match[1]
                    return _definition

            _options = unless _globPatterns[type] then null else {
                paths: _globPatterns[type]
            }

            # We don't know where the definition is, look it up
            return atom.workspace.scan _regex, _options, (result) ->
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

                _definitions[name] =
                    name: name
                    type: type

                    pointer:
                        filePath: _bestMatch.filePath
                        range: _match.range
                return findDefinition name, type
