require "spec_helper"

describe "Managing MongoLab", :appdirect => true do
  it_can_manage_service(
    app_name: "mongolab",
    namespace: "mongodb",
    plan_name: "sandbox",
    service_name: "mongolab-dev",
  )
end
