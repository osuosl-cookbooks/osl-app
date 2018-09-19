osl-app CHANGELOG
=================
This file is used to list changes made in each version of the
osl-app cookbook.

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

