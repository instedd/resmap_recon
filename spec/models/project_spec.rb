require 'spec_helper'

describe Project do
  let(:rm_sites) { double() }

  let(:master_collection) do 
    o = double() 
    allow(o).to receive(:sites).and_return rm_sites
    o
  end
    
  let(:project) do 
    p = Project.new 
    allow(p).to receive(:master_collection).and_return master_collection
    p
  end

  describe '#search_mfl' do
    def rm_sites_expect_where(where_expected)
      expect(rm_sites).to receive(:where) do |where|
        expect(where).to eql where_expected
      end.and_return rm_sites
    end

    def rm_sites_expect_where_hierarchy(hierarchy_field_code, node_expected)
      expect(rm_sites).to receive(:where) do |where|
        expect(where).to eql("#{hierarchy_field_code}[under]" => node_expected)
      end.and_return rm_sites
    end

    def rm_sites_expect(modifier, value_expected)
      expect(rm_sites).to receive(modifier) do |modifier_value|
        expect(modifier_value).to eq value_expected
      end.and_return rm_sites
    end

    def default_for(param)
      {:page_size => 50, :page => 1}[param]
    end

    def rm_sites_expect_where_default
      rm_sites_expect_where({})
    end

    def rm_sites_expect_default_for(param)
      rm_sites_expect param, default_for(param)
    end

    it 'defaults' do
      rm_sites_expect :page_size, 50
      rm_sites_expect :page, 1
      rm_sites_expect_where({})

      project.search_mfl
    end

    it 'passes page option' do
      rm_sites_expect_where({})
      rm_sites_expect_default_for :page_size
      rm_sites_expect :page, 7

      project.search_mfl page: 7
    end

    it 'passes page_size option' do
      rm_sites_expect_where({})
      rm_sites_expect :page_size, 13
      rm_sites_expect_default_for :page

      project.search_mfl page_size: 13
    end

    it 'passes search option' do
      rm_sites_expect_where :search => { :foo => :bar }
      rm_sites_expect_default_for :page_size
      rm_sites_expect_default_for :page

      project.search_mfl search: { :foo => :bar }
    end

    describe 'hierarchy' do
      before(:each) do
        Field = Struct.new(:code)
        expect(project).to receive(:target_field).and_return Field.new(23)
      end

      it 'passes hierarchy option' do
        rm_sites_expect_where_hierarchy 23, :foo
        rm_sites_expect_default_for :page_size
        rm_sites_expect_default_for :page
        
        project.search_mfl hierarchy: :foo
      end

      it 'passes all options' do
        rm_sites_expect_where :search => { :foo => :bar }
        rm_sites_expect_where_hierarchy 23, :foo
        rm_sites_expect :page_size, 13
        rm_sites_expect :page, 7

        project.search_mfl page_size: 13, page: 7, search: { :foo => :bar }, hierarchy: :foo
      end
    end
  end
end