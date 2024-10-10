class User < ApplicationRecord
  validates_presence_of :name
  
  # Insecure MD5 hash as password
  def password=(new_password)
    self[:password] = Digest::MD5.hexdigest(new_password)
  end

  def to_xml(options={})
    if options[:builder]
      options[:builder].name name
    else
      "<name>#{name}</name>"
    end
  end
end
