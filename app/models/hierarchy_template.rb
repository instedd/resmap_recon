module HierarchyTemplate
  def self.load(template_name)
    filename = case template_name
               when 'Kenya MFL' then "kenya_hierarchy.yml"
               when 'Tanzania MFL' then "tanzania_hierarchy.yml"
               else raise "Unknown hierarchy template: #{template_name}"
               end

    YAML::load_file(File.join(Rails.root, "config", filename))
  end
end
