Chart = require "./chart"
dashboards = require './dashboards'
chartInstances = {}

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



  class Dashboard
    constructor: (@data) ->
      @data = @normalize(data)
      @metadata = @createMetadata(@data)
      @csData = crossfilter(@data)
      $("#add-graph")
        .click () =>
          chart = new Chart(@csData, gridster, chartInstances)
              .groupByFunction "count"
          @setupGraphConfigurationUI(@createGraphConfigurationComponents(@data))
          $("##{chart.chartId} .widget-configure").click()
      dc.dataCount(".dc-data-count").dimension(@csData).group(@csData.groupAll()).html
        some: "<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records" + " | <a href='javascript:dc.filterAll(); dc.renderAll();''>Reset All</a>"
        all: "All records selected. Please click on the graph to apply filters."
      .render()

    createGraphConfigurationComponents: (data) ->
      createSelect = (desc, attribute, options, optionDisplay = (opt) -> opt) ->
        "<span>#{desc}</span><select id='#{S(attribute).camelize()}Select' class='form-control' style='width: 200px; display: inline'><option selected>-- Select #{attribute}</option>" +
        _.map(options, (each) ->  "<option value='#{each}'>#{optionDisplay(S(each).humanize().toLowerCase())}</option>") +
        "</select>"

      charts = ["bar", "pie", "row", "donut", "line"].sort()
      properties = _.keys(_.sample(data, 1)[0]).sort()

      $(
        "<select id='chartTypeSelect' class='form-control' style='width: 100px; display: inline'><option selected>-- Select chart</option>" +
        _.map(charts, (each) ->  "<option value='#{each}'>#{S(each).humanize()}</option>") +
        "</select><span>&nbsp;chart</span>" +
        createSelect("&nbsp;of&nbsp;", "property", properties, pluralize) +
        createSelect("&nbsp;grouped by&nbsp;", "group by function", ["count", "average", "sum"]) +
        createSelect(" of ", "group by property", properties, pluralize)
      )

    setupGraphConfigurationUI: (components) ->
      self = this
      $(".widget-remove").click (clickEvent) ->
        chartId = $(clickEvent.target).closest("li").find("div[data-chart-id]").attr("data-chart-id")
        chartInstance = chartInstances[chartId].instance
        chartInstance.cleanupOnDelete()
        gridster.remove_widget($(clickEvent.target).closest("li"))
      $(".gridster").click (e) ->
        if not $(e.target).closest('li.gs-w').length
          $(".widget-selected").removeClass("widget-selected")
          $("#widget-configuration").empty()
      $(".widget-configure").click (clickEvent) ->
        markSelected = (attributeSelect, accessor) ->
          $(components).filter("##{attributeSelect}Select").children("option[value='#{chartInstance[accessor]()}']").prop("selected", true)

        updateChartOnChange = (attributeSelect, accessor) ->
          $(components).filter("##{attributeSelect}Select").change (changeEvent) ->
            $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
            chartInstance[accessor]($(this).val()).configure((chart) -> chart.render())

        $(".widget-selected").removeClass("widget-selected")
        $(clickEvent.target).closest("li").addClass("widget-selected")
        $("#widget-configuration").html(components)
        chartId = $(clickEvent.target).closest("li").find("div[data-chart-id]").attr("data-chart-id")
        chartInstance = chartInstances[chartId].instance

        $("#chartTypeSelect").change ->
          $("#propertySelect option[value]").removeClass("hidden")
          if _.contains(["line", "bar"], $(this).val())
            for k, v of self.metadata
              if v isnt "number"
                $("#propertySelect option[value='#{k}']").addClass("hidden").prop("selected", false)
          $("#propertySelect option.hidden[selected]").prop('selected', false)

        $("#groupByFunctionSelect").change ->
          $("#groupByPropertySelect").removeClass("hidden")
          $("#groupByPropertySelect option[value]").removeClass("hidden")
          if _.contains(["average", "sum"], $(this).val())
            for k, v of self.metadata
              if v isnt "number"
                $("#groupByPropertySelect option[value='#{k}']").addClass("hidden").prop("selected", false)

        markSelected "chartType", "type"
        updateChartOnChange "chartType", "type"

        markSelected "property", "dimensionName"
        updateChartOnChange "property", "dimension"

        markSelected "groupByFunction", "groupByFunction"
        updateChartOnChange "groupByFunction", "groupByFunction"

        markSelected "groupByProperty", "groupByProperty"
        if chartInstance.groupByFunction() is "count" and chartInstance.groupByProperty() is undefined
          markSelected "groupByProperty", "dimensionName"
        updateChartOnChange "groupByProperty", "groupByProperty"


    loadCharts: (charts) ->
      graphConfigurationComponents = @createGraphConfigurationComponents @data
      _.map dashboard.charts, (eachSpec) =>
        new Chart(@csData, gridster, chartInstances)
          .type(eachSpec.chartType)
          .dimension(eachSpec.dimension)
          .groupByFunction "count"
          .extras(eachSpec.extras or {})
          .configure (chart) =>
            chart.render()
            @setupGraphConfigurationUI graphConfigurationComponents

    normalize: (data) ->
      data = _.map data, (d) ->
        for prop, val of d
          if `parseFloat(val) == val`
            d[prop] = parseFloat(val)
        d
      data

    createMetadata: (data) ->
      _.object([k, typeof(v)] for k, v of data[0])


  if dashboard
    d3.json dashboard.src, (data) ->
      new Dashboard(data)
        .loadCharts dashboard.charts
    $("#set-json-file-input").val(dashboard.src)
    $("#set-json-file-button, #set-json-file-input").attr('disabled', true)
    $("#add-graph").removeClass('hidden')

  $("#set-json-file-button").click () ->
    $("#set-json-file-button, #set-json-file-input").attr('disabled', true)
    $("#add-graph").removeClass('hidden')
    d3.json $("#set-json-file-input").val(), (data) ->
      new Dashboard(data)
      $("#json-data-selector").show()

