module TestCenter
  module Helper
    module HtmlTestReport
      class Report
        def initialize(html_file)
          @root = html_file.root
        end

        def testsuites
          testsuite_elements = REXML::XPath.match(@root, "//section[contains(@class, 'test-suite')]")
          testsuite_elements.map do |testsuite_element|
            TestSuite.new(testsuite_element)
          end
        end
      end

      class TestSuite
        def initialize(testsuite_element)
          @root = testsuite_element
        end

        def title
          @root.attribute('id').value
        end

        def testcases
          testcase_failure_xpath = [
            "contains(concat(' ', @class, ' '), ' details ')",
            "contains(concat(' ', @class, ' '), ' failing ')"
          ].join(' and ')

          failure_details_elements = REXML::XPath.match(@root, "//[#{testcase_failure_xpath}]")

          testcase_elements = REXML::XPath.match(@root, ".//*[contains(@class, 'tests')]//*[contains(concat(' ', @class, ' '), ' test ')]")
          testcase_elements.map do |testcase_element|
            testcase = TestCase.new(testcase_element)
            title = testcase.title
            failure_details_element = failure_details_elements.find do |failure_element|
              failure_element.attribute('class').value.include?(title)
            end

            testcase.add_failure_details(failure_details_element)
            testcase
          end
        end
      end

      class TestCase
        def initialize(testcase_element)
          @root = testcase_element
        end

        def title
          REXML::XPath.first(@root, ".//h3[contains(@class, 'title')]/text()").to_s
        end

        def row_color
          @root.attribute('class').value.include?('odd') ? 'odd' : ''
        end

        def set_row_color(row_color)
          raise 'row_color must either be "odd" or ""' unless ['odd', ''].include?(row_color)

          current_class_attribute = @root.attribute('class').value.sub(/\bodd\b/, '')
          @root.add_attribute('class', current_class_attribute << ' ' << row_color)
        end

        def add_failure_details(failure_details_element)
          @failure_details_element = failure_details_element.clone
        end
      end
    end
  end
end
