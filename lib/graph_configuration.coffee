module.exports = class GraphConfiguration
  constructor: (data) ->
    @metadata = @createMetadata(data)
    createSelect = (desc, attribute, options, optionDisplay = (opt) -> opt) ->
      "<span>#{desc}</span><select id='#{S(attribute).camelize()}Select' class='form-control' style='width: 200px; display: inline'><option selected>-- Select #{attribute}</option>" +
      _.map(options, (each) ->  "<option value='#{each}'>#{optionDisplay(S(each).humanize().toLowerCase())}</option>") +
      "</select>"

    charts = ["bar", "pie", "row", "donut", "line"].sort()
    properties = _.keys(_.sample(data, 1)[0]).sort()

    @components = $(
      "<select id='chartTypeSelect' class='form-control' style='width: 100px; display: inline'><option selected>-- Select chart</option>" +
      _.map(charts, (each) ->  "<option value='#{each}'>#{S(each).humanize()}</option>") +
      "</select><span>&nbsp;chart</span>" +
      createSelect("&nbsp;of&nbsp;", "property", properties, pluralize) +
      createSelect("&nbsp;grouped by&nbsp;", "group by function", ["count", "average", "sum"]) +
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
        selectElement.children("option[value='#{chartInstance[accessor]()}']").prop("selected", true)
        selectElement.change()

      updateChartOnChange = (attributeSelect, accessor) ->
        $(self.components).filter("##{attributeSelect}Select").change (changeEvent) ->
          $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
          chartInstance[accessor]($(this).val()).configure((chart) -> chart.render())

      $(".widget-selected").removeClass("widget-selected")
      $(clickEvent.target).closest("li").addClass("widget-selected")
      $("#graph-configuration").html(self.components)
      chartId = $(clickEvent.target).closest("li").find("div[data-chart-id]").attr("data-chart-id")
      chartInstance = chartInstances[chartId].instance

      $("#chartTypeSelect").change ->
        $("#propertySelect option[value]").removeClass("hidden")
        if _.contains(["line", "bar"], $(this).val())
          for k, v of self.metadata
            if not _.contains ["number", "date"], v
              $("#propertySelect option[value='#{k}']").addClass("hidden").prop("selected", false)
        $("#propertySelect option.hidden[selected]").prop('selected', false)

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

