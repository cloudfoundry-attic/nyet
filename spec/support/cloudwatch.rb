require "aws-sdk"

class CloudWatch
  def initialize(access_key_id, access_secret_key, deployment)
    AWS.config(
      :access_key_id => access_key_id,
      :secret_access_key => access_secret_key)
    @deployment = deployment
  end

  def send_data (data)
    dimensions = [
      {name: "deployment", value: @deployment},
      {name: "test", value: "nyet"}
    ]

    metric = {
      namespace: "CI/#{@deployment}",
      metric_data: [
        {
          metric_name: data[:key].to_s,
          value: data[:value].to_s,
          timestamp: Time.now.utc.iso8601,
          dimensions: dimensions
        }]
    }

    cloud_watch = AWS::CloudWatch.new
    cloud_watch.put_metric_data metric
  end
end