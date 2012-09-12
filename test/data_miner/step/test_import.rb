require 'helper'
init_database

require 'earth'
require 'earth/electricity/electric_utility'
require 'earth/hospitality/commercial_building_energy_consumption_survey_response'
require 'earth/residence/residential_energy_consumption_survey_response'

class PetBlue < ActiveRecord::Base
  data_miner do
    import 'fake', :url => 'fake' do
      key :id
    end
  end
end
PetBlue.auto_upgrade!

describe DataMiner::Step::Import do
  describe '#table_has_autoincrementing_primary_key?' do
    it "recognizes auto-increment primary keys" do
      PetBlue.data_miner_script.steps.first.send(:table_has_autoincrementing_primary_key?).must_equal true
    end
    it "recognizes that not all integer primary keys are auto-increment" do
      [
        ElectricUtility,
        ResidentialEnergyConsumptionSurveyResponse,
        CommercialBuildingEnergyConsumptionSurveyResponse,
      ].each do |model|
        model.data_miner_script.steps.select { |s| s.is_a?(DataMiner::Step::Import) }.each do |import_step|
          import_step.send(:table_has_autoincrementing_primary_key?).must_equal false
        end
      end
    end
  end
end
