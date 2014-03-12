# ----------------------------------------------------------------------------
#  Variable inspector
# ----------------------------------------------------------------------------

        _definition = {}

    # -------------------------------------
    #  Variable regex matchers
    # -------------------------------------
        _regexes = {
            'variable:sass': '\\$__VARIABLE__\\:[\\s?](.+)[\\;|\\n]'
            'variable:less': '\\@__VARIABLE__\\:[\\s?](.+)[\\;|\\n]'
        }

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        module.exports =
            # Find a variable definition in the project
            # @String name
            # @String type
            findDefinition: (name, type) ->
                return _definition[name] if _definition[name]

                return unless _regexString = _regexes[type]
                _regex = RegExp (_regexString.replace '__VARIABLE__', name)

                _results = []

                atom.project.scan _regex, undefined, (result) ->
                    _results.push result
                .finally ->
                    # Figure out what file is holding the definition
                    # Assume it's the one closest to the current path
                    _targetPath = atom.workspaceView.getActivePaneItem().getPath()
                    _targetFragments = _targetPath.split '/'

                    _bestMatch = null
                    _bestMatchHits = 0

                    for result in _results
                        _thisMatchHits = 0
                        _pathFragments = result.filePath.split '/'
                        _thisMatchHits++ for pathFragment, i in _pathFragments when pathFragment is _targetFragments[i]

                        if _thisMatchHits > _bestMatchHits
                            _bestMatch = result
                            _bestMatchHits = _thisMatchHits
                    return unless _bestMatch and _match = _bestMatch.matches[0]

                    _definition[name] = {
                        name: name
                        type: type
                        definition: (_match.matchText.match _regex)[1]

                        pointer:
                            filePath: _bestMatch.filePath
                            range: _match.range
                    }
