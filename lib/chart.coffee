ChartDefinitions = require './chart_definitions'
module.exports = class Chart
  constructor: (@csData, @gridster, chartInstances) ->
    @chartId = "chart_" + new Date().getTime()
    @gridWidget = gridster.add_widget("<li></li>", 4, 4)
    widgets = "<div class='widgets' style='float: right'><a class='reset' href='#' style='display: none;'>reset</a><span class='graph-configure fa fa-wrench glow'></span><span class='widget-remove fa fa-remove glow'></span></div>"
    @gridWidget.append "<div id='#{@chartId}' data-chart-id='#{@chartId}'><header class='widget-drag-handle fa fa-navicon'></header>#{widgets}<strong class='chart-title'>&nbsp;</strong><div class='clearfix'></div><div class='chart-content'></div></div>"
    chartInstances[@chartId] = instance: this
  type: (type) ->
    if type is undefined
      @_type
    else
      @_type = type
      this

  groupByProperty: (groupByProperty) ->
    if groupByProperty is undefined
      @_groupByProperty
    else
      @_groupByProperty = groupByProperty
      this

  groupByFunction: (groupByFunction) ->
    if groupByFunction is undefined
      @_groupByFunction
    else
      @_groupByFunction = groupByFunction
      this

  dimension: (dimension) ->
    if dimension is undefined
      @_dimension
    else if _.isArray dimension
      @_dimension =
        name: dimension
        f: (d) -> _.map(dimension, (each) -> d[each])
      this
    else
      @_dimension =
        name: dimension
        f: (d) -> d[dimension]
      this

  dimensionName: () ->
    @_dimension?.name

  extras: (extras) ->
    if extras is undefined
      @_extras
    else
      @_extras = extras
      this

  cleanupOnDelete: () ->
    dc.deregisterChart(@dcInstance) if @dcInstance

  resizeGridsterWidgetToFitChart: () ->
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

  createReducers: () ->
    reduceAdd = (attr) ->
      (p, v) ->
        ++p.count
        p.sum += if attr then (v[attr] or 0) else 0
        p.average = p.sum / p.count
        p
    reduceRemove = (attr) ->
      (p, v) ->
        --p.count
        p.sum -= if attr then (v[attr] or 0) else 0
        p.average = p.sum / p.count
        p
    reduceInit = ->
      count: 0
      sum: 0
      average: 0
    [reduceAdd, reduceRemove, reduceInit]

  configure: (onSuccess = () -> null) ->
    return if @type() is undefined
    return if @dimension() is undefined
    dc.deregisterChart @dcInstance if @dcInstance

    chartDefinition = ChartDefinitions[@type()]
    chart = dc[chartDefinition.type]("##{@chartId}")
    @dcInstance = chart

    fieldDimension = @csData.dimension(@dimension().f)
    [reduceAdd, reduceRemove, reduceInit] = @createReducers()
    fieldGroup = fieldDimension.group().reduce(reduceAdd(@groupByProperty()), reduceRemove(@groupByProperty()), reduceInit)
    chart
      .root(d3.select "##{@chartId} .chart-content")
      .dimension(fieldDimension)
      .group
        all: () ->
          fieldGroup.all().filter (d) ->
            if _.isArray d.key
              not _.contains(d.key, undefined)
            else
              d.key? and (d.value.count > 0)
      .turnOnControls(true)
      .on "postRender", (chart) => @resizeGridsterWidgetToFitChart()
      .valueAccessor((d) => d.value[@groupByFunction()])
    $("##{@chartId} .chart-title").html("&nbsp;#{S(@dimension().name).humanize()}")
    chartDefinition.customize(chart, fieldGroup, onSuccess, @extras())
