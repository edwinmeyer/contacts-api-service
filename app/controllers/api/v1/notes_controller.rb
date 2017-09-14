class Api::V1::NotesController < ApplicationController
  before_action :set_note, only: [:show, :update, :destroy]

  # GET /notes
  def index
    notes = Note.order('id')
    render json: notes
  end

  # GET /notes/1
  def show
    render json: @note
  end

  # POST /notes
  def create
    note = Note.new(note_params)
    render json: note, status: :created if note.save!
  end

  # PATCH/PUT /notes/1
  def update
    @note.update!(note_params)
    render json: @note, status: :ok
  end

  # DELETE /notes/1
  def destroy
    @note.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_note
      @note = Note.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def note_params
      params.require(:note).permit(:note_date, :content, :contact_id)
    end
end
