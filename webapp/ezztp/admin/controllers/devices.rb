Ezztp::Admin.controllers :devices do
  require 'csv'

  get :index do
    @title = "Devices"
    @devices = Device.all
    render 'devices/index'
  end

  get :new do
    @title = pat(:new_title, :model => 'device')
    @device = Device.new
    @configuration_templates = ConfigurationTemplate.all
    @images = Image.all
    render 'devices/new'
  end

  post :create do
    @device = Device.new(params[:device])
    @configuration_templates = ConfigurationTemplate.all
    @images = Image.all
    if @device.save
      @title = pat(:create_title, :model => "device #{@device.id}")
      flash[:success] = pat(:create_success, :model => 'Device')
      params[:save_and_continue] ? redirect(url(:devices, :index)) : redirect(url(:devices, :edit, :id => @device.id))
    else
      @title = pat(:create_title, :model => 'device')
      flash.now[:error] = pat(:create_error, :model => 'device')
      render 'devices/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "device #{params[:id]}")
    @device = Device.find(params[:id])
    @configuration_templates = ConfigurationTemplate.all
    @images = Image.all
    if @device
      render 'devices/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'device', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "device #{params[:id]}")
    @device = Device.find(params[:id])
    @configuration_templates = ConfigurationTemplate.all
    @images = Image.all
    if @device
      if @device.update_attributes(params[:device])
        flash[:success] = pat(:update_success, :model => 'Device', :id =>  "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:devices, :index)) :
          redirect(url(:devices, :edit, :id => @device.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'device')
        render 'devices/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'device', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Devices"
    device = Device.find(params[:id])
    if device
      if device.destroy
        flash[:success] = pat(:delete_success, :model => 'Device', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'device')
      end
      redirect url(:devices, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'device', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Devices"
    unless params[:device_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'device')
      redirect(url(:devices, :index))
    end
    ids = params[:device_ids].split(',').map(&:strip)
    devices = Device.find(ids)
    
    if Device.destroy devices
    
      flash[:success] = pat(:destroy_many_success, :model => 'Devices', :ids => "#{ids.to_sentence}")
    end
    redirect url(:devices, :index)
  end

  get :csv do
    @title = "Devices"
    @devices = Device.all
    @error = nil
    render 'devices/csv'
  end

  get 'export.csv' do
    content_type :csv
    @devices = Device.all
    csv = nil
    csv = CSV.generate{|c|
      c << ['id', 'keytype', 'key', 'configuration_template_id', 'image_id']
      @devices.each{|device|
          c << [device[:id], device[:keytype], device[:key], device[:configuration_template_id], device[:image_id]]
      }
    }
    return csv
  end

  get 'sample.csv' do
    content_type :csv

    return CSV.generate{|c|
      c << ['id', 'keytype', 'key', 'configuration_template_id', 'image_id', '# first line will be ignored.']
      c << ['1', 'port', 'sw01:ge-0/0/0.0', '1', '2', '# update a exist device if id is not null and found on DB.']
      c << ['', 'model', 'qfx5100-48s', '2', '4', '# create a new device if id is null.']
      c << ['', 'mac', '00aabbccddee', '2', '6']
    }
  end

  post :csv do
    @message = []
    @error = []
    csv = nil
    if params["device"] && params["device"]["file"]
      filename = params["device"]["file"][:filename]
      csv = params["device"]["file"][:tempfile].read
    end

    if csv
      csv_ary = CSV.parse(csv)
      csv_ary.delete_at(0)
      csv_ary.each{|d|
        id = d[0]
        param = {:keytype => d[1], :key => d[2], :configuration_template_id => d[3], :image_id => d[4]}

        device = nil
        if id && id.length > 0
          begin
            device = Device.find(id)
          rescue => e
            puts 'find device failed'
            @error << "error: can't find the device by id. line: '#{d.join(',')}' " + 'expection: ' + e.to_s
            next
          end
        end

        if device
          begin
            device.update_attributes!(param)
          rescue => e
            puts 'update failed'
            @error << "error line: '#{d.join(',')}' " + 'expection: ' + e.to_s
          else
            puts 'update success'
            @message << "successfully updated id: #{id} line: '#{d.join(',')}'"
          end
        else
          device = Device.new(param)
          begin
            device.save!
          rescue => e
            puts 'create failed'
            @error << "error line: '#{d.join(',')}' " + 'expection: ' + e.to_s
          else 
            puts 'create success'
            @message << "successfully created id: #{id} line: '#{d.join(',')}'"
          end
        end
      }
    else
      @error << 'file is not specified.'
    end

    @message = nil if @message.length == 0
    @error = nil if @error.length == 0

    render 'devices/csv'
  end
end
