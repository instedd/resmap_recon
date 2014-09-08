require 'spec_helper'

describe 'Routes' do
  it 'routes to MFL sites map' do
    expect(:get => "/projects/1/master/sites/map").to route_to("project_master_sites#map", :project_id => "1")
  end
end