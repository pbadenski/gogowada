Dashboard = require './dashboard'
dashboards = require './dashboards'

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
    $("#examples").addClass('hidden')

  project = $.url(window.location).param('project')
  if project
    dashboard = dashboards[project]
    d3.json dashboard.src, (data) ->
      new Dashboard(data, gridster)
        .loadCharts dashboard.charts
    $("#set-json-file-input").val(dashboard.src)
    afterJsonFileSet()
    $("#add-graph").removeClass('hidden')

  $("#set-json-file-button").click () ->
    afterJsonFileSet()
    $("#while-file-is-loaded").removeClass("hidden")
    d3.json $("#set-json-file-input").val(), (data) ->
      new Dashboard(data, gridster)
      $("#while-file-is-loaded").addClass("hidden")
      $("#add-graph").removeClass('hidden')

  $("#set-csv-file-button").click () ->
    afterJsonFileSet()
    $("#while-file-is-loaded").removeClass("hidden")
    reader = new FileReader()
    reader.onloadend = (e) ->
      contents = e.target.result
      new Dashboard(d3.csv.parse(contents), gridster)
      $("#while-file-is-loaded").addClass("hidden")
      $("#add-graph").removeClass('hidden')
    reader.readAsText($("#set-csv-file-input")[0].files[0])

