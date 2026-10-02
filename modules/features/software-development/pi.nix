{ inputs, ... }:

{
  flake.modules.homeManager.will = { config, ... }: {
    programs.pi-coding-agent = {
      enable = true;
      settings = {
        defaultProvider = "llama-cpp";
        defaultModel = "qwen3.8";
      };
      context = ''
        # Environment: NixOS
        You are running on **NixOS**. Keep this in mind when giving commands or diagnosing problems. To run a package that isn't installed, use `nix run nixpkgs#<pkg>`.
      '';

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
  };
}
