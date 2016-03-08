class AtomFingeraView extends HTMLElement
    init: ->
        @classList.add('fingera-status', 'inline-block')
        @innerHTML = """
            <span>
                <span id="fs-delta"></span>
                <span id="fs-arrival"></span>
            </span>
        """
        @delta = @querySelector("#fs-delta")
        @arrival = @querySelector("#fs-arrival")

    update: ->
        host = atom.config.get('fingera-status.host')
        user_number = atom.config.get('fingera-status.user_number')

        @updateDelta host, user_number

        show_arrival = atom.config.get('fingera-status.show_arrival')
        if show_arrival
            @updateArrival host, user_number
        else
            @arrival.innerHTML = ""


    activate: ->
        @update()
        @intervalUpdate = setInterval @update.bind(@), (60 * 1000)

    deactivate: ->
        clearInterval @intervalUpdate

    updateArrival: (host, user_number) ->
        url = "http://#{host}/users_summary"
        request = new XMLHttpRequest()
        request.open('GET', url, true)
        arrival = @arrival

        request.onerror = ->
            arrival.innerHTML = """ |
            <span class="icon-alert text-error"></span>
            """

        request.onload = ->
            if not ((request.status >= 200) and (request.status < 400))
                arrival.innerHTML = """ |
                    <span class="icon-alert text-error"></span>
                """
            else
                raw_data = request.responseText

                arrival.innerHTML = """ |
                    <span class="icon-sign-out text-warning"></span>
                """
                # Parse response
                html = document.createElement("html")
                html.innerHTML = raw_data
                selector = "div#user_status_info_#{user_number} p.status-info a"
                arrival_text = html.querySelector(selector)?.innerText
                arrival_value = /\d+:\d+/.exec(arrival_text)?[0]

                if (not arrival_value?) or (arrival_value.length < 1)
                    # Probably outside
                    return

                # Parse time
                h = parseInt(arrival_value.split(":")[0], 10)
                m = parseInt(arrival_value.split(":")[1], 10)
                arrival_date = new Date()
                arrival_date.setHours(h)
                arrival_date.setMinutes(m)
                arrival_date.setSeconds(0)

                arrival_period_minutes = atom.config.get('fingera-status.arrival_timer')
                if arrival_period_minutes > 0
                    now = new Date()

                    arrival_delta = now - arrival_date
                    arrival_delta_seconds = arrival_delta / 1000
                    arrival_delta_minutes = arrival_delta_seconds / 60
                    arrival_period_seconds = arrival_period_minutes * 60


                    if arrival_delta_seconds < (arrival_period_seconds * 0.25)
                        arrival_symbol = "○"
                        arrival_symbol_class = "text-error"
                    else if arrival_delta_seconds < (arrival_period_seconds * 0.5)
                        arrival_symbol = "◔"
                        arrival_symbol_class = "text-error"
                    else if arrival_delta_seconds < (arrival_period_seconds * 0.75)
                      arrival_symbol = "◑"
                      arrival_symbol_class = "text-warning"
                    else if arrival_delta_seconds < arrival_period_seconds
                        arrival_symbol = "◕"
                        arrival_symbol_class = "text-warning"
                    else
                        arrival_symbol = "✓"
                        arrival_symbol_class = "text-success"
                else
                    arrival_symbol = ""

                if arrival_delta_minutes > arrival_period_minutes
                    arrival_tooltip_text = "#{arrival_value}"
                    arrival_text = "+#{Math.round(arrival_delta_minutes) - 60}"
                else
                    arrival_tooltip_text = "#{Math.round(arrival_delta_minutes)} minutes"
                    arrival_text = "#{arrival_value}"

                arrival_html = if arrival_value? then """ |
                    <span class="" title="#{arrival_tooltip_text}">
                        <span class="#{arrival_symbol_class}">#{arrival_symbol}</span> #{arrival_text}
                    </span>
                    """
                arrival.innerHTML = arrival_html

        request.send()

    updateDelta: (host, user_number) ->
        url = "http://#{host}/users_summary/toggle_user_status/#{user_number}?show_worktime=1"
        request = new XMLHttpRequest()
        request.open('GET', url, true)

        delta = @delta
        request.onerror = ->
            delta.innerHTML = """
            <span class="icon-alert text-error"></span>
            """

        request.onload = ->
            if not ((request.status >= 200) and (request.status < 400))
                delta.innerHTML = """
                    <span class="icon-alert text-error"></span>
                """
            else
                raw_data = request.responseText

                # Parse response
                data_value = /(.*>)(.+)(<\/a>\"\)\;)/im.exec(raw_data)[2]
                delta_value = data_value.split("/")[1].replace(/^\s+|\s+$/g, '')
                summary_value = data_value.split("/")[0].replace(/^\s+|\s+$/g, '')
                delta_class = if delta_value.indexOf("+") >= 0 then "text-success" else "text-error"

                delta_html = """
                    <span class="#{delta_class}" title=#{summary_value}>#{delta_value}</span>
                """
                delta.innerHTML = delta_html

        request.send()

module.exports = document.registerElement('fingera-status', prototype: AtomFingeraView.prototype, extends: 'div')
