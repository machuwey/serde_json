use serde_json::json_parser;
use serde_json::deserialize_from_byte_array;
use core::byte_array::{ByteArray, ByteArrayTrait};
use serde_json::JsonDeserialize;

// Define the Post struct
#[derive(Drop)]
struct Post {
    user: ByteArray,
    message: ByteArray,
    timestamp: u64
}

// Trait definition for deserialization
trait PostDeserialize<T> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<Post, ByteArray>;
}
impl PostDeserializeImpl of PostDeserialize<Post> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<Post, ByteArray> {
        // Now just parse the object fields.
        let mut user: ByteArray = "";
        let mut message: ByteArray = "";
        let mut timestamp: u64 = 0;
        let mut user_parsed = false;
        let mut message_parsed = false;
        let mut timestamp_parsed = false;
        let mut error: ByteArray = "";
        let mut success = true;

        loop {
            json_parser::skip_whitespace(data, ref pos);
            let current_char = data.at(pos).unwrap();
            // Here we expect a closing brace, but we let the external parser (parse_object) check that.
            if current_char == 125_u8 { // '}'
                break;
            }

            // Parse field name.
            match json_parser::parse_string(data, ref pos) {
                Result::Ok(field_name) => {
                    json_parser::skip_whitespace(data, ref pos);
                    if data.at(pos).unwrap() != 58_u8 { // ':'
                        error = "Expected ':'";
                        success = false;
                        break;
                    }
                    pos += 1;

                    if field_name == "user" {
                        match json_parser::parse_string(data, ref pos) {
                            Result::Ok(value) => {
                                user = value;
                                user_parsed = true;
                            },
                            Result::Err(_) => {
                                error = "Failed to parse user";
                                success = false;
                                break;
                            }
                        }
                    } else if field_name == "message" {
                        match json_parser::parse_string(data, ref pos) {
                            Result::Ok(value) => {
                                message = value;
                                message_parsed = true;
                            },
                            Result::Err(_) => {
                                error = "Failed to parse message";
                                success = false;
                                break;
                            }
                        }
                    } else if field_name == "timestamp" {
                        match json_parser::parse_u64(data, ref pos) {
                            Result::Ok(value) => {
                                timestamp = value;
                                timestamp_parsed = true;
                            },
                            Result::Err(_) => {
                                error = "Invalid timestamp";
                                success = false;
                                break;
                            }
                        }
                    } else {
                        error = "Unknown field";
                        success = false;
                        break;
                    }
                },
                Result::Err(_) => {
                    error = "Failed to parse field name";
                    success = false;
                    break;
                }
            };

            json_parser::skip_whitespace(data, ref pos);
            let next_char = data.at(pos).unwrap();
            if next_char == 44_u8 { // ','
                pos += 1;
            } else if next_char != 125_u8 { // Not '}'
                let mut debug_msg: ByteArray = "Unexpected char: ";
                debug_msg.append_byte(next_char);
                error = debug_msg;
                success = false;
                break;
            }
        };

        if !success {
            Result::Err(error)
        } else if !user_parsed || !message_parsed || !timestamp_parsed {
            Result::Err("Missing required field")
        } else {
            Result::Ok(Post { user, message, timestamp })
        }
    }
}

// Implement JsonDeserialize for Post
impl PostJsonDeserialize of JsonDeserialize<Post> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<Post, ByteArray> {
        PostDeserialize::<Post>::deserialize(data, ref pos)
    }
}

#[cfg(test)]
mod tests {
    use super::{Post, deserialize_from_byte_array};
    use core::byte_array::ByteArray;
    use core::panic_with_felt252;

    #[test]
    fn test_correct_deserialization() {
        let json: ByteArray = "{\"user\":\"john\",\"message\":\"hello\",\"timestamp\":1704748800}";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(post) => {
                assert(post.user == "john", 'user should be john');
                assert(post.message == "hello", 'message should be hello');
                assert(post.timestamp == 1704748800, 'timestamp should match');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Deserialization failed');
            }
        }
    }

    #[test]
    fn test_invalid_json() {
        let json: ByteArray = "not_a_json";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Expected object", 'Wrong error'),
        }
    }

    #[test]
    fn test_missing_braces() {
        let json: ByteArray = "user:john";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Expected object", 'Wrong error'),
        }
    }

    #[test]
    fn test_invalid_timestamp() {
        let json: ByteArray = "{\"user\":\"john\",\"message\":\"hello\",\"timestamp\":\"not_a_number\"}";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Invalid timestamp", 'Wrong error'), // Adjusted to match "Invalid timestamp"
        }
    }
}