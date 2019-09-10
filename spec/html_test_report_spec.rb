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

      skip '#collate_testsuite' do
        it 'merges the given testsuite with an existing testsuite' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))

          html_report2 = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report-2.html'))))
          testsuites = html_report2.testsuites
          atomic_boy_ui_swift_testsuite = testsuites[0]
          html_report.collate_testsuite(atomic_boy_ui_swift_testsuite)
          testcases = []
          html_report.testsuites.each do |testsuite|
            testsuite.testcases.each do |testcase|
              testcases << testcase
            end
          end
          testcase_titles = testcases.map(&:title)
          expect(testcase_titles).to eq(
            []
          )
        end

        it 'adds the given testsuite to the report when it didn\'t previously exist' do
        end
      end

      skip '#collate_report' do
        it 'merges two reports with same testsuites' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))

          html_report2 = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report-2.html'))))
          html_report.collate_report(html_report2)
          expect(html_report.testsuites.size).to eq(2)
          testsuite_1 = html_report.testsuites[0]
          testsuite_2 = html_report.testsuites[1]
          expect(testsuite_1.testcases.size).to eq(2)
          expect(testsuite_2.testcases.size).to eq(1)
          expect(testsuite_2.passing?).to eq(true)
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

      describe '#passing?' do
        it 'returns true when all testcases have passed' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite-2.html'))))
          atomic_boy_testsuite = html_report.testsuites[0]
          expect(atomic_boy_testsuite.passing?).to eq(true)
        end

        it 'returns false when not all testcases have passed' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_testsuite = html_report.testsuites[0]
          expect(atomic_boy_testsuite.passing?).to eq(false)
        end
      end

      describe '#set_passing' do
        it 'sets failing testsuite to passing' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_testsuite = html_report.testsuites[0]
          atomic_boy_testsuite.set_passing(true)
          expect(atomic_boy_testsuite.passing?).to eq(true)
        end

        it 'sets passing testsuite to failing' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite-2.html'))))
          atomic_boy_testsuite = html_report.testsuites[0]
          atomic_boy_testsuite.set_passing(false)
          expect(atomic_boy_testsuite.passing?).to eq(false)
        end
      end

      describe '#testcase_with_title' do
        it 'returns an existing testcase that has the given title' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_testsuite = html_report.testsuites[0]
          testcase = atomic_boy_testsuite.testcase_with_title('testExample2')
          expect(testcase).not_to be(nil)
          expect(testcase.row_color).to eq('odd')
          expect(testcase.passing?).to eq(true)
        end

        it 'returns nil for a testcase that does not exist in the testsuite' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_testsuite = html_report.testsuites[0]
          testcase = atomic_boy_testsuite.testcase_with_title('testExample98')
          expect(testcase).to be(nil)
        end
      end

      describe '#add_testcase' do
        it 'adds the given testcase' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_testsuite = html_report.testsuites[0]

          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite-4.html'))))
          testcase_99 = html_report.testsuites[0].testcase_with_title('testExample99')
          atomic_boy_testsuite.add_testcase(testcase_99)
          testcases = atomic_boy_testsuite.testcases
          expect(testcases.size).to eq(4)
          expect(atomic_boy_testsuite.testcase_with_title('testExample99')).not_to be(nil)
        end
      end

      describe '#collate_testsuite' do
        it 'replaces failing testcases with passing testcases' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_failing_testsuite = html_report.testsuites[0]

          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite-2.html'))))
          atomic_boy_passing_testsuite = html_report.testsuites[0]

          atomic_boy_failing_testsuite.collate_testsuite(atomic_boy_passing_testsuite)
          testcases = atomic_boy_failing_testsuite.testcases
          passing_statuses = testcases.map(&:passing?)
          expect(passing_statuses).to eq(
            [
              true,
              true,
              true
            ]
          )
        end

        it 'adds new testcases to testsuite' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_failing_testsuite = html_report.testsuites[0]

          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite-4.html'))))
          atomic_boy_passing_testsuite = html_report.testsuites[0]
          atomic_boy_failing_testsuite.collate_testsuite(atomic_boy_passing_testsuite)
          testcases = atomic_boy_failing_testsuite.testcases
          passing_statuses = testcases.map(&:passing?)
          expect(passing_statuses).to eq(
            [
              false,
              true,
              true,
              false
            ]
          )
        end

        it 'updates the testsuite\'s passing status' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_failing_testsuite = html_report.testsuites[0]

          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite-2.html'))))
          atomic_boy_passing_testsuite = html_report.testsuites[0]

          atomic_boy_failing_testsuite.collate_testsuite(atomic_boy_passing_testsuite)
          expect(atomic_boy_failing_testsuite.passing?).to eq(true)
        end

        it 'updates the testsuite\'s failing status' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite-2.html'))))
          atomic_boy_passing_testsuite = html_report.testsuites[0]

          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          atomic_boy_failing_testsuite = html_report.testsuites[0]

          atomic_boy_passing_testsuite.collate_testsuite(atomic_boy_failing_testsuite)
          expect(atomic_boy_failing_testsuite.passing?).to eq(false)
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

      describe '#passing?' do
        it 'returns true when testcase is passing' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/atomicboy_uitestsuite.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_testcases = testsuites[0].testcases
          passing_statuses = atomic_boy_ui_testcases.map(&:passing?)
          expect(passing_statuses).to eq(
            [
              false,
              true,
              true
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
      
      describe '#update_testcase' do
        it 'replaces a failing testcase with a passing test case' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_failing_testcase = testsuites[1].testcases[0]

          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report-2.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_swift_passing_testcase = testsuites[0].testcases[0]

          atomic_boy_ui_failing_testcase.update_testcase(atomic_boy_ui_swift_passing_testcase)
          expect(atomic_boy_ui_failing_testcase.failure_details).to eq('')
        end

        it 'replaces a passing test case with a failing test case' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_failing_testcase = testsuites[1].testcases[0]

          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report-2.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_swift_passing_testcase = testsuites[0].testcases[0]

          atomic_boy_ui_swift_passing_testcase.update_testcase(atomic_boy_ui_failing_testcase)
          failure_details = atomic_boy_ui_swift_passing_testcase.failure_details
          failure_reason = REXML::XPath.first(failure_details, "//[contains(@class, 'reason')]/text()").to_s
          expect(failure_reason).to eq('((false) is true) failed')
          failure_location = REXML::XPath.first(failure_details, "//[@class = 'test-detail']/text()").to_s
          expect(failure_location).to eq('AtomicBoyUITests.m:40')
        end

        it 'matches the previous row color' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_failing_testcase = testsuites[1].testcases[0]
          atomic_boy_ui_failing_testcase.set_row_color('odd')
          
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report-2.html'))))
          testsuites = html_report.testsuites
          atomic_boy_ui_swift_passing_testcase = testsuites[0].testcases[0]

          atomic_boy_ui_failing_testcase.update_testcase(atomic_boy_ui_swift_passing_testcase)
          expect(atomic_boy_ui_failing_testcase.row_color).to eq('odd')
        end
      end
    end
  end
end