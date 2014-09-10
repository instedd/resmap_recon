require "spec_helper"

describe SourceList do
  let(:resmap_api) { double(:resmap_api) }

  before(:each) do
    AppContext.resmap_api = resmap_api
  end

  class MockSite < Struct.new(:id, :name, :properties)
  end

  it "creates sites from Resource Map" do
    collections = double(:collections)
    resmap_api.stub(collections: collections)

    collection = double(:collection)
    collections.should_receive(:find).with(1).and_return(collection)

    sites = double(:sites)
    collection.stub(sites: sites)

    sites_relation = double(:sites_relation)
    sites.should_receive(:where).with({}).and_return(sites_relation)
    sites_relation.should_receive(:page_size).with(1000).and_return(sites_relation)

    sites_relation.should_receive(:each).and_yield(MockSite.new(10, "Ten", {})).and_yield(MockSite.new(20, "Twenty", {}))

    source_list = SourceList.make collection_id: 1
    source_list.import_sites_from_resource_map

    mappings = source_list.site_mappings.all
    mappings.length.should eq(2)
    mappings[0].site_id.should eq("10")
    mappings[0].name.should eq("Ten")
    mappings[1].site_id.should eq("20")
    mappings[1].name.should eq("Twenty")
  end

  describe "process automapping" do
    let(:project) { Project.make hierarchy: HierarchyTemplate.load("Tanzania MFL") }
    let(:source_list) { project.source_lists.make }
    let(:chosen_fields) {
      [
        {"kind"=>"Fixed value", "name"=>"Tanzania", "id"=>"TZ"},
        {"kind"=>"Fixed value", "name"=>"Central Zone", "id"=>"TZ.NT"},
        {"kind"=>"Source field", "name"=>"Region name", "id"=>"regionname"},
        {"kind"=>"Source field", "name"=>"District", "id"=>"district"},
      ]
    }

    class SiteRelationMock
      def initialize(enumerable)
        @sites = enumerable
      end

      def each(flag=false)
        @sites.each do |s|
          yield(s) 
        end
      end

      def total_count
        @sites.length
      end
    end

    def define_sites_pending(properties)
      sites_pending = SiteRelationMock.new(properties.each_with_index.map do |props, i|
        MockSite.new(i + 1, "Site#{i}", props)
      end)

      source_list.stub sites_pending: sites_pending

      properties.length.times do |i|
        source_list.site_mappings.make site_id: i + 1
      end
    end

    it "automaps one site and finds it" do
      define_sites_pending [
        {"regionname" => "Dodoma Region", "district" => "Bahi District"},
      ]

      result, count = source_list.process_automapping(chosen_fields)
      result.should eq([])
      count.should eq(1)

      SiteMapping.first.mfl_hierarchy.should eq("TZ.CL.DO.BA")
    end

    it "automaps one site and doesn't find it" do
      define_sites_pending [
        {"regionname" => "Dodoma Region", "district" => "Caqui District"},
      ]

      result, count = source_list.process_automapping(chosen_fields)
      count.should eq(0)
      result.should eq([
        {
          name: "Tanzania",
          sub: [
            {
              name: "Central Zone",
              sub: [
                {
                  name: "Dodoma Region",
                  sub: [
                    {
                      name: "Caqui District",
                      sub: [],
                      options: ["Bahi District", "Chemba District", "Chamwino District", "Dodoma District", "Kondoa District", "Kongwa District", "Mpwapwa District"]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ])

      SiteMapping.first.mfl_hierarchy.should be_nil
    end
  end
end
