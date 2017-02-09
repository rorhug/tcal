PRY_HIDDEN_MODEL_ATTRIBUTES = {
  "User" => [:auth_hash],
  "StaffMember" => [:row_html]
}

Pry.config.print = proc do |output, value, _pry_|
  hidden_attrs = PRY_HIDDEN_MODEL_ATTRIBUTES[value.class.to_s]

  value_to_print = if hidden_attrs.nil?
    value
  else
    dupped_model = value.dup
    hidden_attrs.each do |attr|
      dupped_model.write_attribute(attr, "<HIDDEN FOR PRY>")
    end
    dupped_model
  end

  Pry::DEFAULT_PRINT.call(output, value_to_print, _pry_)
end
