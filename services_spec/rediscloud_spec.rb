require "spec_helper"

describe "Managing RedisCloud", :appdirect => true do
  pending "Rediscloud disabled our automatic testing and returns no credentials" do
    it_can_manage_service(
      app_name: "rediscloud",
      namespace: "redis",
      plan_name: "20mb",
      service_name: "rediscloud-dev",
    )
  end
end
