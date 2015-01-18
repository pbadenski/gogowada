Chart = require "./chart"
dashboards = require './dashboards'
chartInstances = {}

# dashboard = dashboards.chicago_employees
dashboard = dashboards.chicago_affordable_housing
$ ->
  gridster = $(".gridster > ul").gridster(
    widget_margins: [10, 10]
    widget_base_dimensions: [60, 60]
    resize:
      enabled: true
    draggable:
       handle: 'header'
  ).data("gridster")


  setupWidgets = (data) ->
    charts = ["pieChart", "rowChart", "barChart"]
    chartSelect = "<span>Chart type:</span><select id='chartSelect'><option selected>-- Select chart</option>" + _.map(charts, (each) ->  "<option value='#{each}'>#{S(each).humanize()}</option>") + "</select>"
    properties = _.keys(_.sample(data, 1)[0]).sort()
    propertySelect = "<span>Property:</span><select id='propertySelect'><option selected>-- Select property</option>" + _.map(properties, (each) -> "<option value='#{each}'>#{S(each).humanize()}</option>") + "</select>"
    $(".widget-remove").click (clickEvent) ->
      gridster.remove_widget($(clickEvent.target).closest("li"))
    $(".widget-configure").click (clickEvent) ->
      $("#widget-configuration").html( chartSelect + propertySelect)
      chartId = $(clickEvent.target).closest("li").find("div[data-chart-id]").attr("data-chart-id")
      chartInstance = chartInstances[chartId].instance
      $("#chartSelect option[value='#{chartInstance.type()}']").prop("selected", true)
      $("#chartSelect").change (changeEvent) ->
        $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
        chartInstance.type($(this).val()).configure((chart) -> chart.render())
      $("#propertySelect option[value='#{chartInstance.dimensionName()}']").prop("selected", true)
      $("#propertySelect").change (changeEvent) ->
        $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
        chartInstance.dimension($(this).val()).configure((chart) -> chart.render())

  normalize = (data) ->
    data = _.map data, (d) ->
      for prop, val of d
        if `parseFloat(val) == val`
          d[prop] = parseFloat(val)
      d
    console.log(data[0])
    data

  initializeDashboardFromSrc = (src, onCrossFilterData = () -> null) ->
    d3.json $("#set-json-file-input").val(), (data) ->
      data = normalize(data)
      csData = crossfilter(data)
      onCrossFilterData(csData)
      $("#add-graph")
        .click () ->
          new Chart(csData, gridster, chartInstances)
          setupWidgets(data)
      dc.dataCount(".dc-data-count").dimension(csData).group(csData.groupAll()).html
        some: "<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records" + " | <a href='javascript:dc.filterAll(); dc.renderAll();''>Reset All</a>"
        all: "All records selected. Please click on the graph to apply filters."
      .render()

  if dashboard
    d3.json dashboard.src, (data) ->
      initializeDashboardFromSrc dashboard.src, (csData) ->
        _.each dashboard.charts, (eachSpec) ->
          new Chart(csData, gridster, chartInstances)
            .type(eachSpec.chartType)
            .dimension(eachSpec.dimension)
            .extras(eachSpec.extras or {})
            .configure (chart) ->
              chart.render()
              setupWidgets(data)
    $("#set-json-file-input").val(dashboard.src)
    $("#set-json-file-button, #set-json-file-input").attr('disabled', true)

  $("#set-json-file-button").click () ->
    $("#set-json-file-input").attr('readonly', true)
    initializeDashboardFromSrc $("#set-json-file-input").val()

