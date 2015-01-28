Dashboard = require './dashboard'
dashboards = require './dashboards'

dashboard = null
# dashboard = dashboards.chicago_employees
# dashboard = dashboards.chicago_affordable_housing
$ ->
  gridster = $(".gridster > ul").gridster
    widget_margins: [10, 10]
    widget_base_dimensions: [60, 60]
    resize:
      enabled: true
    draggable:
       handle: 'header'
  .data("gridster")

  afterJsonFileSet = () ->
    $("#set-json-file-button, #set-json-file-input").attr('disabled', true)

  if dashboard
    d3.json dashboard.src, (data) ->
      new Dashboard(data, gridster)
        .loadCharts dashboard.charts
    $("#set-json-file-input").val(dashboard.src)
    afterJsonFileSet()
    $("#add-graph").removeClass('hidden')

  $("#set-json-file-button").click () ->
    afterJsonFileSet()
    $("#while-json-is-loaded").removeClass("hidden")
    d3.json $("#set-json-file-input").val(), (data) ->
      new Dashboard(data, gridster)
      $("#while-json-is-loaded").addClass("hidden")
      $("#add-graph").removeClass('hidden')

