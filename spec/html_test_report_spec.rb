module TestCenter::Helper::HtmlTestReport
  describe 'HtmlTestReport' do
    describe '#Report' do
      describe '#testsuites' do
        it 'returns the correct testsuites' do
          html_report = Report.new(REXML::Document.new(File.new(File.open('./spec/fixtures/report.html'))))
          testsuites = html_report.testsuites
          expect(testsuites.size).to eq(2)
        end
      end
    end
  end
end