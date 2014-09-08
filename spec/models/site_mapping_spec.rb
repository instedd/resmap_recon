require 'spec_helper'

describe SiteMapping do
  let(:project) { Project.make }
  let(:source_list) { SourceList.make }

  describe 'project' do
    it 'gets the project id from the source list if present' do
      m = SiteMapping.new name: 'Foo'
      m.source_list = source_list
      m.project = nil
      m.save

      expect(m.save).to be_true
      expect(m.project.id).to be source_list.project.id
    end

    it 'accepts site mappings without source list if project is set' do
      m = SiteMapping.new name: 'Foo'
      m.source_list = nil
      m.project = project

      expect(m.save).to be_true
      expect(m.source_list).to be_nil
      expect(m.project.id).to be project.id
    end 

    it 'rejects site mappings without source list and without project' do
      m = SiteMapping.new name: 'Foo'
      m.source_list = nil
      m.project = nil

      expect(m.save).to be_false      
    end
  end
  
  describe '#non_source_list' do
    it 'restricts scope to site mappings which did not come from a source list' do
      source_list.site_mappings.make name: 'Mapping from source list 1'
      source_list.site_mappings.make name: 'Mapping from source list 2'

      SiteMapping.make name: 'Non Source List 1'
      SiteMapping.make name: 'Non Source List 2'

      expect(SiteMapping.non_source_list.order(:name).map(&:name)).to eql(['Non Source List 1', 'Non Source List 2'])
    end
  end
end