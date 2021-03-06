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

require File.expand_path('../support/helpers', __FILE__)

describe 'postgresql::server_test' do
  include Helpers::Postgresql

  it "can connect to postgresql with pgsql_test_user" do
    require 'pg'
    conn = PG::Connection.new(
                               :host => '127.0.0.1',
                               :user => 'pgsql_test_user',
                               :password => 'test',
                               :dbname => 'pgsql_test'
                             )
    assert_match(/127\.0\.0\.1/, conn.host)
  end

  it "can create basebackup with pgsql_repl_test_user" do
    repl_dir = '/tmp/pgsql_repl_test_user'
    assert_sh("PGPASSWORD=test pg_basebackup -D #{repl_dir} -h 127.0.0.1 -U pgsql_repl_test_user")
    file("#{repl_dir}/backup_label").must_exist
  end
end
