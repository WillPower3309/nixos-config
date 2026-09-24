{ inputs, ... }:

{
  flake.modules.homeManager.will = { config, pkgs, ... }: {
    programs.pi-coding-agent = {
      enable = true;
      settings = {
        defaultProvider = "llama-cpp";
        defaultModel = "qwen3.8";
      };
      models.providers.${config.programs.pi-coding-agent.settings.defaultProvider} = {
        baseUrl = "http://localhost:8080/v1";
        api = "openai-completions";
        apiKey = config.programs.pi-coding-agent.settings.defaultProvider;
        models = [{
          id = config.programs.pi-coding-agent.settings.defaultModel;
          contextWindow = 64000;
        }];
      };
    };

    home.packages = [ pkgs.lazygit ];
  };
}
