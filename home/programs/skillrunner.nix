{ skillrunner, system, config, lib, pkgs, ... }:
let
  package = skillrunner.packages.${system}.default;
  isLinux = pkgs.stdenv.isLinux;
in lib.mkIf isLinux {
  home.packages = [ package ];

  # Symlink skills into Claude Code's skill directory
  home.file.".claude/skills/schedule/SKILL.md".source =
    "${package}/share/skillrunner/SKILL.md";
  home.file.".claude/skills/schedule-setup/SKILL.md".source =
    "${package}/share/skillrunner/SETUP_SKILL.md";

  # Create runtime directories via activation script
  home.activation.skillrunner-dirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.config/skillrunner"/{logs/output,locks}
    if [ ! -f "${config.home.homeDirectory}/.config/skillrunner/config.json" ]; then
      echo '{"version": 1, "projects": [], "schedules": []}' > \
        "${config.home.homeDirectory}/.config/skillrunner/config.json"
    fi
    echo '{"last_wake": null, "pid": null, "version": 1}' > \
      "${config.home.homeDirectory}/.config/skillrunner/state.json"
    if [ ! -f "${config.home.homeDirectory}/.config/skillrunner/secrets.env" ]; then
      echo '# SKILLRUNNER_TELEGRAM_TOKEN=your_bot_token_here' > \
        "${config.home.homeDirectory}/.config/skillrunner/secrets.env"
      chmod 600 "${config.home.homeDirectory}/.config/skillrunner/secrets.env"
    fi
  '';

  # Systemd user service + timer
  systemd.user.services.skillrunner = {
    Unit.Description = "SkillRunner — scheduled Claude Code skill executor";
    Service = {
      Type = "oneshot";
      ExecStart = "${package}/bin/skillrunner-daemon";
      Nice = 10;
    };
  };

  systemd.user.timers.skillrunner = {
    Unit.Description = "SkillRunner wake timer";
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
