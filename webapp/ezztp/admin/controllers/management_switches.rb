Ezztp::Admin.controllers :management_switches do
  get :index do
    @title = "Management_switches"
    @management_switches = ManagementSwitch.all
    render 'management_switches/index'
  end

  get :new do
    @title = pat(:new_title, :model => 'management_switch')
    @management_switch = ManagementSwitch.new
    render 'management_switches/new'
  end

  post :create do
    @management_switch = ManagementSwitch.new(params[:management_switch])
    if @management_switch.save
      @title = pat(:create_title, :model => "management_switch #{@management_switch.id}")
      flash[:success] = pat(:create_success, :model => 'ManagementSwitch')
      params[:save_and_continue] ? redirect(url(:management_switches, :index)) : redirect(url(:management_switches, :edit, :id => @management_switch.id))
    else
      @title = pat(:create_title, :model => 'management_switch')
      flash.now[:error] = pat(:create_error, :model => 'management_switch')
      render 'management_switches/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "management_switch #{params[:id]}")
    @management_switch = ManagementSwitch.find(params[:id])
    if @management_switch
      render 'management_switches/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'management_switch', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "management_switch #{params[:id]}")
    @management_switch = ManagementSwitch.find(params[:id])
    if @management_switch
      if @management_switch.update_attributes(params[:management_switch])
        flash[:success] = pat(:update_success, :model => 'Management_switch', :id =>  "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:management_switches, :index)) :
          redirect(url(:management_switches, :edit, :id => @management_switch.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'management_switch')
        render 'management_switches/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'management_switch', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Management_switches"
    management_switch = ManagementSwitch.find(params[:id])
    if management_switch
      if management_switch.destroy
        flash[:success] = pat(:delete_success, :model => 'Management_switch', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'management_switch')
      end
      redirect url(:management_switches, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'management_switch', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Management_switches"
    unless params[:management_switch_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'management_switch')
      redirect(url(:management_switches, :index))
    end
    ids = params[:management_switch_ids].split(',').map(&:strip)
    management_switches = ManagementSwitch.find(ids)
    
    if ManagementSwitch.destroy management_switches
    
      flash[:success] = pat(:destroy_many_success, :model => 'Management_switches', :ids => "#{ids.to_sentence}")
    end
    redirect url(:management_switches, :index)
  end

  post :address do
    logger.info params
    @mgsw = params[:management_switch][:mgsw]
    @fpc = params[:management_switch][:fpc]
    @port = params[:management_switch][:port]

    @management_switches = ManagementSwitch.all
    @management_address = nil
    @first_management_address = nil
    @last_management_address = nil
    @error = nil

    if(!@fpc.nil? and !@port.nil?)
      base_ip = nil
      subscriber = nil
      vc_member = nil
      if(!@mgsw.nil? and @mgsw.length != 0)
        switch = ManagementSwitch.find_by(id: @mgsw)
        subscriber = switch.subscriber_id.to_s
        base_ip = switch.base_ip_address.to_s
        vc_member = switch.number_of_vc_member.to_i
        @error = "Error! FPC #{@fpc} is not found on this VC!! (Member: #{vc_member})" if @fpc.to_i >= vc_member 
      else
        base_ip = GlobalConfiguration.find_by(name: 'management_segment').value.to_s.split('/')[0]
      end
      prefixlen = GlobalConfiguration.find_by(name: 'management_segment').value.to_s.split('/')[1]
      @management_address = get_addr(base_ip, prefixlen, @fpc.to_i, @port.to_i)
      @first_management_address = get_addr(base_ip, prefixlen, 0, 0)
      @last_management_address = get_addr(base_ip, prefixlen, vc_member.to_i - 1, 47) unless vc_member.nil?

      @error = " \nError! Port #{@port} is invalid. Port number should be less than 47" if @port.to_i > 47
    end
    render 'management_switches/address'
  end

  get :address do
    @management_switches = ManagementSwitch.all

    render 'management_switches/address'
  end
end
