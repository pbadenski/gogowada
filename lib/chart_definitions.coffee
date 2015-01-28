module.exports =
  pie:
    type: "pieChart"
    customize: (chart, fieldGroup, onSuccess) ->
      chart
        .width(200)
        .height(200)
      onSuccess(chart)
  donut:
    type: "pieChart"
    customize: (chart, fieldGroup, onSuccess) ->
      chart
        .width(200)
        .height(200)
        .innerRadius(40)
      onSuccess(chart)
   bar:
    type: "barChart"
    customize: (chart, fieldGroup, onSuccess) ->
      chart
        .x(d3.scale.linear().domain([
          _.min(_.pluck(fieldGroup.all(), "key")) * 0.8,
          _.max(_.pluck(fieldGroup.all(), "key")) * 1.2
        ]))
        .centerBar(true)
        .elasticY(true)
        .xAxis().tickFormat(d3.format("s"))
      onSuccess(chart)
  line:
    type: "lineChart"
    customize: (chart, fieldGroup, onSuccess) ->
      sampleElement = _.min(_.pluck(fieldGroup.all(), "key"))
      date =
        scale: d3.time.scale().domain([
          _.min(_.pluck(fieldGroup.all(), "key")),
          _.max(_.pluck(fieldGroup.all(), "key"))
      ])
        tickFormat: d3.time.format "%Y-%m-%d"
      number =
        scale: d3.scale.linear().domain([
          _.min(_.pluck(fieldGroup.all(), "key")) * 0.8,
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
  row:
    type: "rowChart"
    customize: (chart, fieldGroup, onSuccess) ->
      chart
        .height () -> 25 * (chart.group().all().length + 1)
        .xAxis().tickFormat(d3.format("s"))
      onSuccess(chart)
  choropleth:
    type: "leafletChoroplethChart"
    customize: (chart, fieldGroup, onSuccess, extras) ->
      d3.json extras.geojson, (geojson) =>
        chart
          .center([41.83, -87.68])
          .zoom(10)
          .geojson(geojson)
          .featureKeyAccessor(extras.featureKeyAccessor)
        onSuccess(chart)
  "markers on the map":
    type: "leafletMarkerChart"
    customize: (chart, fieldGroup, onSuccess, extras) ->
      chart
        .center([41.83, -87.68])
        .zoom(10)
      onSuccess(chart)
  "clustered markers on the map":
    type: "leafletMarkerChart"
    customize: (chart, fieldGroup, onSuccess, extras) ->
      chart
        .center([41.83, -87.68])
        .cluster(true)
        .zoom(10)
      onSuccess(chart)
