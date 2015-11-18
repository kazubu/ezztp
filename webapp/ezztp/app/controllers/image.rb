Ezztp::App.controllers :image do
  
  # get :index, :map => '/foo/bar' do
  #   session[:foo] = 'bar'
  #   render 'index'
  # end

  # get :sample, :map => '/sample/url', :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   'Maps to url '/foo/#{params[:id]}''
  # end

  # get '/example' do
  #   'Hello world!'
  # end
  
  get 'image.tgz' do
    content_type 'application/x-gzip'
    # params = "dc38e1578381!dc01-row01!ge-0/0/1.0:management!Juniper-qfx5100-48s!TA3714171023"
    param = params[:param] unless params[:param].nil?
    param = params[:p] if param.nil? unless params[:p].nil?
    return 404,'404' if param.nil?
    mac, sw_id, ifl_vlan, model, serial = param.split('!')
    # sw_id, ifl_vlan  is optional if customer used DHCP Snooping with option 82
    serial = '' if serial.nil?

    ifl, vlan_name = ifl_vlan.split(':') unless ifl_vlan.nil?

    logger.info 'MAC Address: ' + mac
    logger.info 'Management Switch: ' + sw_id unless sw_id.nil?
    logger.info 'Interface: ' + ifl unless ifl.nil?
    logger.info 'VLAN Name: ' + vlan_name unless vlan_name.nil?
    logger.info 'Switch Model: ' + model unless model.nil?
    logger.info 'Switch S/N: ' + serial unless serial.nil?

    res = Device.find_by(keytype: "serial", key:serial) unless serial.nil?
    if res then
      logger.info 'serial'
      return 404, '404' if res.image_id.to_s == '0'
      file_name = Image.find(res.image_id).file_name
      p 'filename:' + file_name
      send_file('images/' + file_name)
      return
    end

    res = Device.find_by(keytype: "mac", key:mac) unless mac.nil?
    if res then
      logger.info 'mac'
      return 404, '404' if res.image_id.to_s == '0'
      file_name = Image.find(res.image_id).file_name
      p 'filename:' + file_name
      send_file('images/' + file_name)
      return
    end

    res = Device.find_by(keytype: "port", key:"#{sw_id}:#{ifl}")
    if res then
      logger.info 'port'
      return 404, '404' if res.image_id.to_s == '0'
      file_name = Image.find(res.image_id).file_name
      p 'filename:' + file_name
      send_file('images/' + file_name)
      return
    end

    by_models = Device.where(keytype: "model")
    if by_models
      models = []
      by_models.each{|m|
        logger.info m.key
        models << m.key if model.index(m.key.downcase)
      }
      break if models.length == 0

      longest_model = ""
      models.each{|md| longest_model = md if longest_model.length < md.length }
      res = Device.find_by(keytype: "model", key:longest_model)
      logger.info 'model'
      return 404, '404' if res.image_id.to_s == '0'
      file_name = Image.find(res.image_id).file_name
      p 'filename:' + file_name
      send_file('images/' + file_name)
      return
    end

    return ""
  end

end
