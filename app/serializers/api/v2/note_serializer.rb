class Api::V2::NoteSerializer < ActiveModel::Serializer
  attributes :id, :note_date, :content
end
