require "spec_helper"

describe "Managing MySQL" do
  it_can_manage_service(
    app_name: "mysql",
    namespace: "mysql",
    plan_name: "100",
    service_name: "mysql",
  )
end
