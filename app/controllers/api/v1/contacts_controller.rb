class Api::V1::ContactsController < ApplicationController
  before_action :set_contact, only: [:show, :update, :destroy]

  # GET /contacts
  def index
    @contacts = Contact.order('last_name, first_name')
    render json: @contacts
  end

  # GET /contacts/1
  def show
    render json: @contact
  end

  # POST /contacts
  def create
    contact = Contact.new(contact_params)
    render json: contact, status: :created if contact.save!
  end

  # PATCH/PUT /contacts/1
  def update
    @contact.update!(contact_params)
    render json: @contact, status: :ok
  end

  # DELETE /contacts/1
  def destroy
    @contact.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contact
      @contact = Contact.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def contact_params
      params.require(:contact).permit(:first_name, :last_name, :phone, :email)
    end
end
