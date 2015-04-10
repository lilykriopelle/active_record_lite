class AttrAccessorObject
  def self.my_attr_accessor(*names)

    names.each do |ivar|
      define_method(ivar) { self.instance_variable_get("@#{ivar}") }
      define_method("#{ivar}=") do |val|
         self.instance_variable_set("@#{ivar}", val)
       end
    end
  end
end
