require "rails_helper"

describe "creating datasets" do
  let(:land) { FactoryBot.create(:organisation, name: 'land-registry', title: 'Land Registry') }
  let!(:user) { FactoryBot.create(:user, primary_organisation: land) }
  let!(:dataset) { FactoryBot.create(:dataset, organisation: land, creator: user) }
  let!(:topic) { FactoryBot.create(:topic) }

  context "when the user goes through entire flow" do
    before(:each) do
      sign_in_as(user)
    end

    it "navigates to new dataset form" do
      click_link "Manage datasets"
      click_link "Create a dataset"
      expect(page).to have_current_path("/datasets/new")
      expect(page).to have_content("Create a dataset")
    end

    it "publishes a dataset" do
      visit new_dataset_path

      # PAGE 1: New
      fill_in "dataset[title]", with: "my test dataset"
      fill_in "dataset[summary]", with: "my test dataset summary"
      fill_in "dataset[description]", with: "my test dataset description"
      click_button "Save and continue"

      expect(Dataset.where(title: "my test dataset").size).to eq(1)

      # PAGE 2: Topic
      choose option: topic.id
      click_button "Save and continue"

      expect(Dataset.last.topic.title).to eq(topic.title)

      # PAGE 3: Licence
      choose option: "uk-ogl"
      click_button "Save and continue"

      expect(Dataset.last.licence_code).to eq("uk-ogl")

      # Page 4: Location
      fill_in "dataset[location1]", with: "Aviation House"
      fill_in "dataset[location2]", with: "London"
      fill_in "dataset[location3]", with: "England"
      click_button "Save and continue"

      expect(Dataset.last.location1).to eq("Aviation House")
      expect(Dataset.last.location2).to eq("London")
      expect(Dataset.last.location3).to eq("England")

      # Page 5: Frequency
      choose option: "never"
      click_button "Save and continue"

      expect(Dataset.last.frequency).to eq("never")

      # Page 6: Add Link
      fill_in 'datafile[url]', with: 'https://localhost'
      fill_in 'datafile[name]', with: 'my test datafile'
      click_button "Save and continue"

      expect(Dataset.last.datafiles.size).to eq(1)
      expect(Dataset.last.datafiles.last.url).to eq('https://localhost')
      expect(Dataset.last.datafiles.last.name).to eq('my test datafile')

      # Files page
      expect(page).to have_content("Links to your data")
      expect(page).to have_content("my test datafile")
      click_link "Save and continue"

      # Page 7: Add Documents
      fill_in 'doc[url]', with: 'https://localhost/doc'
      fill_in 'doc[name]', with: 'my test doc'
      click_button "Save and continue"

      expect(Dataset.last.docs.size).to eq(1)
      expect(Dataset.last.docs.last.url).to eq('https://localhost/doc')
      expect(Dataset.last.docs.last.name).to eq('my test doc')
      expect(Dataset.last.status).to eq("draft")

      # Documents page
      expect(page).to have_content("Links to supporting documents")
      expect(page).to have_content("my test doc")
      click_link "Save and continue"

      # Page 8: Publish Page
      expect(Dataset.last.published?).to be(false)

      expect(page).to have_content(Dataset.last.status)
      expect(page).to have_content(Dataset.last.organisation.title)
      expect(page).to have_content(Dataset.last.title)
      expect(page).to have_content(Dataset.last.summary)
      expect(page).to have_content(Dataset.last.description)
      expect(page).to have_content(Dataset.last.topic.title)
      expect(page).to have_content("Open Government Licence")
      expect(page).to have_content(Dataset.last.location1)
      expect(page).to have_content("One-off")
      expect(page).to have_content(Dataset.last.datafiles.first.name)
      expect(page).to have_content(Dataset.last.datafiles.last.name)

      click_button "Publish"

      expect(page).to have_content("Your dataset has been published")
      expect(Dataset.last.published?).to be(true)
    end
  end

  context "when the user doesn't complete flow" do
    before(:each) do
      sign_in_as(user)
    end

    it "saves a draft" do
      visit new_dataset_path
      fill_in "dataset[title]", with: "my test dataset"
      fill_in "dataset[summary]", with: "my test dataset summary"
      fill_in "dataset[description]", with: "my test dataset description"
      click_button "Save and continue"

      expect(Dataset.where(title: "my test dataset").size).to eq(1)
      expect(Dataset.find_by(title: "my test dataset").creator_id).to eq(user.id)
    end

    it 'displays drafts' do
      click_link 'Manage datasets'
      expect(page).to have_content(dataset.title)

      visit dataset_path(dataset.uuid, dataset.name)
      expect(page).to have_content(dataset.title)
    end
  end
end

describe "starting a new draft with invalid inputs" do
  let(:land) { FactoryBot.create(:organisation, name: 'land-registry', title: 'Land Registry') }
  let!(:user) { FactoryBot.create(:user, primary_organisation: land) }
  let!(:topic) { FactoryBot.create(:topic) }

  before(:each) do
    url = "https://test.data.gov.uk/api/3/action/package_patch"
    stub_request(:any, url).to_return(status: 200)
    sign_in_as(user)
    visit new_dataset_path
  end

  it "missing title" do
    fill_in "dataset[summary]", with: "my test dataset summary"
    click_button "Save and continue"
    expect(page).to have_content("There was a problem")
    expect(page).to have_content("Please enter a valid title", count: 2)
    expect(page).to have_selector("div", class: "form-group-error")
    expect(Dataset.where(title: "my test dataset").size).to eq(0)
    # recover
    fill_in "dataset[title]", with: "my test dataset"
    fill_in "dataset[summary]", with: "my test dataset summary"
    fill_in "dataset[description]", with: "my test dataset description"
    click_button "Save and continue"
    expect(page).to have_content("Choose a topic")
  end

  it "missing summary" do
    fill_in "dataset[title]", with: "my test dataset"
    click_button "Save and continue"
    expect(page).to have_content("There was a problem")
    expect(page).to have_content("Please provide a summary", count: 2)
    expect(page).to have_selector("div", class: "form-group-error")
    expect(Dataset.where(title: "my test dataset").size).to eq(0)
    # recover
    fill_in "dataset[title]", with: "my test dataset"
    fill_in "dataset[summary]", with: "my test dataset summary"
    fill_in "dataset[description]", with: "my test dataset description"
    click_button "Save and continue"
    expect(page).to have_content("Choose a topic")
  end

  it "missing both title and summary" do
    click_button "Save and continue"
    expect(page).to have_content("There was a problem")
    expect(page).to have_content("Please enter a valid title", count: 2)
    expect(page).to have_content("Please provide a summary", count: 2)
    expect(Dataset.where(title: "my test dataset").size).to eq(0)
    # recover
    fill_in "dataset[title]", with: "my test dataset"
    fill_in "dataset[summary]", with: "my test dataset summary"
    fill_in "dataset[description]", with: "my test dataset description"
    click_button "Save and continue"
    expect(page).to have_content("Choose a topic")
  end
end

describe "valid options for topic, licence and area" do
  let(:land_registry) { FactoryBot.create(:organisation, name: 'land-registry', title: 'Land Registry') }
  let!(:user) { FactoryBot.create(:user, primary_organisation: land_registry) }
  let!(:topic) { FactoryBot.create(:topic) }

  before(:each) do
    url = "https://test.data.gov.uk/api/3/action/package_patch"
    stub_request(:any, url).to_return(status: 200)
    sign_in_as(user)
    visit new_dataset_path
    fill_in "dataset[title]", with: "my test dataset"
    fill_in "dataset[summary]", with: "my test dataset summary"
    fill_in "dataset[description]", with: "my test dataset description"
    click_button "Save and continue"
  end

  context "when selecting topic type" do
    it "if missing, throw error" do
      click_button "Save and continue"
      expect(page).to have_content("Please choose a topic")
    end
  end

  context "when selecting license type" do
    before(:each) do
      choose option: topic.id
      click_button "Save and continue"
    end

    it "OGL" do
      expect(page).to have_content("Choose a licence")
      choose option: "uk-ogl"
      click_button "Save and continue"
      expect(page).to have_content("Choose a geographical area")
    end

    it "if missing, throw error" do
      click_button "Save and continue"
      expect(page).to have_content("Please select a licence for your dataset")
    end
  end

  context "when selecting geographical area" do
    before(:each) do
      url = "https://test.data.gov.uk/api/3/action/package_patch"
      stub_request(:any, url).to_return(status: 200)
      choose option: topic.id
      click_button "Save and continue"
      choose option: "uk-ogl"
      click_button "Save and continue"
    end

    it "allows entering a geographical area" do
      fill_in "dataset[location1]", with: "High Wycombe"
      click_button "Save and continue"
      expect(page).to have_content("How frequently is this dataset updated?")
    end

    it "allows not entering a geographical area" do
      click_button "Save and continue"
      expect(page).to have_content("How frequently is this dataset updated?")
    end
  end
end

describe "dataset frequency options" do
  let(:land) { FactoryBot.create(:organisation, name: 'land-registry', title: 'Land Registry') }
  let!(:user) { FactoryBot.create(:user, primary_organisation: land) }
  let!(:dataset) { FactoryBot.create(:dataset, organisation: land) }

  before(:each) do
    url = "https://test.data.gov.uk/api/3/action/package_patch"
    stub_request(:any, url).to_return(status: 200)
    sign_in_as(user)
    visit new_dataset_frequency_path(dataset.uuid, dataset.name)
  end

  context "when Never" do
    it "selecting NEVER hides fields and dates" do
      choose option: 'never'
      click_button "Save and continue"

      expect(page).to_not have_content('Year')

      fill_in 'datafile[url]', with: 'https://localhost/doc'
      fill_in 'datafile[name]', with: 'my test doc'
      click_button "Save and continue"

      expect(Dataset.last.links.last.end_date).to be_nil
    end
  end

  context "when DAILY" do
    before(:each) do
      url = "https://test.data.gov.uk/api/3/action/package_patch"
      stub_request(:any, url).to_return(status: 200)
      choose option: 'daily'
      click_button "Save and continue"
      fill_in 'datafile[url]', with: 'https://localhost/doc'
      fill_in 'datafile[name]', with: 'my test doc'
    end

    it "shows date fields and sets end date" do
      expect(page).to     have_content('Month')
      expect(page).to     have_content('Year')

      fill_in "datafile[day]", with: '15'
      fill_in 'datafile[month]', with: '1'
      fill_in 'datafile[year]',  with: '2020'

      click_button "Save and continue"

      expect(Dataset.last.datafiles.last.end_date).to eq(Date.new(2020, 1, 15))
    end

    it "displays errors when dates aren't entered" do
      click_button "Save and continue"

      expect(page).to have_content("There was a problem")
      expect(page).to have_content("Please enter a valid date", count: 2)
      expect(page).to have_content("Please enter a valid month", count: 2)
      expect(page).to have_content("Please enter a valid year", count: 2)
    end
  end

  context "when MONTHLY" do
    before(:each) do
      url = "https://test.data.gov.uk/api/3/action/package_patch"
      stub_request(:any, url).to_return(status: 200)
      choose option: 'monthly'
      click_button "Save and continue"
      fill_in 'datafile[url]', with: 'https://localhost/doc'
      fill_in 'datafile[name]', with: 'my test doc'
    end

    it "shows date fields and sets end date" do
      expect(page).to     have_content('Month')
      expect(page).to     have_content('Year')

      fill_in 'datafile[month]', with: '1'
      fill_in 'datafile[year]',  with: '2020'

      click_button "Save and continue"

      expect(Dataset.last.links.last.end_date).to eq(Date.new(2020, 1).end_of_month)
    end

    it "displays errors when dates aren't entered" do
      click_button "Save and continue"

      expect(page).to have_content("There was a problem")
      expect(page).to have_content("Please enter a valid month")
      expect(page).to have_content("Please enter a valid year")
    end
  end

  context "when QUARTERLY" do
    before(:each) do
      url = "https://test.data.gov.uk/api/3/action/package_patch"
      stub_request(:any, url).to_return(status: 200)
      choose option: 'quarterly'
      click_button "Save and continue"
    end

    def pick_quarter(quarter)
      expect(page).to     have_content('Year')
      expect(page).to     have_content('Quarter')
      fill_in 'datafile[url]', with: 'https://localhost/doc'
      fill_in 'datafile[name]', with: 'my test doc'
      choose option: quarter.to_s
      fill_in "datafile[year]", with: Time.zone.today.year
      click_button "Save and continue"
    end

    it "calculates correct dates for Q1" do
      pick_quarter(1)
      expect(Dataset.last.datafiles.last.end_date).to eq(Date.new(Time.zone.today.year, 6).end_of_month)
    end

    it "calculates correct dates for Q2" do
      pick_quarter(2)
      expect(Dataset.last.datafiles.last.end_date).to eq(Date.new(Time.zone.today.year, 9).end_of_month)
    end

    it "calculates correct dates for Q3" do
      pick_quarter(3)
      expect(Dataset.last.datafiles.last.end_date).to eq(Date.new(Time.zone.today.year, 12).end_of_month)
    end

    it "calculates correct dates for Q4" do
      pick_quarter(4)
      expect(Dataset.last.datafiles.last.end_date).to eq(Date.new(Time.zone.today.year, 3).end_of_month + 1.year)
    end
  end

  context "when ANNUALLY" do
    def pick_year(year_type)
      choose option: year_type
      click_button "Save and continue"
      expect(page).to have_content('Year')
      fill_in 'datafile[url]', with: 'https://localhost/doc'
      fill_in 'datafile[name]', with: 'my test doc'
      fill_in 'datafile[year]', with: '2015'
      click_button "Save and continue"
    end

    it "shows year field and sets end date" do
      pick_year('annually')
      expect(Dataset.last.datafiles.last.end_date).to eq(Date.new(2015).end_of_year)
    end

    it "shows financial year and sets end date" do
      pick_year('financial-year')
      expect(Dataset.last.datafiles.last.end_date).to eq(Date.new(2016).end_of_quarter)
    end
  end
end

describe "passing the frequency page" do
  let(:land) { FactoryBot.create(:organisation, name: 'land-registry', title: 'Land Registry') }
  let!(:user) { FactoryBot.create(:user, primary_organisation: land) }
  let!(:dataset) { FactoryBot.create(:dataset, organisation: land, frequency: nil) }

  before(:each) do
    url = "https://test.data.gov.uk/api/3/action/package_patch"
    stub_request(:any, url).to_return(status: 200)
    sign_in_as(user)
    visit new_dataset_frequency_path(dataset.uuid, dataset.name)
  end

  it "mandates entering a frequency" do
    click_button "Save and continue"
    expect(page).to have_content("Please indicate how often this dataset is updated", count: 2)
    choose option: "never"
    click_button "Save and continue"
    expect(page).to have_content("Add a link to your data")
  end

  it "continues once user specifies a frequency" do
    choose option: "never"
    click_button "Save and continue"
    expect(page).to have_content("Add a link to your data")
  end

  it "routes to the daily datafiles page and checks for errors" do
    choose option: "daily"
    click_button "Save and continue"
    expect(page).to have_content("Add a link to your data")
    fill_in "datafile[day]", with: '15'
    fill_in 'datafile[month]', with: '1'
    fill_in 'datafile[year]',  with: '2020'
    click_button "Save and continue"
    expect(page).to have_content("Please enter a valid url", count: 2)
    expect(page).to have_content("Please enter a valid name", count: 2)
    fill_in "datafile[url]", with: "http://www.example.com/test.csv"
    fill_in "datafile[name]", with: "Test datafile"
    click_button "Save and continue"
    expect(page).to have_content("Links to your data")
  end

  it "routes to the one-off datafiles page" do
    choose option: "never"
    click_button "Save and continue"
    expect(page).to have_content("Add a link to your data")
    expect(page).to_not have_content("Year")
  end

  it "routes to the monthly datafiles page and checks for errors" do
    choose option: "monthly"
    click_button "Save and continue"
    expect(page).to have_content("Add a link to your data")
    expect(page).to have_content("Time period for this link")
    fill_in "datafile[url]", with: "http://www.example.com/test.csv"
    fill_in "datafile[name]", with: "Test datafile"
    click_button "Save and continue"
    expect(page).to have_content("Please enter a valid month", count: 2)
    expect(page).to have_content("Please enter a valid year", count: 2)
    fill_in "datafile[month]", with: "01"
    fill_in "datafile[year]", with: "2019"
    click_button "Save and continue"
    expect(page).to have_content("Links to your data")
  end

  it "routes to the quarterly datafiles page and checks for errors" do
    choose option: "quarterly"
    click_button "Save and continue"
    expect(page).to have_content("Add a link to your data")
    expect(page).to have_content("Quarter")
    fill_in "datafile[url]", with: "http://www.example.com/test.csv"
    fill_in "datafile[name]", with: "Test datafile"
    click_button "Save and continue"
    expect(page).to have_content("Please select a quarter", count: 2)
    expect(page).to have_content("Please enter a valid year", count: 2)
    choose option: "2"
    fill_in "datafile[year]", with: "2019"
    click_button "Save and continue"
    expect(page).to have_content("Links to your data")
  end

  it "routes to the yearly datafiles page and checks for errors" do
    choose option: "annually"
    click_button "Save and continue"
    expect(page).to have_content("Add a link to your data")
    expect(page).to have_content("Time period for this link")
    expect(page).to_not have_content("Month")
    expect(page).to have_content("Year")
    fill_in "datafile[url]", with: "http://www.example.com/test.csv"
    fill_in "datafile[name]", with: "Test datafile"
    click_button "Save and continue"
    expect(page).to have_content("Please enter a valid year", count: 2)
    fill_in "datafile[year]", with: "2019"
    click_button "Save and continue"
    expect(page).to have_content("Links to your data")
  end

  it "routes to the yearly (financial) datafiles page and checks for errors" do
    choose option: "financial-year"
    click_button "Save and continue"
    expect(page).to have_content("Add a link to your data")
    expect(page).to have_content("Time period for this link")
    expect(page).to_not have_content("Month")
    expect(page).to have_content("Year")
    fill_in "datafile[url]", with: "http://www.example.com/test.csv"
    fill_in "datafile[name]", with: "Test datafile"
    click_button "Save and continue"
    expect(page).to have_content("Please enter a valid year", count: 2)
    fill_in "datafile[year]", with: "2019"
    click_button "Save and continue"
    expect(page).to have_content("Links to your data")
  end
end
