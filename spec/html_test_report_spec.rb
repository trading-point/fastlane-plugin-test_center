module TestCenter::Helper::HtmlTestReport
  describe 'HtmlTestReport' do
    describe 'Report' do
      describe '#testsuites' do
        it 'returns the correct number of testsuites' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          expect(testsuites.size).to eq(2)
        end
      end
    end

    describe 'TestSuite' do
      describe '#title' do
        it 'returns the correct title' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          expect(testsuites[0].title).to eq("AtomicBoyUITests")
          expect(testsuites[1].title).to eq("AtomicBoyUITests.SwiftAtomicBoyUITests")
        end
      end

      describe '#testcases' do
        it 'returns the correct number of testcases' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_testcases = testsuites[0].testcases
          expect(atomic_boy_ui_testcases.size).to eq(2)
          atomic_boy_ui_swift_testcases = testsuites[1].testcases
          expect(atomic_boy_ui_swift_testcases.size).to eq(1)
        end
      end
    end

    describe 'TestCase' do
      describe '#title' do
        it 'returns the correct title' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_testcases = testsuites[0].testcases
          testcases_titles = atomic_boy_ui_testcases.map(&:title)
          expect(testcases_titles).to eq(
            [
              "testExample",
              "testExample2"
            ]
          )
        end
      end

      describe '#row_color' do
        it 'returns the correct row colors' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_testcases = testsuites[0].testcases
          testcase_row_colors = atomic_boy_ui_testcases.map(&:row_color)
          expect(testcase_row_colors).to eq(
            [
              '',
              'odd'
            ]
          )
        end
      end

      describe '#set_row_color' do
        it 'correctly sets an even row_color' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_testcase2 = testsuites[0].testcases[1]
          atomic_boy_ui_testcase2.set_row_color('')
          expect(atomic_boy_ui_testcase2.row_color).to eq('')
        end

        it 'correctly sets an odd row_color' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_testcase1 = testsuites[0].testcases[0]
          atomic_boy_ui_testcase1.set_row_color('odd')
          expect(atomic_boy_ui_testcase1.row_color).to eq('odd')
        end

        it 'throws an error if set to an invalid color' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_testcase1 = testsuites[0].testcases[0]
          expect { atomic_boy_ui_testcase1.set_row_color('invalid') }
            .to raise_error('row_color must either be "odd" or ""')
        end
      end

      describe '#failure_details' do
        it 'returns an empty string for a passing testcase' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report-2.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_swift_testcase1 = testsuites[0].testcases[0]
          expect(atomic_boy_ui_swift_testcase1.failure_details).to eq('')
        end

        it 'returns the failure details for a failing test' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_testcase1 = testsuites[0].testcases[0]
          failure_details = atomic_boy_ui_testcase1.failure_details
          failure_reason = REXML::XPath.first(failure_details, "//[contains(@class, 'reason')]/text()").to_s
          expect(failure_reason).to eq('((false) is true) failed')
          failure_location = REXML::XPath.first(failure_details, "//[@class = 'test-detail']/text()").to_s
          expect(failure_location).to eq('AtomicBoyUITests.m:40')
        end
      end 
    end
  end
end