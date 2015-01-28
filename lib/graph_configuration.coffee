ChartDefinitions = require './chart_definitions'
module.exports = class GraphConfiguration
  constructor: (data) ->
    @metadata = @createMetadata(data)
    createSelect = (desc, attribute, options, optionDisplay = _.identity, width = 200) ->
      "<span>#{desc}</span><select id='#{S(attribute).camelize()}Select' class='form-control' style='width: #{width}px; display: inline'><option value='' selected>-- Select #{attribute}</option>" +
      _.map(options, (each) ->  "<option value='#{each}'>#{optionDisplay(S(each).humanize().toLowerCase())}</option>") +
      "</select>"

    charts = _.reject(_.keys(ChartDefinitions), (d) -> _.contains(["choropleth"], d)).sort()
    properties = _.union.apply(_, _.map(data, _.keys)).sort()

    @components = $(
      "<select id='chartTypeSelect' class='form-control' style='width: 100px; display: inline'><option selected>-- Select chart</option>" +
      _.map(charts, (each) ->  "<option value='#{each}'>#{S(each).humanize()}</option>") +
      "</select><span>&nbsp;chart</span>" +
      "<span id='mapConfiguration'>" +
      createSelect(",&nbsp; latitude of &nbsp;", "latitude", properties, pluralize) +
      createSelect("&nbsp;and longitude of &nbsp;", "longitude", properties, pluralize) +
      "</span>" +
      createSelect("&nbsp;of&nbsp;", "property", properties, pluralize) +
      createSelect("&nbsp;grouped by&nbsp;", "group by function", ["count", "average", "sum"], _.identity, 100) +
      createSelect(" of ", "group by property", properties, pluralize)
    )

  createMetadata: (data) ->
    _.object(
      [k, if _.isDate(v) then "date" else typeof(v)] for k, v of data[0]
    )

  setupUI: (chartInstances, gridster) ->
    self = this
    $(".gridster").click (e) ->
      if not $(e.target).closest('li.gs-w').length
        $(".widget-selected").removeClass("widget-selected")
        $("#graph-configuration").empty()
    $(".graph-configure").click (clickEvent) ->
      markSelected = (attributeSelect, accessor) ->
        selectElement = $(self.components).filter("##{attributeSelect}Select")
        selectElement.children("option").prop("selected", false)
        selectElement.children("option[value='#{chartInstance[accessor]()}']").prop("selected", true)
        selectElement.change()

      updateChartOnChange = (attributeSelect, accessor) ->
        $(self.components).filter("##{attributeSelect}Select").change (changeEvent) ->
          $(clickEvent.target).closest(".dc-chart").find(".chart-content").replaceWith("<div class='chart-content'></div>")
          chartInstance[accessor]($(this).val()).configure((chart) -> chart.render())

      $(".widget-selected").removeClass("widget-selected")
      $(clickEvent.target).closest("li").addClass("widget-selected")
      $("#graph-configuration").html(self.components)
      chartId = $(clickEvent.target).closest("li").find("div[data-chart-id]").attr("data-chart-id")
      chartInstance = chartInstances[chartId].instance

      $("#mapConfiguration").addClass("hidden")
      $("#chartTypeSelect").change ->
        $("#propertySelect option[value]").removeClass("hidden")
        if _.contains(["line", "bar"], $(this).val())
          for k, v of self.metadata
            if not _.contains ["number", "date"], v
              $("#propertySelect option[value='#{k}']").addClass("hidden").prop("selected", false)
        if _.contains(["markers on the map", "clustered markers on the map"], $(this).val())
          $("#propertySelect").addClass("hidden")
          $("#mapConfiguration").removeClass("hidden")
        else
          $("#propertySelect").removeClass("hidden")
          $("#mapConfiguration").addClass("hidden")
        $("#propertySelect option.hidden[selected]").prop('selected', false)

      $("#latitudeSelect").change ->
        if $("#longitudeSelect").val()
          $(clickEvent.target).closest(".dc-chart").find(".chart-content").replaceWith("<div class='chart-content'></div>")
          chartInstance.dimension([$("#latitudeSelect").val(), $("#longitudeSelect").val()]).configure((chart) -> chart.render())

      $("#longitudeSelect").change ->
        if $("#latitudeSelect").val()
          $(clickEvent.target).closest(".dc-chart").find(".chart-content").replaceWith("<div class='chart-content'></div>")
          chartInstance.dimension([$("#latitudeSelect").val(), $("#longitudeSelect").val()]).configure((chart) -> chart.render())

      $("#groupByFunctionSelect").change ->
        $("#groupByPropertySelect").removeClass("hidden")
        $("#groupByPropertySelect option[value]").removeClass("hidden")
        if _.contains(["average", "sum"], $(this).val())
          for k, v of self.metadata
            if not _.contains ["number"], v
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

