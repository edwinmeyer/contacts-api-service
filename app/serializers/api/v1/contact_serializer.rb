class Api::V1::ContactSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email
end
