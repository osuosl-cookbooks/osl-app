#
# Cookbook Name:: osl-app
# Recipe:: systemd
#
# Copyright 2016 Oregon State University
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

# user service files
# systemd_service 'openid-staging' do
#   after %w(network.target)
#   install do
#     wanted_by 'multi-user.target'
#   end
#   service do
#     exec_start '/home/openid-staging/'
#   end
# end
