class SynchronizationsController < ApplicationController

  before_filter :find_all_synchronizations
  before_filter :find_page
  
  before_filter :check_model, :only => [:update_all, :delete_all, :update_one, :create_record]

  def index
    # you can use meta fields from your model instead (e.g. browser_title)
    # by swapping @page for @synchronization in the line below:
    present(@page)
  end

  def show
    @synchronization = Synchronization.find(params[:id])

    # you can use meta fields from your model instead (e.g. browser_title)
    # by swapping @page for @synchronization in the line below:
    present(@page)
  end
  
  # ------------------------------
  # test login
  
  def testlogin
    return unless testauthenticate == true
    
    render :nothing => true
  end

  def testauthenticate
    # authenticate
    authenticated = authenticate_or_request_with_http_basic "Authentication Required" do |username, password|
      @user = User.find_by_username(username)
      unless @user.nil?
        username == @user.username && @user.valid_password?(password)
      end
    end
    
    if authenticated == true
      true
    else
      false
    end
  end

  # ------------------------------
  # create records
  def create_record
    if @model.needs_authentication? then
      return unless testauthenticate == true

      @model.create_record(@user.id, params)
      
      render :nothing => true
    end
  end
  
  # ------------------------------
  # custom synchronization methods
  
  # update sync a whole model
  def update_all
    if @model.needs_authentication? then
      update_all_authenticated
    else
      update_all_unauthenticated
    end
  end
  
  def update_all_unauthenticated
    if params[:updated_at].nil? then
      @records = @model.all
    else
      @records = @model.find(:all, :conditions => ['updated_at > ?', Time.parse(params[:updated_at])+1])
    end
        
    respond_with_records @records    
  end
  
  def update_all_authenticated
    # authenticate  
    return unless testauthenticate == true
    
    @records = @model.find_all_by_user_id(@user.id)
    
    respond_with_records @records
  end
    
  # delete sync a whole model
  def delete_all
    if @model.needs_authentication? then
      render :text => t('needs_authentication')
    else
      @records = @model.all.collect{ |m| m.id }
    
      respond_with_records @records
    end
  end
  
  # down sync one record
  #def update_one
  #  if @model.needs_authentication? then
  #    update_one_authenticated
  #  else
  #    update_one_unauthenticated
  #  end
  #end
  
  #def update_one_unauthenticated
  #  @record = @model.find(params[:id])
  #  respond_to do |format|
  #    format.html { render :text => t('format_error') }
  #    format.json { render :json => @record }
  #    format.xml { render :xml => @record }
  #  end
  #end
  
  #def update_one_authenticated
  #
  #end
  
protected

  def find_all_synchronizations
    @synchronizations = Synchronization.order('position ASC')
  end

  def find_page
    @page = Page.where(:link_url => "/synchronizations").first
  end

  def check_model
    @model = params[:model_name].singularize.camelize.constantize
    
    unless (@model.synchronizable?) then
      render :text => t('not_synchronizable')
    end
  end
  
  def respond_with_records(records)
    respond_to do |format|
      #format.html { render :text => t('format_error') }
      format.json { render :json => records }
      format.xml { render :xml => records }
    end
  end

end
