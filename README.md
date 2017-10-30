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


### Design (WIP)
Event attributes:

subcategory_id: value can refer to either internal or district subcategory.
aggregated_subcategory_id: Only set when subcategory is an instance of DsitrictSubcategory. As with category_id, it's redundant, but code-saving.
district_category_id:
category_id: This value is inferred from subcategory_id and event_type. Strictly speaking, it might be somewhat redundant, but having it allows for clearer code elsewhere in the system.
marked_for_deletion: true means event is excluded from statistics results and will be deleted during next locking phase (only superuser can delete directly)
is_locked: locked events can only be altered by superuser
added_after_lock: non-vital attribute, intended for monitoring how many events are added to a period after it was locked.
