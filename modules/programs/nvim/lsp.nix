{ lib }:
let
  azurePipelineSchemaPatterns = [
    "azure-pipelines.yml"
    "azure-pipelines.yaml"
    "azure-pipelines/*.yml"
    "azure-pipelines/*.yaml"
    ".azure-pipelines/*.yml"
    ".azure-pipelines/*.yaml"
    "**/azure-pipelines*.y?(a)ml"
    "/azure-pipeline*.y*l"
    "/*.azure*"
    "Azure-Pipelines/**/*.y*l"
    "Pipelines/*.y*l"
  ];
  azurePipelineSchemaStoreUrl = "https://json.schemastore.org/azure-pipelines.json";
  azurePipelineServiceSchemaUrl = "https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json";
in
{
  enable = true;
  servers = {
    nixd.enable = true;
    lua_ls = {
      enable = true;
      settings.Lua.completion.callSnippet = "Replace";
    };
    bashls.enable = true;
    pyright.enable = true;
    ts_ls.enable = true; # om din Nixvim-version kräver tsserver: byt till tsserver
    rust_analyzer = {
      enable = true;
      installCargo = true;
      installRustc = true;
    };
    gopls.enable = true;
    jsonls.enable = true;

    terraformls.enable = true;

    yamlls = {
      enable = true;

      # Azure DevOps Pipelines via YAML-LS + SchemaStore
      settings = {
        redhat.telemetry.enabled = false;
        yaml = {
          validate = true;
          hover = true;
          completion = true;
          format.enable = true;
          schemaStore = {
            enable = true;
            url = "https://www.schemastore.org/api/json/catalog.json";
          };
          # Point specifically at the Azure Pipelines schema
          schemas = {
            "${azurePipelineSchemaStoreUrl}" = azurePipelineSchemaPatterns;
          };
        };
      };

      # Don't attach to docker-compose files
      extraOptions.on_attach.__raw = ''
        function(client, bufnr)
          local name = vim.api.nvim_buf_get_name(bufnr)
          if name:match("docker%-compose%.ya?ml$") or name:match("compose%.ya?ml$") then
            client:stop()
          end
        end
      '';
    };

    azure_pipelines_ls = {
      enable = true;
      package = null;
      cmd = [
        "azure-pipelines-language-server"
        "--stdio"
      ];
      settings = {
        yaml = {
          schemas."${azurePipelineServiceSchemaUrl}" = azurePipelineSchemaPatterns;
        };
      };
    };

    docker_compose_language_service.enable = lib.mkForce false;
    dockerls = {
      enable = true;

      filetypes = [
        "dockerfile"
        "json"
        "hcl"
      ];
      rootMarkers = [
        "compose.yaml"
        "compose.yml"
        "docker-compose.yaml"
        "docker-compose.yml"
        "docker-bake.hcl"
        "docker-bake.json"
        "Dockerfile"
        ".git"
      ];
      extraOptions.on_attach.__raw = ''
        function(client, bufnr)
          local ft = vim.bo[bufnr].filetype
          if ft == "json" or ft == "hcl" then
            local name = vim.api.nvim_buf_get_name(bufnr)
            if not name:match("docker%-bake%.json$") and not name:match("docker%-bake%.hcl$") then
              client:stop()
            end
          end
        end
      '';
    };
  }; # END servers
}
