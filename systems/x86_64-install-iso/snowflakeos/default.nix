{ inputs, system, pkgs, config, lib, snowflake, ... }:

{
  modules.snowflakeos.snowflakeosModuleManager.enable = false;
  modules.snowflakeos.nixosConfEditor.enable = false;
}
