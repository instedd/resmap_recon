require 'spec_helper'

describe SiteMapping do
  let(:project) { Project.make }
  let(:source_list) { SourceList.make }

  it { should validate_presence_of :source_list }
end