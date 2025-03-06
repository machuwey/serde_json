use serde_json::json_parser;
use serde_json::deserialize_from_byte_array;
use core::byte_array::{ByteArray, ByteArrayTrait};
use core::array::{Array, ArrayTrait};
use serde_json::JsonDeserialize;

#[derive(Drop, Default, SerdeJson)]
struct User {
    name: ByteArray,
    age: u64,
    verified: bool
}

#[derive(Drop, SerdeJson)]
struct Post {
    user: User,
    message: ByteArray,
    comments: Array<ByteArray>,
    timestamp: u64,
}

#[cfg(test)]
mod tests {
    use super::{Post, User, deserialize_from_byte_array};
    use core::byte_array::ByteArray;
    use core::panic_with_felt252;

    #[test]
    fn test_correct_deserialization() {
        let json: ByteArray =
            "{\"user\":{\"name\":\"john\",\"age\":42,\"verified\":false},\"message\":\"hello\",\"comments\":[],\"timestamp\":1704748800}";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(post) => {
                assert(post.user.name == "john", 'user name should be john');
                assert(post.user.age == 42, 'user age should be 42');
                assert(!post.user.verified, 'verified should be false');
                assert(post.message == "hello", 'message should be hello');
                assert(post.comments.len() == 0, 'comments should be empty');
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
            "{\"user\":{\"name\":\"john\",\"age\":42,\"verified\":false},\"message\":\"hello\",\"comments\":[],\"timestamp\":\"not_a_number\"}";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Failed to parse timestamp", 'Wrong error'),
        }
    }

    #[test]
    fn test_user_with_bool() {
        let json: ByteArray = "{\"name\":\"alice\",\"age\":25,\"verified\":true}";
        let result = deserialize_from_byte_array::<User>(json);
        match result {
            Result::Ok(user) => {
                assert(user.name == "alice", 'name should be alice');
                assert(user.age == 25, 'age should be 25');
                assert(user.verified, 'verified should be true');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Deserialization failed');
            },
        }
    }

    #[test]
    fn test_post_with_array() {
        let json: ByteArray = 
            "{\"user\":{\"name\":\"john\",\"age\":42,\"verified\":false},\"message\":\"hello\",\"comments\":[\"nice\",\"cool\"],\"timestamp\":1704748800}";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(post) => {
                assert(post.user.name == "john", 'user name should be john');
                assert(post.user.age == 42, 'user age should be 42');
                assert(!post.user.verified, 'verified should be false');
                assert(post.message == "hello", 'message should be hello');
                assert(post.comments.len() == 2, 'should have 2 comments');
                assert(post.comments[0] == @"nice", 'first comment wrong');
                assert(post.comments[1] == @"cool", 'second comment wrong');
                assert(post.timestamp == 1704748800, 'timestamp should match');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Deserialization failed');
            },
        }
    }

    #[test]
    fn test_invalid_bool() {
        let json: ByteArray = "{\"name\":\"alice\",\"age\":25,\"verified\":\"not_a_bool\"}";
        let result = deserialize_from_byte_array::<User>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Failed to parse verified", 'Wrong error'),
        }
    }

    #[test]
    fn test_invalid_array() {
        let json: ByteArray = 
            "{\"user\":{\"name\":\"john\",\"age\":42,\"verified\":false},\"message\":\"hello\",\"comments\":\"not_an_array\",\"timestamp\":1704748800}";
        let result = deserialize_from_byte_array::<Post>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Failed to parse comments", 'Wrong error'),
        }
    }
}
