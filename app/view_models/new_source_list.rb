class NewSourceList < ViewModel::Base
  attr_accessor :name, :file
  validates :name, :presence => true
  validates :file, :presence => true
  validate :file_is_not_fake

  def initialize(attributes = {})
    @file = FakeFile.new
    super
  end

  def persisted?;false;end

  def create_in_project(project)
    collection = AppContext.resmap_api.collections.create name: name
    source_list = project.source_lists.create!(collection_id: collection.id)
    source_list.as_collection.import_wizard.upload(file)

    source_list
  end

  protected

  class FakeFile
    def file?
    end
  end

  def file_is_not_fake
    errors.add(:file, "can't be blank") if file.is_a?(FakeFile)
  end
end
