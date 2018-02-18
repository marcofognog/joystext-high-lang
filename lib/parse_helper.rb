module ParseHelper
  def sanitized_button_name(name)
    name.delete('.').delete('<').delete('>').delete('*')
  end
end
