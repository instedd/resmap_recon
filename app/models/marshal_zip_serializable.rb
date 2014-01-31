module MarshalZipSerializable
  def self.dump(x)
    data = nil

    # Marshal.dump fails with large flows when run inside a Fiber (Fiber stacks are 4k only)
    # Run the marshaling in a thread so we can use a full stack
    Thread.new { data = Zlib.deflate(Marshal.dump(x), 9) }.join
    data
  end

  def self.load(x)
    return nil if x.nil?
    data = nil

    # Marshal.load fails with large flows when run inside a Fiber (Fiber stacks are 4k only)
    # Run the unmarshaling in a thread so we can use a full stack
    Thread.new {
      begin
        data = Marshal.load(Zlib.inflate(x))
      rescue
        begin
          data = if x.start_with?("---")
            YAML.load(x)
          else
            JSON.parse(x).with_indifferent_access
          end
        rescue
          nil
        end
      end
    }.join
    data
  end
end
