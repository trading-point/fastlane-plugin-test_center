def testidentifiers_from_xmlreport(report)
  testable = REXML::XPath.first(report, "//section[@id='test-suites']")
  testsuites = REXML::XPath.match(testable, "section[contains(@class, 'test-suite')]")
  testidentifiers = []
  testsuites.each do |testsuite|
    testidentifiers += REXML::XPath.match(testsuite, ".//*[contains(@class, 'tests')]//*[contains(@class, 'test')]//*[contains(@class, 'title')]").map do |testcase|
      "#{testsuite.attribute('id').value}/#{testcase.text.strip}"
    end
  end
  testidentifiers
end

module Fastlane::Actions
  
  html_report_1 = File.open('./spec/fixtures/report.html')
  html_report_2 = File.open('./spec/fixtures/report-2.html')

  atomicboy_ui_testsuite_file = File.read('./spec/fixtures/atomicboy_uitestsuite.html')
  atomicboy_ui_testsuite_file2 = File.read('./spec/fixtures/atomicboy_uitestsuite-2.html')
  atomicboy_ui_testsuite_file3 = File.read('./spec/fixtures/atomicboy_uitestsuite-3.html') 

  describe "CollateHtmlReportsAction" do
    before(:each) do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:open).and_call_original
    end

    describe 'it handles invalid data' do
      it 'a failure occurs when non-existent HTML file is specified' do
        fastfile = "lane :test do
          collate_html_reports(
            reports: ['path/to/non_existent_html_report.html'],
            collated_report: 'path/to/report.html'
          )
        end"
        expect { Fastlane::FastFile.new.parse(fastfile).runner.execute(:test) }.to(
          raise_error(FastlaneCore::Interface::FastlaneError) do |error|
            expect(error.message).to match("Error: HTML report not found: 'path/to/non_existent_html_report.html'")
          end
        )
      end
    end

    describe 'it handles valid data' do
      it 'simply copies a :reports value containing one report' do
        fastfile = "lane :test do
          collate_html_reports(
            reports: ['path/to/fake_html_report.html'],
            collated_report: 'path/to/report.html'
          )
        end"
        allow(File).to receive(:exist?).with('path/to/fake_html_report.html').and_return(true)
        allow(File).to receive(:open).with('path/to/fake_html_report.html').and_yield(File.open('./spec/fixtures/report.html'))
        expect(FileUtils).to receive(:cp).with('path/to/fake_html_report.html', 'path/to/report.html')
        Fastlane::FastFile.new.parse(fastfile).runner.execute(:test)
      end

      skip 'merges missing testsuites into one file' do
        fastfile = "lane :test do
          collate_html_reports(
            reports: ['path/to/fake_html_report_1.html', 'path/to/fake_html_report_2.html'],
            collated_report: 'path/to/report.html'
          )
        end"

        allow(File).to receive(:exist?).with('path/to/fake_html_report_1.html').and_return(true)
        allow(File).to receive(:new).with('path/to/fake_html_report_1.html').and_return(html_report_1)
        allow(File).to receive(:exist?).with('path/to/fake_html_report_2.html').and_return(true)
        allow(File).to receive(:new).with('path/to/fake_html_report_2.html').and_return(html_report_2)
        allow(FileUtils).to receive(:mkdir_p)

        report_file = StringIO.new
        expect(File).to receive(:open).with('path/to/report.html', 'w').and_yield(report_file)

        Fastlane::FastFile.new.parse(fastfile).runner.execute(:test)
        report = REXML::Document.new(report_file.string)
        actual_test_identifiers = testidentifiers_from_xmlreport(report)
        expect(actual_test_identifiers).to contain_exactly(
          'AtomicBoyUITests/testExample',
          'AtomicBoyUITests/testExample2',
          'AtomicBoyUITests.SwiftAtomicBoyUITests/testExample'
        )

        failing_testcases = REXML::XPath.match(report, ".//*[contains(@class, 'tests')]//*[contains(concat(' ', @class, ' '), ' test ') and contains(@class, 'failing')]//*[contains(@class, 'title')]")
        expect(failing_testcases.size).to eq(2)
        failing_testcase = failing_testcases.first
        failing_testclass = REXML::XPath.match(failing_testcase, "ancestor::*/*[contains(@class, 'test-suite')]")[0]
        expect(failing_testclass.attribute('id').value).to eq('AtomicBoyUITests')
        expect(failing_testcase.text.strip).to eq('testExample')

        failing_testcase_details = REXML::XPath.match(report, ".//*[contains(@class, 'tests')]//*[contains(@class, 'details') and contains(@class, 'failing')]")
        expect(failing_testcase_details.size).to eq(2)
        failing_testcase_class = failing_testcase_details[0].attribute('class').value
        expect(failing_testcase_class.split(' ')).to include('testExample')

        test_count = REXML::XPath.first(report, ".//*[@id='test-count']/span").text.strip
        expect(test_count).to eq('3')
        fail_count = REXML::XPath.first(report, ".//*[@id='fail-count']/span").text.strip
        expect(fail_count).to eq('2')

        failing_testsuites = REXML::XPath.match(report, "//*[contains(@class, 'test-suite') and contains(@class, 'failing')]")
        expect(failing_testsuites.size).to eq(1)
        passing_testsuites = REXML::XPath.match(report, "//*[contains(@class, 'test-suite') and contains(@class, 'passing')]")
        expect(passing_testsuites.size).to eq(1)
      end
    end

    describe 'it handles malformed data' do
      it 'fixes and merges malformed html files' do
        malformed_report = File.open('./spec/fixtures/malformed-report.html')
        allow(File).to receive(:exist?).with('path/to/fake_html_report_1.html').and_return(true)
        allow(File).to receive(:new).with('path/to/fake_html_report_1.html').and_return(html_report_1)
        allow(File).to receive(:exist?).with('path/to/malformed-report.html').and_return(true)

        second_reports = [
          malformed_report,
          html_report_1
        ]
        allow(File).to receive(:new).with('path/to/malformed-report.html') do
          second_reports.shift
        end

        expect(Fastlane::Actions::CollateHtmlReportsAction).to receive(:repair_malformed_html).with('path/to/malformed-report.html')
        Fastlane::Actions::CollateHtmlReportsAction.opened_reports(
          [
            'path/to/fake_html_report_1.html',
            'path/to/malformed-report.html'
          ]
        )
      end

      it 'finds and fixes unescaped less-than or greater-than characters' do
        malformed_report = File.open('./spec/fixtures/malformed-report.html')
        allow(File).to receive(:read).with('path/to/malformed-report.html').and_return(malformed_report.read)
        patched_file = StringIO.new
        allow(File).to receive(:open).with('path/to/malformed-report.html', 'w').and_yield(patched_file)
        Fastlane::Actions::CollateHtmlReportsAction.repair_malformed_html('path/to/malformed-report.html')
        expect(patched_file.string).to include('&lt;unknown&gt;')
      end
    end

    describe '#testsuite_testcases' do
      before(:each) do
        @atomicboy_ui_testsuite = REXML::Document.new(atomicboy_ui_testsuite_file)
      end

      it 'retrieves all the testcases' do
        testcases = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite)
        expect(testcases.size).to eq(3)
        onclicks = testcases.map do |testcase|
          testcase.attribute('onclick').value
        end
        expect(onclicks).to include(
          "toggleDetails('testExample17');",
          "toggleDetails('testExample2');",
          "toggleDetails('testExample5');"
        )
      end
    end

    describe "#testcase_title" do
      before(:each) do
        @atomicboy_ui_testsuite = REXML::Document.new(atomicboy_ui_testsuite_file)    
      end

      it 'retrieves the title of each testcase' do
        testcases = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite)
        expected_titles = [
          'testExample17',
          'testExample2',
          'testExample5'
        ]
        actual_titles = testcases.map do |testcase|
          CollateHtmlReportsAction.testcase_title(testcase)
        end
        expect(expected_titles).to eq(actual_titles)
      end
    end

    describe '#merge_testcase_into_testsuite' do
      before(:each) do
        @atomicboy_ui_testsuite = REXML::Document.new(atomicboy_ui_testsuite_file).root
        @atomicboy_ui_testsuite2 = REXML::Document.new(atomicboy_ui_testsuite_file2).root
        @atomicboy_ui_testsuite3 = REXML::Document.new(atomicboy_ui_testsuite_file3).root      
      end


      it 'replaces an existing testcase with the new testcase' do
        testcases2 = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite2)
        testcases2.each do |testcase|
          CollateHtmlReportsAction.merge_testcase_into_testsuite(testcase, @atomicboy_ui_testsuite, false)
        end
        testcases = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite)
        expect(testcases.size).to eq(3)
        teststatuses = testcases.map do |testcase|
          m = testcase.attribute('class').value.match(/\b(?<status>failing|passing)\b/)
          m[:status]
        end
        expect(teststatuses).to eq(%w[passing passing passing])
      end

      it 'adds the testcase into a testsuite that does not have the testcase' do
        testcases3 = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite3)
        testcases3.each do |testcase|
          CollateHtmlReportsAction.merge_testcase_into_testsuite(testcase, @atomicboy_ui_testsuite, false)
        end
        testcases = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite)
        expect(testcases.size).to eq(4)
        teststatuses = testcases.map do |testcase|
          m = testcase.attribute('class').value.match(/\b(?<status>failing|passing)\b/)
          m[:status]
        end
        expect(teststatuses).to eq(%w[failing passing passing passing])
      end

      skip 'removes pre-existing failure details for a failing test when replaced with a passing version of the same test' do
        
      end

      skip 'adds the failure details for a new failing test'

      it 'updates the row coloring of the testsuite for testcase replacement' do
        testcases2 = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite2)
        testcases2.each do |testcase|
          CollateHtmlReportsAction.merge_testcase_into_testsuite(testcase, @atomicboy_ui_testsuite, true)
        end
        testcases = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite)
        teststatuses = testcases.each_with_index.map do |testcase, index|
          even_expected = (index % 2).zero?
          m = testcase.attribute('class').value.match(/\bodd\b/)
          if even_expected
            expect(m).to be_nil
          else
            expect(m).not_to be_nil
          end
        end
      end

      it 'updates the row coloring of the testsuite for testcase addition' do
        testcases3 = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite3)
        testcases3.each do |testcase|
          CollateHtmlReportsAction.merge_testcase_into_testsuite(testcase, @atomicboy_ui_testsuite, true)
        end
        testcases = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite)
        teststatuses = testcases.each_with_index.map do |testcase, index|
          even_expected = (index % 2).zero?
          m = testcase.attribute('class').value.match(/\bodd\b/)
          if even_expected
            expect(m).to be_nil, "testcase row #{index + 1} coloring was odd when it was expected to be even"
          else
            expect(m).not_to be_nil, "testcase row #{index + 1} coloring was even when it was expected to be odd"
          end
        end
      end
      it 'updates the overall testsuite passing status' do
        testcases2 = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite2)
        testcases2.each do |testcase|
          CollateHtmlReportsAction.merge_testcase_into_testsuite(testcase, @atomicboy_ui_testsuite, true)
        end
        testsuite_passing = @atomicboy_ui_testsuite.attribute('class').value.match(/\bpassing\b/) != nil
        expect(testsuite_passing).to eq(true)
      end

      it 'updates the overall testsuite failing status' do
        testcases3 = CollateHtmlReportsAction.testsuite_testcases(@atomicboy_ui_testsuite3)
        testcases3.each do |testcase|
          CollateHtmlReportsAction.merge_testcase_into_testsuite(testcase, @atomicboy_ui_testsuite, true)
        end
        testsuite_failing = @atomicboy_ui_testsuite.attribute('class').value.match(/\bfailing\b/) != nil
        expect(testsuite_failing).to eq(true)
      end
    end

    describe '#merge_testsuite_into_testsuite' do
      skip 'replaces failing tests when they have passed'
      skip 'replaces failing tests with newer failing tests'
      skip 'removes failure details for tests that have later passed'
      skip 'adds failure details for tests that did not appear in the first testsuite'
    end
  end
end
