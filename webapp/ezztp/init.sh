
bundle install && \
RACK_ENV=production bundle exec rake db:drop RACK_ENV=production && \
RACK_ENV=production bundle exec rake db:create && \
RACK_ENV=production bundle exec rake db:migrate && \
RACK_ENV=production bundle exec rake db:seed
