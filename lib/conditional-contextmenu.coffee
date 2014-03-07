# ----------------------------------------------------------------------------
#  Conditional Context Menu items
# ----------------------------------------------------------------------------

    module.exports =
        # Add a context menu item and show it or not based on a condition
        # @Object definition { label: '', command: '' }
        # @Function condition
        item: (definition, condition) -> atom.workspaceView.contextmenu =>
            _label = definition.label
            _command = definition.command

            _definitions = atom.contextMenu.definitions['.overlayer']
            _hasItem = true for item in _definitions when item.label is _label and item.command is _command

            if condition() then unless _hasItem
                _definitions.unshift
                    label: _label
                    command: _command
            else for item, i in _definitions when item
                if item.label is _label
                    _definitions.splice i, 1
