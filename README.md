osl-app Cookbook
================
This cookbook configures various applications.

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any
requirements this cookbook has on platforms, libraries, other cookbooks,
packages, operating systems, etc.

e.g.
#### packages
- `toaster` - osl-app needs toaster to brown your bagel.

Attributes
----------
TODO: List your cookbook attributes here.

e.g.
#### osl-app::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['osl-app']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----
#### osl-app::app3
Username and password for test mulgara redmine instance:

username: admin
password: password

#### osl-app::app2
The token and recaptcha in the `formsender.json` data bag
should be set locally before development

Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `username/add_component_x`)
3. Write tests for your change
4. Write your change
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
- Author:: Oregon State University <chef@osuosl.org>

```text
Copyright 2016 Oregon State University

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
