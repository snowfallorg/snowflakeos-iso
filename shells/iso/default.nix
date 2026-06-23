{
  mkShell,
  nixd,
  nixfmt,
  statix,
  deadnix,
}:

mkShell {
  nativeBuildInputs = [
    nixd
    nixfmt
    statix
    deadnix
  ];
}
