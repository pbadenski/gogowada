chartDefinitions = [
  {
    name: "pie"
    type: "pieChart"
    customize: (chart, dimension, fieldDimension, fieldGroup, onSuccess) ->
      chart
        .width(200)
        .height(200)
      onSuccess(chart)
  }
  {
    name: "donut"
    type: "pieChart"
    customize: (chart, dimension, fieldDimension, fieldGroup, onSuccess) ->
      chart
        .width(200)
        .height(200)
        .innerRadius(40)
      onSuccess(chart)
  }
  {
    name: "bar"
    type: "barChart"
    customize: (chart, dimension, fieldDimension, fieldGroup, onSuccess) ->
      chart
        .x(d3.scale.linear().domain([
          0
          _.max(_.pluck(fieldGroup.all(), "key")) * 1.2
        ]))
        .centerBar(true)
        .elasticY(true)
        .xAxis().tickFormat(d3.format("s"))
      onSuccess(chart)
  }
  {
    name: "bubble"
    type: "bubbleChart"
    customize: (chart, dimension, fieldDimension, fieldGroup, onSuccess) ->
      chart.x(d3.scale.linear().domain([
        0
        fieldGroup.orderNatural().top(1)[0].value
      ])).y(d3.scale.linear().domain([
        0
        fieldGroup.orderNatural().top(1)[0].value
      ]))
      onSuccess(chart)
  }
  {
    name: "line"
    type: "lineChart"
    customize: (chart, dimension, fieldDimension, fieldGroup, onSuccess) ->
      sampleElement = _.min(_.pluck(fieldGroup.all(), "key"))
      date =
        scale: d3.time.scale().domain([
          _.min(_.pluck(fieldGroup.all(), "key")),
          _.max(_.pluck(fieldGroup.all(), "key"))
      ])
        tickFormat: d3.time.format "%Y-%m-%d"
      number =
        scale: d3.scale.linear().domain([
          0
          _.max(_.pluck(fieldGroup.all(), "key")) * 1.2
        ])
        tickFormat: d3.format "s"
      typeOfDimension = if _.isDate sampleElement then date else number
      chart
        .width(1000)
        .x(typeOfDimension.scale)
      chart
        .xAxis().tickFormat(typeOfDimension.tickFormat)
      chart
        .yAxis().tickFormat(d3.format("s"))
      onSuccess(chart)
  }
  {
    name: "row"
    type: "rowChart"
    customize: (chart, dimension, fieldDimension, fieldGroup, onSuccess) ->
      chart
        .height () -> 25 * (chart.group().all().length + 1)
        .xAxis().tickFormat(d3.format("s"))
      onSuccess(chart)
  }
  {
    name: "choropleth"
    type: "leafletChoroplethChart"
    customize: (chart, dimension, fieldDimension, fieldGroup, onSuccess, extras) ->
      d3.json extras.geojson, (geojson) =>
        chart
          .center([41.83, -87.68])
          .zoom(10)
          .geojson(geojson)
          .featureKeyAccessor(extras.featureKeyAccessor)
        onSuccess(chart)
  }
]
module.exports = class Chart
  constructor: (@csData, @gridster, chartInstances) ->
    @chartId = "chart_" + new Date().getTime()
    @gridWidget = gridster.add_widget("<li></li>", 4, 4)
    widgets = "<div class='widgets' style='float: right'><a class='reset' href='#' style='display: none;'>reset</a><span class='widget-configure fa fa-wrench glow'></span><span class='widget-remove fa fa-remove glow'></span></div>"
    @gridWidget.append "<div id='" + @chartId + "' data-chart-id='#{@chartId}'><header class='widget-drag-handle fa fa-navicon'></header>#{widgets}<strong class='chart-title'>&nbsp;</strong><div class='clearfix'></div><div class='chart-content'></div></div>"
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

  configure: (onSuccess = () -> null) ->
    return if @type() is undefined
    return if @dimension() is undefined
    chartDefinition = _.findWhere(chartDefinitions, {name: @type()})
    dc.deregisterChart @dcInstance if @dcInstance
    chart = dc[chartDefinition.type]("##{@chartId}")
    @dcInstance = chart
    $("##{@chartId} .chart-title").html("&nbsp;#{S(@dimension().name).humanize()}")
    fieldDimension = @csData.dimension(@dimension().f)
    dimensionElement = @dimension().f(fieldDimension.top(1)[0])
    if _.isArray dimensionElement
      reduceAdd = (p, v) =>
        @dimension().f(v).forEach (val, idx) ->
          p[val] = (p[val] or 0) + 1
        p
      reduceRemove = (p, v) =>
        @dimension().f(v).forEach (val, idx) ->
          p[val] = (p[val] or 0) - 1
        p
      reduceInitial = () -> {}
      fieldGroup = fieldDimension.groupAll().reduce(reduceAdd, reduceRemove, reduceInitial).value()
      fieldGroup.all = ->
        newObject = []
        for key of this
          if @hasOwnProperty(key) and key isnt "all"
            newObject.push
              key: key
              value: this[key]

        newObject
      chart.filterHandler (dimension, filters) ->
        dimension.filter null
        if filters.length is 0
          dimension.filter null
        else
          dimension.filterFunction (d) ->
            i = 0
            while i < d.length
              return true  if filters.indexOf(d[i]) >= 0
              i++
            false
        filters
    else
      reduceAddAvg = (attr) ->
        (p, v) ->
          ++p.count
          p.sum += if attr then (v[attr] or 0) else 0
          p.average = p.sum / p.count
          p
      reduceRemoveAvg = (attr) ->
        (p, v) ->
          --p.count
          p.sum -= if attr then (v[attr] or 0) else 0
          p.average = p.sum / p.count
          p
      reduceInitAvg = ->
        count: 0
        sum: 0
        average: 0
      fieldGroup = fieldDimension.group().reduce(reduceAddAvg(@groupByProperty()), reduceRemoveAvg(@groupByProperty()), reduceInitAvg)
    chart
      .root(d3.select "##{@chartId} .chart-content")
      .dimension(fieldDimension)
      .group
        all: () ->
          fieldGroup.all().filter (d) -> d.value.count > 0
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
       .valueAccessor((d) => d.value[@groupByFunction()])
     chartDefinition.customize(chart, @dimension(), fieldDimension, fieldGroup, onSuccess, @extras())
