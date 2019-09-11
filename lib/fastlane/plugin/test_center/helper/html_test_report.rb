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

        def add_testsuite(testsuite)
          testsuites_element = REXML::XPath.first(@root, ".//*[@id='test-suites']")
          testsuites_element.push(testsuite.root)
        end

        def collate_report(report)
          report.testsuites.each do |given_testsuite|
            existing_testsuite = testsuite_with_title(given_testsuite.title)
            if existing_testsuite.nil?
              add_testsuite(given_testsuite)
            else
              existing_testsuite.collate_testsuite(given_testsuite)
            end
          end
        end

        def testsuite_with_title(title)
          testsuite_element = REXML::XPath.first(@root, ".//*[contains(@id, 'test-suites')]//*[@id='#{title}' and contains(concat(' ', @class, ' '), ' test-suite ')]")
          TestSuite.new(testsuite_element) unless testsuite_element.nil?
        end
      end

      class TestSuite
        attr_reader :root

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
            TestCase.new(testcase_element)
          end
        end

        def testcase_with_title(title)
          testcase_element = REXML::XPath.first(@root, ".//*[contains(@class, 'tests')]//*[contains(concat(' ', @class, ' '), ' test ')]//*[text()='#{title}']/../..")
          TestCase.new(testcase_element) unless testcase_element.nil?
        end

        def passing?
          @root.attribute('class').value.include?('passing')
        end

        def set_passing(status)
          desired_status = status ? ' passing ' : ' failing '
          to_replace = status ? /\bfailing\b/ : /\bpassing\b/
  
          attribute = @root.attribute('class').value.sub(to_replace, desired_status)
          attribute.gsub!(/\s{2,}/, ' ')
          @root.add_attribute('class', attribute)  
        end

        def add_testcase(testcase)
          tests_table = REXML::XPath.first(@root, ".//*[contains(@class, 'tests')]/table")
          tests_table.push(testcase.root)
        end

        def collate_testsuite(testsuite)
          given_testcases = testsuite.testcases
          given_testcases.each do |given_testcase|
            existing_testcase = testcase_with_title(given_testcase.title)
            if existing_testcase.nil?
              add_testcase(given_testcase)
            else
              existing_testcase.update_testcase(given_testcase)
            end
          end
          set_passing(testcases.all?(&:passing?))
        end
      end

      class TestCase
        attr_reader :root

        def initialize(testcase_element)
          @root = testcase_element
        end

        def title
          REXML::XPath.first(@root, ".//h3[contains(@class, 'title')]/text()").to_s
        end

        def passing?
          @root.attribute('class').value.include?('passing')
        end

        def row_color
          @root.attribute('class').value.include?('odd') ? 'odd' : ''
        end

        def set_row_color(row_color)
          raise 'row_color must either be "odd" or ""' unless ['odd', ''].include?(row_color)

          current_class_attribute = @root.attribute('class').value.sub(/\bodd\b/, '')
          @root.add_attribute('class', current_class_attribute << ' ' << row_color)
        end

        def failure_details
          return '' if @root.attribute('class').value.include?('passing')

          xpath_class_attributes = [
            "contains(concat(' ', @class, ' '), ' details ')",
            "contains(concat(' ', @class, ' '), ' failing ')",
            "contains(concat(' ', @class, ' '), ' #{title} ')"
          ].join(' and ')
          
          REXML::XPath.first(@root.parent, "//[#{xpath_class_attributes}]")
        end

        def update_testcase(testcase)
          color = row_color
          failure = failure_details
          parent = @root.parent
          unless failure.kind_of?(String)
            parent.delete(failure)
          end
          new_failure = testcase.failure_details
          unless new_failure.kind_of?(String)
            parent.insert_after(@root, new_failure)
          end
          parent.replace_child(@root, testcase.root)
          @root = testcase.root
          set_row_color(color)
        end
      end
    end
  end
end
