Ezztp::App.controllers :config do
  
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
  
  get 'config.txt' do
    content_type 'text/plain'
    # params = "dc38e1578381!dc01-row01!ge-0/0/1.0:management!Juniper-qfx5100-48s!TA3714171023"
    param = params[:param] unless params[:param].nil?
    param = params[:p] if param.nil? unless params[:p].nil?
    return 500,'500' if param.nil?
    @mac, @sw_id, ifl_vlan, @model, @serial = param.split('!')
    # sw_id, ifl_vlan  is optional if customer used DHCP Snooping with option 82

    @ifl, @vlan_name = ifl_vlan.split(':') unless ifl_vlan.nil?
    @serial = '' if @serial.nil?

    logger.info 'MAC Address: ' + @mac
    logger.info 'Management Switch: ' + @sw_id unless @sw_id.nil?
    logger.info 'Interface: ' + @ifl unless @ifl.nil?
    logger.info 'VLAN Name: ' + @vlan_name unless @vlan_name.nil?
    logger.info 'Switch Model: ' + @model
    logger.info 'Switch S/N: ' + @serial
    unless @ifl.nil?
      @ifl =~ /[gx]e-(\d+)\/(\d+)\/(\d+).*/
      fpc,pic,port = $1.to_i,$2.to_i,$3.to_i

      mgt_segment = GlobalConfiguration.find_by(name: 'management_segment').value.to_s
      logger.info 'Management Segment: ' +  mgt_segment

      base_ip = mgt_segment.to_s.split('/')[0]
      prefixlen = mgt_segment.to_s.split('/')[1]

      if ManagementSwitch.all.length == 0
        logger.info 'Management Switch is not configured. We will generate management address from start address of management segement.'
      else
        logger.info 'Management Switch is configured.'
        switch = ManagementSwitch.find_by(subscriber_id: @sw_id)
        if switch.nil?
          logger.info 'Management Switch is not found. return 500'
          return 500, '500'
        end
        logger.info 'Management Switch is found.'
        base_ip = switch.base_ip_address.to_s
        vc_member = switch.number_of_vc_member.to_i

        if fpc >= vc_member
          logger.info "FPC #{fpc} is should be not found in this switch. return 500"
          return 500, '500'
        end

        if port > 47
          logger.info "Port #{port} is should be less than 47. return 500"
          return 500, "500"
        end
      end
      @management_address = get_addr(base_ip, prefixlen, fpc, port)
      logger.info 'Generated Management Address: ' + @management_address

      @hostname = @sw_id + '-' + fpc.to_s + '-' + port.to_s
      logger.info 'Generated Host Name: ' + @hostname
    else
      @management_address = 'undefined'
      @hostname = "undefined-#{@serial}-#{@mac}"
    end

    @global = Hash[GlobalConfiguration.all.map{|conf| [conf.name.to_sym, conf.value]}]
    logger.info @global

    res = Device.find_by(keytype: "serial", key:@serial)
    if res then
      logger.info 'serial'
      return 404, '404' if res.configuration_template_id.to_s == '0'
      return render :erb, ConfigurationTemplate.find(res.configuration_template_id).template
    end

    res = Device.find_by(keytype: "mac", key:@mac)
    if res then
      logger.info 'mac'
      return 404, '404' if res.configuration_template_id.to_s == '0'
      return render :erb, ConfigurationTemplate.find(res.configuration_template_id).template
    end

    res = Device.find_by(keytype: "port", key:"#{@sw_id}:#{@ifl}")
    if res then
      logger.info 'port'
      return 404, '404' if res.configuration_template_id.to_s == '0'
      return render :erb, ConfigurationTemplate.find(res.configuration_template_id).template
    end

    by_models = Device.where(keytype: "model")
    if by_models
      models = []
      by_models.each{|m|
        models << m.key if @model.index(m.key.downcase)
      }
      
      if models.length != 0 then
        longest_model = ""
        models.each{|md| longest_model = md if longest_model.length < md.length }
        res = Device.find_by(keytype: "model", key:longest_model)
        logger.info 'model'
        return 404, '404' if res.configuration_template_id.to_s == '0'
        return render :erb, ConfigurationTemplate.find(res.configuration_template_id).template if res
      end
    end


    logger.info 'default'
    return render :erb, ConfigurationTemplate.first.template
  end

  post :upload, :with => :fname,  :csrf_protection => false do
    fname = params[:fname]

    hostname = nil
    datetime = nil

    if fname =~ /.+_\d{8}_\d{6}\_juniper\.conf/
      tmp = fname.split('_')
      hostname = tmp.shift(tmp.length - 3).join('_')
      datetime = [tmp[0],tmp[1]].join('_')
    elsif fname =~ /.+_juniper\.conf_\d{8}_\d{6}/
      hostname= fname.split('_juniper.conf_')[0]
      datetime = fname.split('_juniper.conf_')[1]
    else
      halt 500
    end

    s_hostname = hostname.split('-')
    subscriber = s_hostname[0, s_hostname.length - 2].join('-')
    fpc = s_hostname[s_hostname.length - 2]
    port = s_hostname[s_hostname.length - 1]
    content = request.body.read
    junos_ver = content.scan(/^version (.+);$/)[0][0]

    dev_key = subscriber+':ge-'+fpc+'/0/'+port+'.0'
    logger.info 'key: ' + dev_key
    logger.info 'junos_ver: ' + junos_ver

    tmpl_name = hostname+"_auto_archive"
    logger.info 'tmpl_name: ' + tmpl_name

    cfg = ConfigurationTemplate.find_by(name: tmpl_name)
    cfg_id = nil
    if cfg
      logger.info 'Updating Configuration template...'
      cfg.template = content
      cfg.save
      cfg_id = cfg.id
    else
      logger.info 'Creating Configuration template...'
      cfg = ConfigurationTemplate.create(name: tmpl_name, template: content)
      cfg_id = cfg.id
    end

    dev = Device.find_by(keytype: "port", key: dev_key)
    if dev
      logger.info 'Device found. Update...'
      dev.configuration_template_id = cfg_id
      dev.save
    else
      logger.info 'Device not found.'
    end
  end
end
