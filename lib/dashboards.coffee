module.exports =
  chicago_affordable_housing:
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
  chicago_employees:
    src: "https://data.cityofchicago.org/resource/xzkq-xp2w.json?$limit=50000",
    derivedProperties: [
      {
        name: "employee_salary_range"
        f: (d) ->
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
    ]
    charts: [
      {
        chartType: "pieChart"
        dimension: "employee_salary_range"
      }
      {
        chartType: "rowChart"
        dimension: "department"
      }
    ]
