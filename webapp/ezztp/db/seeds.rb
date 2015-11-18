email     = shell.ask "Which email do you want use for logging into admin?"
password  = shell.ask "Tell me the password to use:"

shell.say ""

account = Account.create(:email => email, :name => "ZTP", :surname => "Admin", :password => password, :password_confirmation => password, :role => "admin")

if account.valid?
  shell.say "================================================================="
  shell.say "Account has been successfully created, now you can login with:"
  shell.say "================================================================="
  shell.say "   email: #{email}"
  shell.say "   password: #{password}"
  shell.say "================================================================="
else
  shell.say "Sorry but some thing went wrong!"
  shell.say ""
  account.errors.full_messages.each { |m| shell.say "   - #{m}" }
end

default_config = ConfigurationTemplate.create(:name => "default", :template => <<EOL
system {
  arp {
    aging-timer 5;
  }
  host-name <%= @hostname %>;
  syslog {
    user * {
      any emergency;
    }
    file messages {
      any notice;
      authorization info;
    }
    file interactive-commands {
      interactive-commands any;
    }
  }
  extensions {
    providers {
      juniper {
        license-type juniper deployment-scope commercial;
      }
      chef {
        license-type juniper deployment-scope commercial;
      }
    }
  }
  services {
    ssh;
    netconf {
      ssh;
    }
  }
  root-authentication {
    encrypted-password "<%= @global[:root_encrypted_password] %>";
  }
}
interfaces {
  vme {
    unit 0{
      family inet {
        address <%= @management_address %>;
      }
    }
  }
}
routing-options {
  static {
    route 0.0.0.0/0 {
      next-hop <%= @global[:management_default_gateway] %>;
      no-readvertise;
    }
  }
}
EOL
)

zeroize_config = ConfigurationTemplate.create(:name => "zeroize-halt", :template => <<EOL
system {
  host-name temp;
  root-authentication {
    encrypted-password "<%= @global[:root_encrypted_password] %>";
  }
}
event-options {
    generate-event {
        timer time-interval 120;
    }
    policy zeroize-halt {
        events timer;
        within 160 {
            trigger after 1;
        }
        then {
            execute-commands {
                commands {
                    "request system zeroize halt";
                }
            }
        }
    }
}
EOL
)

vcf_config = ConfigurationTemplate.create(:name => "vcf-config", :template => <<EOL
<% vcp_setting = {
    "qfx5100-48s" => [[0,48],[0,49]], # "A part of model number" => [[PIC, PORT], ... ],
    "qfx5100-48t" => [[0,48],[0,49]],
    "qfx5100-24q" => [[0,0],[0,1]],
} %>

system {
  host-name temp;
  root-authentication {
    encrypted-password "<%= @global[:root_encrypted_password] %>";
  }
}
event-options {
    generate-event {
        vcf-event time-interval 120;
    }
    policy vcf {
        within 180 {
            trigger after 1;
        }
        events vcf-event;
        then {
            change-configuration {
              commands {
                  "delete event-options";
              }
            }
            execute-commands {
                commands {
                    "op url http://<%= @global[:ztp_server_address] %>/slax/vcf.slax";
<% vcp_setting.each_key{|leaf_model| vcp_setting[leaf_model].each{|vcport| %>
                    "op url http://<%= @global[:ztp_server_address] %>/slax/vcp.slax pic <%= vcport[0] %> port <%= vcport[1] %>";
<% }if @model.index(leaf_model.downcase)}%>
                    "op url http://<%= @global[:ztp_server_address] %>/slax/reboot.slax";
                }
            }
        }
    }
}
interfaces {
  vme {
    unit 0{
      family inet {
        address <%= @management_address %>;
      }
    }
  }
}
routing-options {
  static {
    route 0.0.0.0/0 {
      next-hop <%= @global[:management_default_gateway] %>;
      no-readvertise;
    }
  }
}
EOL
)

shell.say ""
