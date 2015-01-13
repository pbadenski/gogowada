$ ->
  chartInstances = {}
  gridster = $(".gridster > ul").gridster(
    widget_margins: [
      10
      10
    ]
    widget_base_dimensions: [
      140
      140
    ]
    min_cols: 6
    resize:
      enabled: true
  ).data("gridster")
  $(".gridster ul").gridster
    widget_margins: [
      10
      10
    ]
    widget_base_dimensions: [
      140
      140
    ]

  chartSpecifications = [
    {
      chartType: "pieChart"
      dimension: "property_type"
    }
    {
      chartType: "rowChart"
      dimension: "zip_code"
    }
  ]
  createChart = (csData) ->
    chartId = "chart_" + new Date().getTime()
    gridWidget = gridster.add_widget("<li><span class='widget-configure fa fa-wrench glow'></span></li>", 2, 10)
    gridWidget.append "<div id='" + chartId + "'>" + "<a class='reset' href='javascript:chartInstances[\"" + chartId + "\"].dcInstance.filterAll();dc.redrawAll();' style='display: none;'>reset</a>" + "<div class='clearfix'></div>" + "</div>"
    __csData: csData
    __chartId: chartId
    type: (_type) ->
      @__type = _type
      this

    dimension: (_dimension) ->
      @__dimension = _dimension
      this

    configure: ->
      self = this
      chart = dc[self.__type]("#" + self.__chartId)
      self.dcInstance = chart
      chartInstances[self.__chartId] = instance: self
      fieldDimension = self.__csData.dimension((d) ->
        d[self.__dimension]
      )
      fieldGroup = fieldDimension.group()
      basicInitChart = chart.dimension(fieldDimension).group(fieldGroup).turnOnControls(true)
      switch @__type
        when "barChart"
          basicInitChart.x(d3.scale.linear().domain([
            0
            fieldGroup.orderNatural().top(1)[0].value
          ]))
        when "bubbleChart"
          basicInitChart.x(d3.scale.linear().domain([
            0
            fieldGroup.orderNatural().top(1)[0].value
          ])).y(d3.scale.linear().domain([
            0
            fieldGroup.orderNatural().top(1)[0].value
          ]))
        when "rowChart"
          basicInitChart.height(25 * fieldGroup.size())
        else
          basicInitChart

  d3.json "https://data.cityofchicago.org/resource/s6ha-ppgi.json", (data) ->
    csData = crossfilter(data)
    _.each chartSpecifications, (eachSpec) ->
      chart = createChart(csData).type(eachSpec.chartType).dimension(eachSpec.dimension).configure()

    dc.dataCount(".dc-data-count").dimension(csData).group(csData.groupAll()).html
      some: "<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records" + " | <a href='javascript:dc.filterAll(); dc.renderAll();''>Reset All</a>"
      all: "All records selected. Please click on the graph to apply filters."

    d3.json "https://gist.githubusercontent.com/pbadenski/e03ba5cecbcd3c47f249/raw/5f1ab78195f14803edb781cfee37f05cec202308/gistfile1.txt", (geojson) ->
      dimension = csData.dimension((d) -> d.zip_code)
      dc
        .leafletChoroplethChart("#map")
        .dimension(dimension)
        .group(dimension.group())
        .width(600)
        .height(400)
        .center([41.83, -87.68])
        .zoom(10)
        .geojson(geojson)
        .featureKeyAccessor((feature) ->
          feature.properties.ZIP
        )
        .render()

    dc.renderAll()
    gridster.resize_widget gridster.$widgets.eq(1), 2, 2
    gridster.$widgets.select(".widget-configure").click (clickEvent) ->
      $("#widget-configuration").html(
        "<span>Chart type:</span>" + "<select id='chartSelect'>" + "<option value='rowChart' selected>Row Chart</option>" + "<option value='pieChart'>Pie Chart</option>" + "</select>" +
        "<span>Property type:</span>" + "<select id='propertySelect'>" + "<option value='zip_code' selected>Zip code</option>" + "<option value='property_type'>Property type</option>" + "</select>"
      )
      $("#chartSelect").change (changeEvent) ->
        chartId = $(clickEvent.target).parent().find(".dc-chart").attr("id")
        $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
        chartInstances[chartId].instance.type($(this).val()).configure().render()
      $("#propertySelect").change (changeEvent) ->
        chartId = $(clickEvent.target).parent().find(".dc-chart").attr("id")
        $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
        chartInstances[chartId].instance.dimension($(this).val()).configure().render()
