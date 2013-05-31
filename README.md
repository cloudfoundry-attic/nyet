# Nyet: Not YETI

CloudFoundry uses YETI test suite for broad functionality testing.

Nyet stands for Not YETI and is a fast and simple way to test whether
CloudFoundry deployment was successful.

Nyet failure indicates a bad deployment.

Nyet CRUDs a single Sinatra application.


## Running Against an Existing Organization

Provide existing organization and user.
You do not have to provide admin credentials!
(This is recommended way to run against production environment.)

```
NYET_TARGET="http://api.target.com"
NYET_ORGANIZATION_NAME="some-org-name"

NYET_REGULAR_USERNAME="username"
NYET_REGULAR_PASSWORD="password"
```


## Running Without Existing Organization

Provide admin credentials and regular user credentials. Admin credentials
will be used to create and delete `nyet-org-*` organization for every test run.

```
NYET_TARGET="http://api.target.com"

NYET_ADMIN_USERNAME="admin-username"
NYET_ADMIN_PASSWORD="admin-password"

NYET_REGULAR_USERNAME="username"
NYET_REGULAR_PASSWORD="password"
```


## DataDog Monitoring

Several data points can be recorded to DataDog account. Provide following
environment variables to turn it on:

```
NYET_DATADOG_API_KEY="api-key"
NYET_DATADOG_APP_KEY="app-key"
DEPLOYMENT_NAME="deployment-name"
```
