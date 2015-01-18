module.exports = class Chart
  constructor: (@csData, @gridster, chartInstances) ->
    @chartId = "chart_" + new Date().getTime()
    @gridWidget = gridster.add_widget("<li><header>|||</header><div class='widgets'><span class='widget-configure fa fa-wrench glow'></span><span class='widget-remove fa fa-remove glow'></span></div></li>", 1, 1)
    @gridWidget.append "<div id='" + @chartId + "' data-chart-id='" + @chartId + "'>" + "<a class='reset' href='#' style='display: none;'>reset</a>" + "<div class='clearfix'></div>" + "</div>"
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
    if @_dimension is undefined
      ""
    else
      @_dimension.name

  extras: (extras) ->
    if extras is undefined
      @_extras
    else
      @_extras = extras
      this
  configure: (onSuccess = () -> null) ->
    self = this
    return if @type() is undefined
    return if @dimension() is undefined
    chart = dc[@type()]("#" + @chartId)
    fieldDimension = @csData.dimension(@dimension().f)
    fieldGroup = fieldDimension.group()
    chart
      .dimension(fieldDimension)
      .group(fieldGroup)
      .turnOnControls(true)
      .on "postRender", (chart) ->
         gridster_col_width_with_margins = self.gridster.options.widget_base_dimensions[0] + 2 * self.gridster.options.widget_margins[0]
         gridster_row_width_with_margins = self.gridster.options.widget_base_dimensions[1] + 2 * self.gridster.options.widget_margins[1]
         gridster_cols = Math.ceil((self.gridWidget.find('.dc-chart').width() + 20) / gridster_col_width_with_margins)
         gridster_rows = Math.ceil((self.gridWidget.find('.dc-chart').height() + 20) / gridster_row_width_with_margins)
         
         console.log self.gridWidget.find('.dc-chart')
         console.log self.gridWidget.find('.dc-chart').width()
         console.log self.gridWidget.find('.dc-chart').height()
         self.gridster.resize_widget self.gridWidget, gridster_cols, gridster_rows
         self.gridWidget.find('.dc-chart').find('.reset').click () ->
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
            parseInt(fieldGroup.orderNatural().top(1)[0].key)
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
          .height(25 * fieldGroup.size())
        onSuccess(chart)
      when "leafletChoroplethChart"
        d3.json @extras().geojson, (geojson) =>
          console.log geojson
          chart
            .center([41.83, -87.68])
            .zoom(10)
            .geojson(geojson)
            .featureKeyAccessor(@extras().featureKeyAccessor)
          onSuccess(chart)
      else
        onSuccess(chart)
