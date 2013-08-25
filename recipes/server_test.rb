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
include_recipe "postgresql::ruby"
include_recipe "postgresql::server"

createuser 'pgsql_test_user' do
  # test
  password 'md57575f73cbe370fb93579b62a8c72e6f6'
end

createuser 'pgsql_repl_test_user' do
  replication true
  # test
  password 'md51bb5c3518155338763483c8223e3083b'
end

createdb 'pgsql_test'

node.set['postgresql']['pg_hba'] = [
  {:comment => '# pgsql_test_user',
   :type    => 'host',
   :method  => 'md5',
   :addr    => '127.0.0.1/32',
   :db      => 'pgsql_test',
   :user    => 'pgsql_test_user'},
  {:comment => '# pgsql_repl_test_user',
   :type    => 'host',
   :method  => 'md5',
   :addr    => '127.0.0.1/32',
   :db      => 'replication',
   :user    => 'pgsql_repl_test_user'}
] + node['postgresql']['pg_hba']

node.set['postgresql']['config'] = node['postgresql']['config'].merge({
  'wal_level' => 'hot_standby',
  'max_wal_senders' => 3,
  'archive_mode' => false,
  'wal_keep_segments' => 9
})
