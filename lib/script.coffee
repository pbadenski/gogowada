$ ->
  chartInstances = {}
  gridster = $(".gridster > ul").gridster(
    widget_margins: [10, 10]
    widget_base_dimensions: [140, 140]
    resize:
      enabled: true
  ).data("gridster")

  dashboard1 = {
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
            featureKeyAccessor: (f) -> f.properties.ZIP
          }
      }
    ]
  }
  dashboard2 = {
    src: "https://data.cityofchicago.org/resource/xzkq-xp2w.json",
    charts: [
      {
        chartType: "pieChart"
        dimension: (d) ->
          if (d.employee_annual_salary > 100000)
            "Above 100k"
          else if (d.employee_annual_salary > 80000)
            "Between 80k and 100k"
          else if (d.employee_annual_salary > 60000)
            "Between 60k and 80k"
          else if (d.employee_annual_salary > 40000)
            "Between 40k and 60k"
          else
            "Below 40k"
      }
      {
        chartType: "rowChart"
        dimension: "department"
      }
    ]
  }
  dashboard3 = {}
  dashboard = dashboard3
  if dashboard.src
    $("#dataUrl").val(dashboard.src)
  createChart = (csData) ->
    chartId = "chart_" + new Date().getTime()
    gridWidget = gridster.add_widget("<li><div class='widgets'><span class='widget-configure fa fa-wrench glow'></span><span class='widget-remove fa fa-remove glow'></span></div></li>", 1, 1)
    gridWidget.append "<div id='" + chartId + "' data-chart-id='" + chartId + "'>" + "<a class='reset' href='#' style='display: none;'>reset</a>" + "<div class='clearfix'></div>" + "</div>"
    chart =
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
        else if typeof dimension is "function"
          @_dimension = dimension
          this
        else
          @_dimension = (d) -> d[dimension]
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
        fieldDimension = self.__csData.dimension(self.dimension())
        fieldGroup = fieldDimension.group()
        chart
          .dimension(fieldDimension)
          .group(fieldGroup)
          .turnOnControls(true)
          .on('postRender', (chart) ->
             gridster_cols = Math.ceil(self.__gridWidget.find('.dc-chart').width() / gridster.options.widget_base_dimensions[0])
             gridster_rows = Math.ceil(self.__gridWidget.find('.dc-chart').height() / gridster.options.widget_base_dimensions[1])
             gridster.resize_widget self.__gridWidget, gridster_cols, gridster_rows
             self.__gridWidget.find('.dc-chart').find('.reset').click(() ->
               chart.filterAll()
               dc.redrawAll()
             )
          )
        self.dcInstance = chart
        switch self.type()
          when "pieChart"
            chart
              .width(200)
              .height(200)
            onSuccess(chart)
          when "barChart"
            chart
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
            chart.x(d3.scale.linear().domain([
              0
              fieldGroup.orderNatural().top(1)[0].value
            ])).y(d3.scale.linear().domain([
              0
              fieldGroup.orderNatural().top(1)[0].value
            ]))
            onSuccess(chart)
          when "rowChart"
            chart
              .height(25 * fieldGroup.size())
            onSuccess(chart)
          when "leafletChoroplethChart"
            d3.json self.extras().geojson, (geojson) ->
              chart
                .width(600)
                .height(400)
                .center([41.83, -87.68])
                .zoom(10)
                .geojson(geojson)
                .featureKeyAccessor(self.extras().featureKeyAccessor)
              onSuccess(chart)
          else
            onSuccess(chart)
    chartInstances[chartId] = instance: chart
    chart

  setupWidgets = (data) ->
    charts = ["pieChart", "rowChart", "barChart"]
    chartSelect = "<span>Chart type:</span>" + "<select id='chartSelect'>" + _.map(charts, (each) ->  "<option value='#{each}' selected>#{S(each).humanize()}</option>") + "</select>"
    properties = _.keys(_.sample(data, 1)[0]).sort()
    propertySelect = "<span>Property type:</span>" + "<select id='propertySelect'>" + _.map(properties, (each) -> "<option value='#{each}' selected>#{S(each).humanize()}</option>") + "</select>"
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
      $("#propertySelect option[value='#{chartInstance.dimension()}']").prop("selected", true)
      $("#propertySelect").change (changeEvent) ->
        $(clickEvent.target).parent().find(".dc-chart").children("svg").remove()
        chartInstance.dimension($(this).val()).configure((chart) -> chart.render())

  $("#set-json-file-button").click () ->
    $("#set-json-file-input").attr('readonly', true)
    dashboard.src = $("#set-json-file-input").val()
    d3.json dashboard.src, (data) ->
      csData = crossfilter(data)
      $("#add-graph")
        .click () ->
          createChart(csData)
          setupWidgets(data)
      _.each dashboard.charts, (eachSpec) ->
        createChart(csData)
          .type(eachSpec.chartType)
          .dimension(eachSpec.dimension)
          .extras(eachSpec.extras or {})
          .configure (chart) ->
            chart.render()
            setupWidgets(data)
      dc.dataCount(".dc-data-count").dimension(csData).group(csData.groupAll()).html
        some: "<strong>%filter-count</strong> selected out of <strong>%total-count</strong> records" + " | <a href='javascript:dc.filterAll(); dc.renderAll();''>Reset All</a>"
        all: "All records selected. Please click on the graph to apply filters."


