osl-app CHANGELOG
=================
This file is used to list changes made in each version of the
osl-app cookbook.

4.4.3 (2023-08-25)
------------------
- Add ignore_failure true to git resources

4.4.2 (2023-07-25)
------------------
- Remove server_names_hash_bucket_size as this is now included in osl-nginx

4.4.1 (2023-06-13)
------------------
- Add Sentry URI to app2 recipe

4.4.0 (2023-06-02)
------------------
- Remove CentOS Stream 8 references

4.3.3 (2023-05-22)
------------------
- Ruby upgrade for openid-production-unicorn.service

4.3.2 (2023-05-11)
------------------
- Moved app1 staging site to ruby 3.1.4

4.3.1 (2023-05-09)
------------------
- Add RT_TOKEN

4.3.0 (2023-05-09)
------------------
- Migrate to new containerized formsender

4.2.3 (2022-05-12)
------------------
- Use system installed node binary

4.2.2 (2022-05-11)
------------------
- Update to using latest nodejs cookbook

4.2.1 (2022-03-23)
------------------
- updated ruby in production

4.2.0 (2022-03-04)
------------------
- updated ruby for openid-staging-unicorn

4.1.1 (2022-01-20)
------------------
- Upgrade redmine-replicant to 4.2.3

4.1.0 (2021-09-19)
------------------
- Create sudoers file based on service_name property

4.0.0 (2021-09-17)
------------------
- Convert app2 to use the users cookbook

3.2.0 (2021-08-26)
------------------
- Convert this cookbook to properly use systemd_unit

3.1.0 (2021-06-17)
------------------
- Set unified_mode for custom resources

3.0.1 (2021-06-11)
------------------
- Set "unicorn" ports to osl_only

3.0.0 (2021-05-25)
------------------
- Update to new osl-firewall resources

2.11.0 (2021-04-06)
-------------------
- Update Chef dependency to >= 16

2.10.1 (2021-03-24)
-------------------
- Fix logrotation for openid logs

2.10.0 (2021-02-03)
-------------------
- Replace any occurrence of yum-centos/yum-epel/yum-elrepo with osl-repos equivalents

2.9.2 (2021-01-26)
------------------
- Set user to etherpad to fix idempotency issues

2.9.1 (2021-01-20)
------------------
- Cookstyle fixes

2.9.0 (2020-12-15)
------------------
- Replicant Redmine fix & DB cleanup

2.8.2 (2020-12-11)
------------------
- Add admin password to etherpad

2.8.1 (2020-11-19)
------------------
- Add Etherpad Docker containers

2.8.0 (2020-10-23)
------------------
- CentOS 8 support

2.7.0 (2020-09-10)
------------------
- Chef 16 Fixes

2.6.1 (2020-08-22)
------------------
- Move to replicant to our custom docker image

2.6.0 (2020-08-20)
------------------
- Move Replicant's Redmine to a docker container

2.5.1 (2020-07-22)
------------------
- Update Redmine to 4.1.1

2.5.0 (2020-07-01)
------------------
- Chef 15 Fixes

2.4.1 (2020-03-10)
------------------
- Added recaptcha keys and stubbed them in test

2.4.0 (2019-12-20)
------------------
- Chef 14 post-migration fixes

2.3.1 (2019-12-11)
------------------
- Migrate away from using poise-python

2.3.0 (2019-12-03)
------------------
- Chef 14

2.2.0 (2019-11-12)
------------------
- Refactor to support systemd-3.x cookbook

2.1.1 (2019-11-12)
------------------
- Bump redmine to 4.0.5 to work around upstream issue

2.1.0 (2019-09-24)
------------------
- Add code.mulgara.org container, add docker tests

2.0.10 (2019-08-15)
-------------------
- Upgrade replicant redmine ruby

2.0.9 (2019-06-21)
------------------
- Use remove instead of delete for sudo resource

2.0.8 (2019-06-21)
------------------
- Remove and disable fenestra app

2.0.7 (2019-04-09)
------------------
- Update openid production systemd service to use Ruby 2.5.3

2.0.6 (2019-04-05)
------------------
- Update ChefSpec platforms

2.0.5 (2019-03-29)
------------------
- Update to ruby 2.5.3 for openid staging

2.0.4 (2019-02-14)
------------------
- Fix typo in timesync-web systemd configs

2.0.3 (2019-02-05)
------------------
- Fix mismatch in streamwebs' service PID file

2.0.2 (2019-01-30)
------------------
- Use simple systemd type for timesync application

2.0.1 (2018-11-09)
------------------
- Replace nodejs with osl-nodejs

2.0.0 (2018-09-19)
------------------
- Chef 13 compatibility fixes

1.11.15 (2018-02-14)
--------------------
- Enable systemd services and improve tests.

1.11.14 (2017-10-12)
--------------------
- Use correct domain for streamwebs

1.11.13 (2017-10-12)
--------------------
- Setup transfer and error logging for streamwebs

1.11.12 (2017-10-04)
--------------------
- Update media folder location for streamwebs

1.11.11 (2017-09-29)
--------------------
- Setup nginx on app3 for media serving on the streamwebs websites

1.11.10 (2017-08-04)
--------------------
- Add braintree access token for openid

1.11.9 (2017-07-03)
-------------------
- Use unicorn instead of webrick in replicant's systemd command

1.11.8 (2017-06-10)
-------------------
- update replicant redmine command to redmine 3.3.3

1.11.7 (2017-05-09)
-------------------
- only rotate new log files

1.11.6 (2017-05-04)
-------------------
- Change type from forking to simple

1.11.5 (2017-05-04)
-------------------
- Move env variable to envrionemnt property

1.11.4 (2017-05-04)
-------------------
- quick fix for replicant redmine systemd command

1.11.3 (2017-05-03)
-------------------
- Use command to run replicant redmine until we upgrade

1.11.2 (2017-04-27)
-------------------
- Set proper permissions for logrotate

1.11.1 (2017-04-15)
-------------------
- Add logrotate to OpenID staging

1.11.0 (2017-04-14)
-------------------
- Add logrotate for OpenID on app1

1.10.9 (2017-03-28)
-------------------
- fix for failing formsender systemd service

1.10.8 (2017-03-27)
-------------------
- Replicant user data bag to make kitchen for app2 work again

1.10.7 (2017-03-23)
-------------------
- Adds right amount of spacing between guincorn params.

1.10.6 (2017-03-23)
-------------------
- Enable seperate logs for formsender's gunicorn.

1.10.5 (2017-02-07)
-------------------
- Redmine replicant on app2

1.10.4 (2017-02-01)
-------------------
- Kennric/adjust streamwebs

1.10.3 (2016-12-09)
-------------------
- Installs psycopg2

1.10.2 (2016-12-09)
-------------------
- Add postgis to list of packages

1.10.1 (2016-12-05)
-------------------
- tweak gunicorn command

1.10.0 (2016-11-29)
-------------------
- Kennric/add timesync web2

1.9.4 (2016-11-23)
------------------
- Packages for Geo-Django

1.9.3 (2016-11-17)
------------------
- Add warning comment about updating NodeJS version.

1.9.2 (2016-11-15)
------------------
- fix unicorn command for iam instances

1.9.1 (2016-11-15)
------------------
- Add comments clarifying timesync port numbers.

1.9.0 (2016-11-10)
------------------
- Add timesync services to app2.

1.8.0 (2016-11-04)
------------------
- Upgrade NodeJS to LTS v6.9.1.

1.7.0 (2016-10-18)
------------------
- Kennric/streamwebs app3

1.6.0 (2016-10-03)
------------------
- add iam to app2

1.5.1 (2016-09-27)
------------------
- Kennric/app2 formsender

1.5.0 (2016-09-23)
------------------
- Kennric/app2 formsender

1.4.6 (2016-09-19)
------------------
- Cleanup and fix chefspec tests so they run and pass

1.4.5 (2016-08-08)
------------------
- remove osl-root and osl-osuadmin data bag users

1.4.4 (2016-06-29)
------------------
- Add postgresql dev packages

1.4.3 (2016-06-16)
------------------
- Use iam-staging and iam-production instead of iam

0.1.0
-----
- Initial release of osl-app

