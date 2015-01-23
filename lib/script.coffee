Chart = require "./chart"
dashboards = require './dashboards'
chartInstances = {}

# dashboard = dashboards.chicago_employees
# dashboard = dashboards.chicago_affordable_housing
dashboard = null
$ ->
  gridster = $(".gridster > ul").gridster
    widget_margins: [10, 10]
    widget_base_dimensions: [60, 60]
    resize:
      enabled: true
    draggable:
       handle: 'header'
  .data("gridster")

  createGraphConfigurationComponents = (data, dimensionLookup) ->
    createSelect = (attribute, options) ->
      "<span>#{S(attribute).capitalize()}:</span><select id='#{S(attribute).camelize()}Select'><option selected>-- Select #{attribute}</option>" +
      _.map(options, (each) ->  "<option value='#{each}'>#{S(each).humanize()}</option>") +
      "</select>"

    charts = ["barChart", "pieChart", "rowChart", "donutChart", "lineChart"]
    properties = _.keys(_.sample(data, 1)[0]).sort()

    $(createSelect("chart type", charts) +
      createSelect("property", properties.concat(dimensionLookup.list)) +
      createSelect("group by function", ["count", "avg", "sum"]) +
      createSelect("group by property", properties))

  setupGraphConfigurationUI = (components, dimensionLookup) ->
    $(".widget-remove").click (clickEvent) ->
      chartId = $(clickEvent.target).closest("li").find("div[data-chart-id]").attr("data-chart-id")
      chartInstance = chartInstances[chartId].instance
      chartInstance.cleanupOnDelete()
      gridster.remove_widget($(clickEvent.target).closest("li"))
    $(".widget-configure").click (clickEvent) ->
      $("#widget-configuration").html(components)
      chartId = $(clickEvent.target).closest("li").find("div[data-chart-id]").attr("data-chart-id")
      chartInstance = chartInstances[chartId].instance

      markSelected = (attributeSelect, accessor) ->
        $(components).filter("##{attributeSelect}Select").children("option[value='#{chartInstance[accessor]()}']").prop("selected", true)

      updateChartOnChange = (attributeSelect, accessor, valueExtractor = (v) -> v) ->
        $(components).filter("##{attributeSelect}Select").change (changeEvent) ->
          $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
          chartInstance[accessor](valueExtractor($(this).val())).configure((chart) -> chart.render())

      markSelected "chartType", "type"
      updateChartOnChange "chartType", "type"

      markSelected "property", "dimensionName"
      updateChartOnChange "property", "dimension", (v) -> dimensionLookup.get v

      markSelected "groupByProperty", "groupByProperty"
      updateChartOnChange "groupByProperty", "groupByProperty"

      markSelected "groupByFunction", "groupByFunction"
      updateChartOnChange "groupByFunction", "groupByFunction"

  normalize = (data) ->
    data = _.map data, (d) ->
      for prop, val of d
        if `parseFloat(val) == val`
          d[prop] = parseFloat(val)
      d
    data

  class Dashboard
    constructor: (data, dimensionLookup = {get: _.identity, list: []}) ->
      data = normalize(data)
      @csData = crossfilter(data)
      $("#add-graph")
        .click () =>
          new Chart(@csData, gridster, chartInstances)
              .groupByFunction "count"
          setupGraphConfigurationUI(createGraphConfigurationComponents(data, dimensionLookup), dimensionLookup)
      dc.dataCount(".dc-data-count").dimension(@csData).group(@csData.groupAll()).html
        some: "<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records" + " | <a href='javascript:dc.filterAll(); dc.renderAll();''>Reset All</a>"
        all: "All records selected. Please click on the graph to apply filters."
      .render()
    processWithCrossFilterData: (f) => f(@csData)

  if dashboard
    d3.json dashboard.src, (data) ->
      dimensionLookup =
        get: (name) ->
          _.findWhere(dashboard.derivedProperties, {name: name}) or name
        list: _.pluck(dashboard.derivedProperties, "name")
      graphConfigurationComponents = createGraphConfigurationComponents data, dimensionLookup
      new Dashboard(data, dimensionLookup)
        .processWithCrossFilterData (csData) ->
          _.each dashboard.charts, (eachSpec) ->
            new Chart(csData, gridster, chartInstances)
              .type(eachSpec.chartType)
              .dimension(dimensionLookup.get eachSpec.dimension)
              .groupByFunction "count"
              .extras(eachSpec.extras or {})
              .configure (chart) ->
                chart.render()
                setupGraphConfigurationUI graphConfigurationComponents, dimensionLookup
    $("#set-json-file-input").val(dashboard.src)
    $("#set-json-file-button, #set-json-file-input").attr('disabled', true)

  $("#set-json-file-button").click () ->
    $("#set-json-file-input").attr('readonly', true)
    d3.json $("#set-json-file-input").val(), (data) ->
      new Dashboard(data)
      $("#json-data-selector").show()

