module.exports = class Chart
  constructor: (@csData, @gridster, chartInstances) ->
    @chartId = "chart_" + new Date().getTime()
    @gridWidget = gridster.add_widget("<li></li>", 1, 1)
    widgets = "<div class='widgets' style='float: right'><a class='reset' href='#' style='display: none;'>reset</a><span class='widget-configure fa fa-wrench glow'></span><span class='widget-remove fa fa-remove glow'></span></div>"
    @gridWidget.append "<div id='" + @chartId + "' data-chart-id='#{@chartId}'><header style='float: left'>|||</header>#{widgets}<strong class='chart-title'>&nbsp;</strong><div class='clearfix'></div><div class='chart-content'></div></div>"
    chartInstances[@chartId] = instance: this
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
      @_dimension = {name: null, f: dimension}
      this
    else
      @_dimension = {name: dimension, f: (d) -> d[dimension]}
      this

  dimensionName: () ->
    @_dimension?.name

  extras: (extras) ->
    if extras is undefined
      @_extras
    else
      @_extras = extras
      this

  configure: (onSuccess = () -> null) ->
    return if @type() is undefined
    return if @dimension() is undefined
    chart = dc[@type()]("##{@chartId}")
    $("##{@chartId} .chart-title").html("&nbsp;#{S(@dimension().name).humanize()}")
    fieldDimension = @csData.dimension(@dimension().f)
    fieldGroup = fieldDimension.group()
    chart
      .anchor("##{@chartId} .chart-content")
      .dimension(fieldDimension)
      .group
        all: () ->
          fieldGroup.all().filter (d) -> d.value > 0
      .turnOnControls(true)
      .on "postRender", (chart) =>
         [gridster_widget_width, gridster_widget_height] = @gridster.options.widget_base_dimensions
         [gridster_margin_width, gridster_margin_height] = @gridster.options.widget_margins

         gridster_col_width_with_margins  = gridster_widget_width + 2 * gridster_margin_width
         gridster_cols = Math.ceil((@gridWidget.find('.dc-chart').width() + 20) / gridster_col_width_with_margins)

         gridster_row_height_with_margins = gridster_widget_height + 2 * gridster_margin_height
         gridster_rows = Math.ceil((@gridWidget.find('.dc-chart').height() + 20) / gridster_row_height_with_margins)
         
         @gridster.resize_widget @gridWidget, gridster_cols, gridster_rows
         @gridWidget.find('.dc-chart').find('.reset').click () ->
           chart.filterAll()
           dc.redrawAll()
    switch @type()
      when "pieChart"
        chart
          .width(200)
          .height(200)
        onSuccess(chart)
      when "barChart"
        chart
          .x(d3.scale.linear().domain([
            0
            _.max(_.pluck(fieldGroup.all(), "key")) * 1.2
          ]))
          .group(
            fieldDimension
            .group()
            .reduceCount(@dimension().f))
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
          .height () -> 25 * (chart.group().all().length + 1)
        onSuccess(chart)
      when "leafletChoroplethChart"
        d3.json @extras().geojson, (geojson) =>
          chart
            .center([41.83, -87.68])
            .zoom(10)
            .geojson(geojson)
            .featureKeyAccessor(@extras().featureKeyAccessor)
          onSuccess(chart)
      else
        onSuccess(chart)
