require "spec_helper"

describe "Managing CloudAMQP", :appdirect => true do
  it_can_manage_service(
    app_name: "cloudamqp",
    namespace: "amqp",
    plan_name: "lemur",
    service_name: "cloudamqp-dev",
  )
end
