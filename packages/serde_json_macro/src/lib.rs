use cairo_lang_macro::{derive_macro, ProcMacroResult, TokenStream};
use cairo_lang_parser::utils::SimpleParserDatabase;
use cairo_lang_syntax::node::kind::SyntaxKind::{Member, TerminalStruct, TokenIdentifier};

#[derive_macro]
pub fn serde_json(token_stream: TokenStream) -> ProcMacroResult {
    let db = SimpleParserDatabase::default();
    let (parsed, _diag) = db.parse_virtual_with_diagnostics(token_stream);
    // extract struct name in a string
    let mut struct_name = String::new();
    let mut nodes = parsed.descendants(&db);
    for node in nodes.by_ref() {
        if node.kind(&db) == TerminalStruct {
            struct_name = nodes
                .find(|node| node.kind(&db) == TokenIdentifier)
                .unwrap()
                .get_text(&db);
            break;
        }
    }
    // extract struct members in a vector of string tuples
    let members = parsed
        .descendants(&db)
        .filter(|node| node.kind(&db) == Member)
        .into_iter()
        .map(|node| {
            let member_text = node.get_text(&db);
            let member = member_text.split_once(':').unwrap();
            (member.0.trim().to_string(), member.1.trim().to_string())
        })
        .collect::<Vec<_>>();
    // generate the variables declaration section
    let mut variables_declaration = String::new();
    for (member_identifier, member_type) in members.iter() {
        variables_declaration.push_str(&indoc::formatdoc! {r#"
            let mut {member_identifier}: {member_type} = Default::default();
            let mut {member_identifier}_parsed = false;
        "#});
    }
    // generate the members parsing section
    let mut members_parsing = String::new();
    for (index, (member_identifier, member_type)) in members.iter().enumerate() {
        let if_or_else_if = if index == 0 { "if" } else { "else if" };
        let parsing_function = if member_type == "u64" {
            "parse_u64"
        } else if member_type == "ByteArray" {
            "parse_string"
        } else if member_type == "bool" {
            "parse_bool"
        } else if member_type == "felt252" {
            "parse_felt252"
        } else if member_type.starts_with("Array<") && member_type.ends_with(">") {
            "parse_array"
        } else {
            "parse_object"
        };
        members_parsing.push_str(&indoc::formatdoc! {r#"
            {if_or_else_if} field_name == "{member_identifier}" {{
                match json_parser::{parsing_function}(data, ref pos) {{
                    Result::Ok(value) => {{
                        {member_identifier} = value;
                        {member_identifier}_parsed = true;
                    }},
                    Result::Err(_) => {{
                        error = "Failed to parse {member_identifier}";
                        success = false;
                        break;
                    }},
                }};
            }}
        "#});
    }
    members_parsing.push_str(&indoc::formatdoc! {r#"
        else {{
            error = "Unknown field";
            success = false;
            break;
        }}
    "#});
    // generate the missing required field condition
    let missing_required_field_condition = members
        .iter()
        .map(|(member_identifier, _)| format!("!{member_identifier}_parsed"))
        .collect::<Vec<_>>()
        .join(" || ");
    // generate the members list
    let members_list = members
        .iter()
        .map(|(member_identifier, _)| member_identifier.clone())
        .collect::<Vec<_>>()
        .join(", ");
    // generate the implementation of JsonDeserialize trait
    ProcMacroResult::new(TokenStream::new(indoc::formatdoc! {r#"
        impl {struct_name}JsonDeserializeImpl of JsonDeserialize<{struct_name}> {{
            fn deserialize(data: @ByteArray, ref pos: usize) -> Result<{struct_name}, ByteArray> {{
                {variables_declaration}
                let mut error: ByteArray = "";
                let mut success = true;
                loop {{
                    json_parser::skip_whitespace(data, ref pos);
                    let current_char = data.at(pos).unwrap();
                    if current_char == 125_u8 {{
                        break;
                    }}
                    match json_parser::parse_string(data, ref pos) {{
                        Result::Ok(field_name) => {{
                            json_parser::skip_whitespace(data, ref pos);
                            if data.at(pos).unwrap() != 58_u8 {{
                                error = "Expected ':'";
                                success = false;
                                break;
                            }}
                            pos += 1;
                            {members_parsing}
                        }},
                        Result::Err(_) => {{
                            error = "Failed to parse field name";
                            success = false;
                            break;
                        }},
                    }};
                    json_parser::skip_whitespace(data, ref pos);
                    let next_char = data.at(pos).unwrap();
                    if next_char == 44_u8 {{
                        pos += 1;
                    }} else if next_char != 125_u8 {{
                        let mut debug_msg: ByteArray = "Unexpected char: ";
                        debug_msg.append_byte(next_char);
                        error = debug_msg;
                        success = false;
                        break;
                    }}
                }};
                if !success {{
                    Result::Err(error)
                }} else if {missing_required_field_condition} {{
                    Result::Err("Missing required field")
                }} else {{
                    Result::Ok({struct_name} {{ {members_list} }})
                }}
            }}
        }}
    "#}))
}
