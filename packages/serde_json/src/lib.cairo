pub mod parser;
pub mod traits;
use core::byte_array::ByteArray;
use core::result::Result;
use core::traits::Drop;

pub use parser::json_parser;
pub use traits::JsonDeserialize;

/// Preprocesses JSON input to handle multiline formatting 
/// by normalizing whitespace outside of quoted strings.
fn preprocess_json(json_data: ByteArray) -> ByteArray {
    let mut processed: ByteArray = "";
    let mut in_string = false;
    let mut escape = false;
    let mut idx = 0;
    
    while idx < json_data.len() {
        let char = json_data[idx];
        
        if in_string {
            // Inside a string - keep everything as is
            processed.append_byte(char);
            if char == 92_u8 { // '\'
                escape = !escape;
            } else if char == 34_u8 && !escape { // '"' (unescaped)
                in_string = false;
            } else {
                escape = false;
            }
        } else {
            // Outside a string - normalize whitespace
            if char == 34_u8 { // '"'
                in_string = true;
                processed.append_byte(char);
            } else if char == 32_u8 || char == 10_u8 || char == 9_u8 || char == 13_u8 {
                // Space, newline, tab, carriage return - ignore outside strings
                // Do nothing
            } else {
                // Any other character - keep it
                processed.append_byte(char);
            }
        }
        
        idx += 1;
    }
    
    processed
}

// This function handles JSON deserialization, including proper handling of whitespace
// between JSON elements. It supports both single-line and multiline JSON formats.
pub fn deserialize_from_byte_array<T, impl TDeserialize: JsonDeserialize<T>, impl TDrop: Drop<T>>(
    json_data: ByteArray,
) -> Result<T, ByteArray> {
    // Preprocess the JSON to normalize whitespace
    let processed_data = preprocess_json(json_data);
    
    let mut pos = 0;
    json_parser::skip_whitespace(@processed_data, ref pos);
    json_parser::parse_object::<T, TDeserialize, TDrop>(@processed_data, ref pos)
}
