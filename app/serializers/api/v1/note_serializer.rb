class Api::V1::NoteSerializer < ActiveModel::Serializer
  attributes :id, :note_date, :content
end
