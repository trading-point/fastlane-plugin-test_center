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
    end
  end
end