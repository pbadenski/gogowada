GraphConfiguration = require "./graph_configuration"
Chart = require "./chart"

removeWidgetHandler = (target, chartInstances, gridster) ->
  chartId = $(target).closest("li").find("div[data-chart-id]").attr("data-chart-id")
  chartInstance = chartInstances[chartId].instance
  chartInstance.cleanupOnDelete()
  gridster.remove_widget($(target).closest("li"))
  $("#graph-configuration").empty()

module.exports = class Dashboard
  @chartInstances: {}

  constructor: (@data, @gridster) ->
    @data = @normalize(data)
    @csData = crossfilter(@data)
    @graphConfiguration = new GraphConfiguration @data
    $("#add-graph")
      .click () =>
        chart = new Chart(@csData, gridster, Dashboard.chartInstances)
            .groupByFunction "count"
        $(".widget-remove").click (clickEvent) ->
          removeWidgetHandler(clickEvent.target, Dashboard.chartInstances, gridster)
        @graphConfiguration.setupUI(Dashboard.chartInstances, gridster)
        $("##{chart.chartId} .graph-configure").click()
    dc.dataCount(".dc-data-count").dimension(@csData).group(@csData.groupAll()).html
      some: "<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records" + " | <a href='javascript:dc.filterAll(); dc.renderAll();''>Reset All</a>"
      all: ""
    .render()

  loadCharts: (charts) ->
    _.map charts, (eachSpec) =>
      new Chart(@csData, @gridster, Dashboard.chartInstances)
        .type(eachSpec.chartType)
        .dimension(eachSpec.dimension)
        .groupByFunction "count"
        .extras(eachSpec.extras or {})
        .configure (chart) =>
          chart.render()
          @graphConfiguration.setupUI(Dashboard.chartInstances, @gridster)
          $(".widget-remove").click (clickEvent) =>
            removeWidgetHandler(clickEvent.target, Dashboard.chartInstances, @gridster)

  normalize: (data) ->
    data = _.map data, (d) ->
      for prop, val of d
        if `parseFloat(val) == val`
          d[prop] = parseFloat(val)
        else if _.contains(val, "-") or _.contains(val, "/")
          dateValue = moment(val, ["YYYY-MM-DD", "YYYY-MM-DDThh:mm:ss", "MM/DD/YYYY"], true)
          if dateValue.isValid()
            d[prop] = dateValue.toDate()
      d
    data
