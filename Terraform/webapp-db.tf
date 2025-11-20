resource "azurerm_resource_group" "rg" {
  name     = var.resource-group-name
  location = var.location
}

resource "azurerm_service_plan" "plan" {
  name                = "example-appserviceplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "F1"
}

resource "azurerm_windows_web_app" "app-service" {
  name                = var.app-service-name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=tcp:${azurerm_mssql_server.sqldb.fully_qualified_domain_name} Database=${azurerm_mssql_database.db.name};User ID=${azurerm_mssql_server.sqldb.administrator_login};Password=${azurerm_mssql_server.sqldb.administrator_login_password};Trusted_Connection=False;Encrypt=True;"
  }
}

resource "azurerm_mssql_server" "sqldb" {
  name                         = "terraform-sqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "houssem"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "db" {
  name      = "terraform-sqldatabase"
  server_id = azurerm_mssql_server.sqldb.id
  sku_name  = "Basic"

  tags = {
    environment = "production"
  }
}
