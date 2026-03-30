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
