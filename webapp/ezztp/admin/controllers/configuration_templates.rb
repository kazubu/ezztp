Ezztp::Admin.controllers :configuration_templates do
  get :index do
    @title = "Configuration_templates"
    @configuration_templates = ConfigurationTemplate.all
    render 'configuration_templates/index'
  end

  get :new do
    @title = pat(:new_title, :model => 'configuration_template')
    @configuration_template = ConfigurationTemplate.new
    render 'configuration_templates/new'
  end

  get :new, :with => :id do
    @title = pat(:new_title, :model => 'configuration_template')
    @configuration_template = ConfigurationTemplate.new
    @configuration_template.template = ConfigurationTemplate.find(params[:id]).template
    render 'configuration_templates/new'
  end

  post :create do
    @configuration_template = ConfigurationTemplate.new(params[:configuration_template])
    if @configuration_template.save
      @title = pat(:create_title, :model => "configuration_template #{@configuration_template.id}")
      flash[:success] = pat(:create_success, :model => 'ConfigurationTemplate')
      params[:save_and_continue] ? redirect(url(:configuration_templates, :index)) : redirect(url(:configuration_templates, :edit, :id => @configuration_template.id))
    else
      @title = pat(:create_title, :model => 'configuration_template')
      flash.now[:error] = pat(:create_error, :model => 'configuration_template')
      render 'configuration_templates/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "configuration_template #{params[:id]}")
    @configuration_template = ConfigurationTemplate.find(params[:id])
    if @configuration_template
      render 'configuration_templates/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'configuration_template', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "configuration_template #{params[:id]}")
    @configuration_template = ConfigurationTemplate.find(params[:id])
    if @configuration_template
      if @configuration_template.update_attributes(params[:configuration_template])
        flash[:success] = pat(:update_success, :model => 'Configuration_template', :id =>  "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:configuration_templates, :index)) :
          redirect(url(:configuration_templates, :edit, :id => @configuration_template.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'configuration_template')
        render 'configuration_templates/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'configuration_template', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Configuration_templates"
    configuration_template = ConfigurationTemplate.find(params[:id])
    if configuration_template
      if configuration_template.destroy
        flash[:success] = pat(:delete_success, :model => 'Configuration_template', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'configuration_template')
      end
      redirect url(:configuration_templates, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'configuration_template', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Configuration_templates"
    unless params[:configuration_template_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'configuration_template')
      redirect(url(:configuration_templates, :index))
    end
    ids = params[:configuration_template_ids].split(',').map(&:strip)
    configuration_templates = ConfigurationTemplate.find(ids)
    
    if ConfigurationTemplate.destroy configuration_templates
    
      flash[:success] = pat(:destroy_many_success, :model => 'Configuration_templates', :ids => "#{ids.to_sentence}")
    end
    redirect url(:configuration_templates, :index)
  end
end
