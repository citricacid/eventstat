## eventstat


### Installation

#### Ruby
If not installed already, do `sudo apt-get install libmysqlclient-dev`. Next get rvm with: `gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3` followed by `curl -sSL https://get.rvm.io | bash -s stable`. Close and reopen the terminal, then invoke `source ~/.rvm/scripts/rvm` and `rvm install 2.3` (user may need to be in sudoers list for this step). Grab bundler with `gem install bundler`, change to the app directory and do `bundle install`.

#### MySQL

To create the database, open MySQL and do `CREATE DATABASE eventstat`. Set up the user for the main script as follows: `CREATE USER 'eventstat'@'localhost' IDENTIFIED BY 'secret';` and `GRANT ALL PRIVILEGES on eventstat.* to 'eventstat'@'localhost'` Open a new terminal to `cp settings.rb.example settings.rb`, then install the database structure with `ruby db/schema.rb`


#### Logs
From the app folder, do `mkdir logs && touch logs/error.log && touch logs/eventstat.txt`

#### Web server

There are many ways to set up the server, for example as a standalone Thin server or as a Phusion Passenger. For local testing, `ruby webserver.rb` should start it on port 5100.
