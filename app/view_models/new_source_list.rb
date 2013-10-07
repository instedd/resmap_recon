class NewSourceList
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :name, :file
  validates :name, :presence => true

  def initialize
    file = FakeFile.new
  end

  def persisted?;false;end

  class FakeFile
    def file?
    end
  end
end
