require "spec_helper"

describe "Managing ClearDB", :appdirect => true do
  it_can_manage_service(
    app_name: "cleardb",
    namespace: "mysql",
    plan_name: "spark",
    service_name: "cleardb-dev",
  )
end
