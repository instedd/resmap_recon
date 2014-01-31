require "spec_helper"

describe SourceList do
  let(:resmap_api) { mock(:resmap_api) }

  before(:each) do
    AppContext.resmap_api = resmap_api
  end

  class MockSite < Struct.new(:id, :name)
  end

  it "creates sites from Resource Map" do
    collections = mock(:collections)
    resmap_api.stub(collections: collections)

    collection = mock(:collection)
    collections.should_receive(:find).with(1).and_return(collection)

    sites = mock(:sites)
    collection.stub(sites: sites)

    sites_relation = mock(:sites_relation)
    sites.should_receive(:where).with({}).and_return(sites_relation)

    sites_relation.should_receive(:each).and_yield(MockSite.new(10, "Ten")).and_yield(MockSite.new(20, "Twenty"))

    source_list = SourceList.make collection_id: 1
    source_list.import_sites_from_resource_map

    mappings = source_list.site_mappings.all
    mappings.length.should eq(2)
    mappings[0].site_id.should eq("10")
    mappings[0].name.should eq("Ten")
    mappings[1].site_id.should eq("20")
    mappings[1].name.should eq("Twenty")
  end
end
