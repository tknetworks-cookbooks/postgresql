#
# Author:: Ken-ichi TANABE (<nabeken@tknetworks.org>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
define :createuser,
       :createdb    => true,
       :createrole  => false,
       :login       => true,
       :superuser   => false,
       :replication => false,
       :password    => nil do
  raise 'Please specify a password' unless params[:password]

  # issue special sql for replication user
  if params[:replication]
    ruby_block "postgresql-create-role-replication-#{params[:name]}" do
      block do
        sql = Tempfile.open("create-role-replication-#{params[:name]}.sql")
        begin
          sql.puts "CREATE ROLE #{params[:name]} LOGIN REPLICATION PASSWORD '#{params[:password]}';"
          sql.close
          `cat #{sql.path} | su postgres -c \"psql -U postgres\"`
          sql.unlink
        rescue
          sql.close!
        end
      end
      not_if do
        `su postgres -c "echo \\"SELECT count(*) FROM pg_roles WHERE rolname = '#{params[:name]}';\\" | psql -A -t -U postgres postgres"`.strip == "1"
      end
    end
  else
    args = {
      :createdb   => {true => "--createdb",   false => "--no-createdb"},
      :createrole => {true => "--createrole", false => "--no-createrole"},
      :login      => {true => "--login",      false => "--no-login"},
      :superuser  => {true => "--superuser",  false => "--no-superuser"},
    }
    cmd = "createuser"
    args.keys.each do |k|
      cmd += " #{args[k][params[k]]}"
    end

    ruby_block "postgresql-alter-role-#{params[:name]}" do
      action :nothing
      block do
        sql = Tempfile.open("alter-role-#{params[:name]}.sql")
        begin
          sql.puts "ALTER ROLE #{params[:name]} WITH ENCRYPTED PASSWORD '#{params[:password]}';"
          sql.close
          `cat #{sql.path} | su postgres -c \"psql -U postgres\"`
          sql.unlink
        rescue
          sql.close!
        end
      end
    end

    execute "postgresql-createuser-#{params[:name]}" do
      user "postgres"
      command "#{cmd} #{params[:name]}"
      not_if do
        `su postgres -c "echo \\"SELECT count(*) FROM pg_roles WHERE rolname = '#{params[:name]}';\\" | psql -A -t -U postgres postgres"`.strip == "1"
      end
      if params[:password]
        notifies :create, "ruby_block[postgresql-alter-role-#{params[:name]}]"
      end
    end
  end
end

define :createdb do
  execute "postgresql-createdb-#{params[:name]}" do
    user 'postgres'
    command "createdb #{params[:name]}"
    not_if do
      `su postgres -c "echo \\"SELECT count(*) FROM pg_database WHERE datname = '#{params[:name]}';\\" | psql -A -t -U postgres postgres"`.strip == "1"
    end
  end
end
