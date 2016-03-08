{CompositeDisposable} = require 'atom'
AtomFingeraView = require './fingera-view'

# console.log "Fingera loaded"

module.exports = AtomFingera =
    config:
        host:
            type: 'string'
            default: "127.0.0.1"
        user_number:
            type: 'integer'
            default: 1
            min: 1
        show_arrival:
            type: 'boolean'
            default: true
        arrival_timer:
            type: 'integer'
            default: 60
            min: 0

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
        if @view?
            @statusBar = statusBar
            @view.activate()
            @tile = @statusBar.addRightTile
                item: @view,
                priority: -1
