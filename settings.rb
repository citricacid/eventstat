module Settings

HTML_DEST_PATH = "./www/"
LOG_PATH = "./logs/"

SECRET = 'i would say but i forgot'
SESSION_KEY = 'marshmallow man'
PW = 'secret'
PWADMIN = 'secret2'


DB = {:adapter =>       'mysql2',
                        :database => 'eventstat',
                        :username => 'eventstat',
                        :password => 'secret',
                        :host => 'localhost',
                        :pool => 5,
                        :reconnect => true}

DBWEB = {:adapter =>    'mysql2',
                        :database => 'eventstat',
                        :username => 'eventstat',
                        :password => 'secret',
                        :host => 'localhost',
                        :pool => 5,
                        :reconnect => true}

end
