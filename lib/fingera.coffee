{CompositeDisposable} = require 'atom'
AtomFingeraView = require './fingera-view'

# console.log "Fingera loaded"

module.exports = AtomFingera =
    config:
        host:
            type: 'string'
        user_number:
            type: 'integer'
            min: 1
        show_arrival:
            type: 'boolean'
            default: true

    activate: (state)->
        @state = state
        @subscriptions = new CompositeDisposable
        @view = new AtomFingeraView()
        @view.init()

    deactivate: ->
        @subscriptions.dispose()
        @view.destroy()
        @tile?.destroy()

    consumeStatusBar: (statusBar) ->
        @statusBar = statusBar
        @view.activate()
        @tile = @statusBar.addRightTile
            item: @view,
            priority: -1
