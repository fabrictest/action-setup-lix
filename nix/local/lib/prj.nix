let
  inherit (inputs) self l;

  id = l.pipe (self + /.config/prj_id) [
    l.readFile
    l.trim
  ];
in
{
  inherit id;
}
