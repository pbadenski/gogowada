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

  dashboard = {
    src: "https://data.cityofchicago.org/resource/s6ha-ppgi.json"
    charts: [
      {
        chartType: "pieChart"
        dimension: "property_type"
      }
      {
        chartType: "rowChart"
        dimension: "zip_code"
      }
      {
        chartType: "leafletChoroplethChart"
        dimension: "zip_code"
        extras:
          {
            geojson: "https://gist.githubusercontent.com/pbadenski/e03ba5cecbcd3c47f249/raw/5f1ab78195f14803edb781cfee37f05cec202308/gistfile1.txt"
          }
      }
    ]
  }
  createChart = (csData) ->
    chartId = "chart_" + new Date().getTime()
    gridWidget = gridster.add_widget("<li><span class='widget-configure fa fa-wrench glow'></span></li>", 1, 1)
    gridWidget.append "<div id='" + chartId + "'>" + "<a class='reset' href='#' style='display: none;'>reset</a>" + "<div class='clearfix'></div>" + "</div>"
    __csData: csData
    __chartId: chartId
    __gridWidget: gridWidget
    type: (type) ->
      if type is undefined
        @_type
      else
        @_type = type
        this

    dimension: (dimension) ->
      if dimension is undefined
        @_dimension
      else
        @_dimension = dimension
        this

    extras: (extras) ->
      if extras is undefined
        @_extras
      else
        @_extras = extras
        this

    configure: (onSuccess = () -> null) ->
      self = this
      chart = dc[self.type()]("#" + self.__chartId)
      self.dcInstance = chart
      chartInstances[self.__chartId] = instance: self
      fieldDimension = self.__csData.dimension((d) -> d[self.dimension()])
      fieldGroup = fieldDimension.group()
      basicInitChart = chart
        .dimension(fieldDimension)
        .group(fieldGroup)
        .turnOnControls(true)
        .on('postRender', (chart) ->
           gridster_cols = Math.round(self.__gridWidget.find('.dc-chart').width() / gridster.options.widget_base_dimensions[0])
           gridster_rows = Math.round(self.__gridWidget.find('.dc-chart').height() / gridster.options.widget_base_dimensions[1])
           gridster.resize_widget self.__gridWidget, gridster_cols, gridster_rows
           self.__gridWidget.find('.dc-chart').find('.reset').click(() ->
             chart.filterAll()
             dc.redrawAll()
           )
        )
      switch self.type()
        when "pieChart"
          onSuccess(chart)
        when "barChart"
          basicInitChart
            .x(d3.scale.linear().domain([
              0
              fieldGroup.orderNatural().top(1)[0].value
            ]))
            .group(
              fieldDimension
              .group()
              .reduceCount((d) -> d[self.dimension()]))
            .centerBar(true)
            .xAxis().tickFormat()
          onSuccess(chart)
        when "bubbleChart"
          basicInitChart.x(d3.scale.linear().domain([
            0
            fieldGroup.orderNatural().top(1)[0].value
          ])).y(d3.scale.linear().domain([
            0
            fieldGroup.orderNatural().top(1)[0].value
          ]))
          onSuccess(chart)
        when "rowChart"
          basicInitChart
            .height(25 * fieldGroup.size())
          onSuccess(chart)
        when "leafletChoroplethChart"
          d3.json self.extras().geojson, (geojson) ->
            basicInitChart
              .width(600)
              .height(400)
              .center([41.83, -87.68])
              .zoom(10)
              .geojson(geojson)
              .featureKeyAccessor((feature) ->
                feature.properties.ZIP
              )
            onSuccess(basicInitChart)
        else
          onSuccess(basicInitChart)

  d3.json dashboard.src, (data) ->
    csData = crossfilter(data)
    _.each dashboard.charts, (eachSpec) ->
      chart = createChart(csData).type(eachSpec.chartType).dimension(eachSpec.dimension).extras(eachSpec.extras or {}).configure((chart) -> chart.render())

    dc.dataCount(".dc-data-count").dimension(csData).group(csData.groupAll()).html
      some: "<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records" + " | <a href='javascript:dc.filterAll(); dc.renderAll();''>Reset All</a>"
      all: "All records selected. Please click on the graph to apply filters."

    charts = ["pieChart", "rowChart", "barChart"]
    chartSelect = "<span>Chart type:</span>" + "<select id='chartSelect'>" + _.map(charts, (each) ->  "<option value='#{each}' selected>#{S(each).humanize()}</option>") + "</select>"
    properties = _.keys(_.sample(data, 1)[0]).sort()
    propertySelect = "<span>Property type:</span>" + "<select id='propertySelect'>" + _.map(properties, (each) -> "<option value='#{each}' selected>#{S(each).humanize()}</option>") + "</select>"

    gridster.$widgets.select(".widget-configure").click (clickEvent) ->
      $("#widget-configuration").html( chartSelect + propertySelect)
      chartId = $(clickEvent.target).parent().find(".dc-chart").attr("id")
      chartInstance = chartInstances[chartId].instance
      $("#chartSelect option[value='#{chartInstance.type()}']").prop("selected", true)
      $("#chartSelect").change (changeEvent) ->
        $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
        chartInstance.type($(this).val()).configure((chart) -> chart.render())
      $("#propertySelect option[value='#{chartInstance.dimension()}']").prop("selected", true)
      $("#propertySelect").change (changeEvent) ->
        $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
        chartInstance.dimension($(this).val()).configure((chart) -> chart.render())
