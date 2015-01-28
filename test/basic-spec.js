describe('angularjs homepage todo list', function() {
  beforeEach(function() {
    var matchers = {
      toBeEmpty: function() {
        this.message = function() {
          return "Expected array to be empty, but got: " + require('util').inspect(this.actual);  
        };
        
        return this.actual.size == 0;  
      }
    };

    this.addMatchers(matchers);
  });
  afterEach(function() {
      browser.manage().logs().get('browser').then(function(browserLog) {
        expect(browserLog).toBeEmpty();
      });
  });
  it('should add a todo', function() {
    browser.get('http://localhost:8000');

    element(by.id('set-json-file-input')).sendKeys('http://localhost:8000/test.json');
    element(by.id('set-json-file-button')).click();

    expect(element(by.id("add-graph")).isPresent()).toBe(true);
    browser.wait(function () {
      return browser.isElementPresent(by.css(".dc-data-count"));
    }, 5000);

    element(by.id("add-graph")).click();
    expect(element(by.id("chartTypeSelect")).all(by.tagName("option")).getAttribute("value"))
      .toEqual(['-- Select chart', 'bar', 'clustered markers on the map', 'donut', 'line', 'markers on the map', 'pie', 'row']);
    expect(element(by.id("propertySelect")).all(by.tagName("option")).getAttribute("value"))
      .toEqual(['', 'address', 'community_area', 'community_area_number', 'latitude', 'location', 'longitude', 'management_company', 'phone_number', 'property_name', 'property_type', 'units', 'x_coordinate', 'y_coordinate', 'zip_code' ]);
    expect(element(by.id("groupByFunctionSelect")).all(by.tagName("option")).getAttribute("value"))
      .toEqual(['', 'count', 'average', 'sum']);
    expect(element(by.id("groupByPropertySelect")).all(by.tagName("option")).getAttribute("value"))
      .toEqual(['', 'address', 'community_area', 'community_area_number', 'latitude', 'location', 'longitude', 'management_company', 'phone_number', 'property_name', 'property_type', 'units', 'x_coordinate', 'y_coordinate', 'zip_code' ]);

    element(by.id("chartTypeSelect")).element(by.css("[value='row']")).click();
    element(by.id("propertySelect")).element(by.css("[value='property_type']")).click();
    expect(element(by.css(".gridster svg")).isPresent()).toBe(true);
    element(by.id("chartTypeSelect")).element(by.css("[value='pie']")).click();
    element(by.css(".gridster .widget-remove")).click();

    element(by.id("add-graph")).click();
    element(by.id("chartTypeSelect")).element(by.css("[value='bar']")).click();
    element(by.id("propertySelect")).element(by.css("[value='units']")).click();
    expect(element(by.css(".gridster svg")).isPresent()).toBe(true);

  });
});

