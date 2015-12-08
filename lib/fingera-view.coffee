class AtomFingeraView extends HTMLElement
    init: ->
        @classList.add('fingera-status', 'inline-block')
        @innerHTML = """
            <span>
                <span></span>
                <span></span>
            </span>
        """
        @arrival = @querySelector("span span:nth-child(2)")
        @delta = @querySelector("span span:nth-child(1)")

    activate: ->
        @updateDelta()
        @updateArrival()

        @intervalDeltaId = setInterval @updateDelta.bind(@), (60 * 1000)
        @intervalArrivalId = setInterval @updateArrival.bind(@), (60 * 1000)

    deactivate: ->
        clearInterval @intervalDeltaId
        clearInterval @intervalArrivalId

    updateArrival: ->
        show_arrival = atom.config.get('fingera-status.show_arrival')
        if not show_arrival
            @arrival.innerHTML = ""
            return

        host = atom.config.get('fingera-status.host')
        user_number = atom.config.get('fingera-status.user_number')

        request = new XMLHttpRequest()
        url = "http://#{host}/users_summary"
        request.open('GET', url, true)

        arrival = @arrival

        request.onload = ->
            if (request.status >= 200) and (request.status < 400)
                raw_data = request.responseText

                # Parse response
                html = document.createElement("html")
                html.innerHTML = raw_data
                selector = "div#user_status_info_#{user_number} p.status-info a"
                arrival_text = html.querySelector(selector).innerText
                arrival_value = /\d+:\d+/.exec(arrival_text)?[0]

                if (not arrival_value?) or (arrival_value.length < 1)
                    arrival.innerHTML = """ |
                        <span class="icon-sign-out text-warning"></span>
                    """
                    return

                h = parseInt(arrival_value.split(":")[0], 10)
                m = parseInt(arrival_value.split(":")[1], 10)
                arrival_date = new Date()
                arrival_date.setHours(h)
                arrival_date.setMinutes(m)
                arrival_date.setSeconds(0)

                now = new Date()

                arrival_delta = now - arrival_date
                arrival_delta_minutes = arrival_delta / 1000 / 60

                if arrival_delta_minutes < 15
                    arrival_symbol = "○"
                    arrival_symbol_class = "text-error"
                else if arrival_delta_minutes < 30
                    arrival_symbol = "◔"
                    arrival_symbol_class = "text-error"
                else if arrival_delta_minutes < 45
                  arrival_symbol = "◑"
                  arrival_symbol_class = "text-warning"
                else if arrival_delta_minutes < 60
                    arrival_symbol = "◕"
                    arrival_symbol_class = "text-warning"
                else
                    arrival_symbol = "✓"
                    arrival_symbol_class = "text-success"


                arrival_tooltip_text = if arrival_delta_minutes > 60 then "#{arrival_value}" else "#{Math.round(arrival_delta_minutes)} minutes"
                arrival_text = if arrival_delta_minutes > 60 then "+#{Math.round(arrival_delta_minutes) - 60}" else "#{arrival_value}"

                arrival_html = if arrival_value? then """ |
                    <span class="" title="#{arrival_tooltip_text}">
                        <span class="#{arrival_symbol_class}">#{arrival_symbol}</span> #{arrival_text}
                    </span>
                """ else """ |
                    <span class="badge badge-small text-error">✖</span>
                """
                arrival.innerHTML = arrival_html

            else
                arrival.innerHTML = """ |
                    <span class="icon-alert text-error"></span>
                """

        request.onerror = ->
            arrival.innerHTML = """ |
                <span class="icon-alert text-error"></span>
            """

        request.send()

    updateDelta: ->
        host = atom.config.get('fingera-status.host')
        user_number = atom.config.get('fingera-status.user_number')

        request = new XMLHttpRequest()
        url = "http://#{host}/users_summary/toggle_user_status/#{user_number}?show_worktime=1"
        request.open('GET', url, true)


        delta = @delta
        request.onload = ->
            if (request.status >= 200) and (request.status < 400)
                raw_data = request.responseText

                # Parse response
                # html = document.createElement("html")
                # html.innerHTML = raw_data
                # selector = 'a[title="Zobrazit stav"]'
                # data_value = html.querySelector(selector).innerText

                data_value = /(.*>)(.+)(<\/a>\\n<\/span>)/im.exec(raw_data)[2]
                delta_value = data_value.split("/")[1].replace(/^\s+|\s+$/g, '')
                summary_value = data_value.split("/")[0].replace(/^\s+|\s+$/g, '')
                delta_class = if delta_value.indexOf("+") >= 0 then "text-success" else "text-error"

                delta_html = """
                    <span class="#{delta_class}" title=#{summary_value}>#{delta_value}</span>
                """
                delta.innerHTML = delta_html

            else
                delta.innerHTML = """
                    <span class="icon-alert text-error"></span>
                """

                request.onerror = ->
                    delta.innerHTML = """
                        <span class="icon-alert text-error"></span>
                    """

        request.send()

module.exports = document.registerElement('fingera-status', prototype: AtomFingeraView.prototype, extends: 'div')
