require "spec_helper"

describe "Managing ElephantSQL", :appdirect => true do
  it_can_manage_service(
    app_name: "elephantsql",
    namespace: "pg",
    plan_name: "turtle",
    service_name: "elephantsql-dev",
  )
end
