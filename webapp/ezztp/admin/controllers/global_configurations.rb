Ezztp::Admin.controllers :global_configurations do
  get :index do
    @title = "Global_configurations"
    @global_configurations = GlobalConfiguration.all
    render 'global_configurations/index'
  end

  get :new do
    @title = pat(:new_title, :model => 'global_configuration')
    @global_configuration = GlobalConfiguration.new
    render 'global_configurations/new'
  end

  post :create do
    @global_configuration = GlobalConfiguration.new(params[:global_configuration])
    if @global_configuration.save
      @title = pat(:create_title, :model => "global_configuration #{@global_configuration.id}")
      flash[:success] = pat(:create_success, :model => 'GlobalConfiguration')
      params[:save_and_continue] ? redirect(url(:global_configurations, :index)) : redirect(url(:global_configurations, :edit, :id => @global_configuration.id))
    else
      @title = pat(:create_title, :model => 'global_configuration')
      flash.now[:error] = pat(:create_error, :model => 'global_configuration')
      render 'global_configurations/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "global_configuration #{params[:id]}")
    @global_configuration = GlobalConfiguration.find(params[:id])
    if @global_configuration
      render 'global_configurations/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'global_configuration', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "global_configuration #{params[:id]}")
    @global_configuration = GlobalConfiguration.find(params[:id])
    if @global_configuration
      if @global_configuration.update_attributes(params[:global_configuration])
        flash[:success] = pat(:update_success, :model => 'Global_configuration', :id =>  "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:global_configurations, :index)) :
          redirect(url(:global_configurations, :edit, :id => @global_configuration.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'global_configuration')
        render 'global_configurations/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'global_configuration', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Global_configurations"
    global_configuration = GlobalConfiguration.find(params[:id])
    if global_configuration
      if global_configuration.destroy
        flash[:success] = pat(:delete_success, :model => 'Global_configuration', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'global_configuration')
      end
      redirect url(:global_configurations, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'global_configuration', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Global_configurations"
    unless params[:global_configuration_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'global_configuration')
      redirect(url(:global_configurations, :index))
    end
    ids = params[:global_configuration_ids].split(',').map(&:strip)
    global_configurations = GlobalConfiguration.find(ids)
    
    if GlobalConfiguration.destroy global_configurations
    
      flash[:success] = pat(:destroy_many_success, :model => 'Global_configurations', :ids => "#{ids.to_sentence}")
    end
    redirect url(:global_configurations, :index)
  end
end
