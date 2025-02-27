use serde_json::json_parser;
use serde_json::deserialize_from_byte_array;
use core::byte_array::{ByteArray, ByteArrayTrait};
use serde_json::JsonDeserialize;

#[derive(Drop, Default, SerdeJson)]
struct User {
    name: ByteArray,
    age: u64,
}

// Define the Post struct
#[derive(Drop, SerdeJson)]
struct Post {
    user: User,
    message: ByteArray,
    timestamp: u64,
}

#[cfg(test)]
mod tests {
    use super::{Post, deserialize_from_byte_array};
    use core::byte_array::ByteArray;
    use core::panic_with_felt252;

    #[test]
    fn test_correct_deserialization() {
        let json: ByteArray =
            "{\"user\":{\"name\":\"john\",\"age\":42},\"message\":\"hello\",\"timestamp\":1704748800}";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(post) => {
                assert(post.user.name == "john", 'user name should be john');
                assert(post.user.age == 42, 'user age should be 42');
                assert(post.message == "hello", 'message should be hello');
                assert(post.timestamp == 1704748800, 'timestamp should match');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Deserialization failed');
            },
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
        let json: ByteArray =
            "{\"user\":{\"name\":\"john\",\"age\":42},\"message\":\"hello\",\"timestamp\":\"not_a_number\"}";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Failed to parse timestamp", 'Wrong error'),
        }
    }
}
