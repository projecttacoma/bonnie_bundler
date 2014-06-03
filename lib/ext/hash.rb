class Hash

  def remove_nils
    clear_nils = Proc.new { |k, v| v.kind_of?(Hash) ? (v.delete_if(&clear_nils); nil) : v.nil? }; 
    self.delete_if(&clear_nils)
  end

  def convert_keys_to_strings
     Hash.convert_keys_to_strings(self)
     self
  end

  def self.convert_keys_to_strings(hash)
     if hash.kind_of? Hash 
         hash.keys.each do |k|
          v = hash[k]
          if k.kind_of? Symbol
            hash[k.to_s] = hash[k]
            hash.delete(k)
          end
          Hash.convert_keys_to_strings(v)
       end
     elsif hash.kind_of? Array 
       hash.each{|val| Hash.convert_keys_to_strings(val)}
     end 
  end

end
