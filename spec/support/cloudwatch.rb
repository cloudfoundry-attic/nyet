require "aws-sdk"

class CloudWatch
  class << self
    def configure(access_key_id, access_secret_key, deployment)
      AWS.config(
        :access_key_id => access_key_id,
        :secret_access_key => access_secret_key)
      @deployment = deployment
      @data = []
    end

    def add (data)
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

      @data << metric
    end

    def send_all
      cloud_watch = AWS::CloudWatch.new
      @data.each { |metric| cloud_watch.put_metric_data metric }
    end
  end
end