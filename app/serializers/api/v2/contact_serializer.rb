class Api::V2::ContactSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name
end
