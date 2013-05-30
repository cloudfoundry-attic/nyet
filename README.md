# Nyet: Not Yeti

CloudFoundry uses yeti test suite for broad functionality testing.

Nyet stands for Not Yeti and is a fast and simple way to test whether
CloudFoundry deployment was successful.

Nyet failure indicates a bad deployment.

Nyet uses CRUD approach as applied to a single simple application pushed
into the CloudFoundry deployment.

CRUD: Nyet:

- creates a simple Sinatra rackup app;
- ensures the app is accessible (Read);
- updates the app;
- deletes the app.

## DataDog Monitoring

Several data points can be recorded to DataDog account. Provide following
environment variables to turn it on:

```
NYET_DATADOG_API_KEY="api-key"
NYET_DATADOG_APP_KEY="app-key"
DEPLOYMENT_NAME="deployment-name"
```
