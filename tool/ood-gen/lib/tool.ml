type lifecycle = [%import: Data_intf.Tool.lifecycle] [@@deriving show]

let lifecycle_of_string = function
  | "incubate" -> Ok `Incubate
  | "active" -> Ok `Active
  | "sustain" -> Ok `Sustain
  | "deprecate" -> Ok `Deprecate
  | s -> Error (`Msg ("Unknown lifecycle type: " ^ s))

let lifecycle_of_yaml = function
  | `String s -> lifecycle_of_string s
  | _ -> Error (`Msg "Expected a string for lifecycle type")

type t = [%import: Data_intf.Tool.t] [@@deriving show]

type metadata = {
  name : string;
  source : string;
  license : string;
  synopsis : string;
  description : string;
  lifecycle : lifecycle;
}
[@@deriving
  of_yaml, stable_record ~version:t ~modify:[ description ] ~add:[ slug ]]

let of_metadata m =
  metadata_to_t m ~slug:(Utils.slugify m.name) ~modify_description:(fun v ->
      v |> Markdown.Content.of_string |> Markdown.Content.render)

let decode s = Result.map of_metadata (metadata_of_yaml s)
let all () = Utils.yaml_sequence_file decode "tools.yml"

let template () =
  Format.asprintf {|
include Data_intf.Tool
let all = %a
|} (Fmt.Dump.list pp)
    (all ())
