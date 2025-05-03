use core::array::Array;
use core::byte_array::{ByteArray, ByteArrayTrait};
use serde_json::{JsonDeserialize, deserialize_from_byte_array, json_parser};

#[derive(Drop, Default, SerdeJson)]
struct Event {
    id: felt252,
    name: ByteArray,
    active: bool,
    timestamp: u256,
}

#[derive(Drop, Default, SerdeJson)]
struct User {
    name: ByteArray,
    age: u64,
    verified: bool,
}

#[derive(Drop, SerdeJson)]
struct Post {
    user: User,
    message: ByteArray,
    comments: Array<ByteArray>,
    timestamp: u64,
}

#[derive(Drop, SerdeJson, Default)]
struct TestBigNumber {
    test_value: u128,
    description: ByteArray,
}

#[cfg(test)]
mod tests {
    use core::byte_array::ByteArray;
    use core::panic_with_felt252;
    use super::{Event, Post, TestBigNumber, User, deserialize_from_byte_array};

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

    #[test]
    fn test_event_with_felt252() {
        let json: ByteArray =
            "{\"id\":123456,\"name\":\"launch\",\"active\":true,\"timestamp\":115792089237316195423570985008687907853269984665640564039457584007913129639935}";
        let result = deserialize_from_byte_array::<Event>(json);
        match result {
            Result::Ok(event) => {
                assert(event.id == 123456, 'id should be 123456');
                assert(event.name == "launch", 'name should be launch');
                assert(event.active, 'active should be true');
                assert(
                    event
                        .timestamp == 115792089237316195423570985008687907853269984665640564039457584007913129639935_u256,
                    'timestamp should be max u256',
                );
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Deserialization failed');
            },
        }
    }

    #[test]
    fn test_invalid_felt252() {
        let json: ByteArray = "{\"id\":\"not_a_number\",\"name\":\"launch\",\"active\":true}";
        let result = deserialize_from_byte_array::<Event>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Failed to parse id", 'Wrong error'),
        }
    }

    #[test]
    fn test_missing_felt252() {
        let json: ByteArray = "{\"name\":\"launch\",\"active\":true}";
        let result = deserialize_from_byte_array::<Event>(json);
        match result {
            Result::Ok(_) => panic(array!['Expected failure']),
            Result::Err(e) => assert(e == "Missing required field", 'Wrong error'),
        }
    }

    #[test]
    fn test_quoted_numbers() {
        // Test with quoted u64
        let json: ByteArray = "{\"name\":\"alice\",\"age\":\"25\",\"verified\":true}";
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

        // Test with quoted felt252 and u256
        let json: ByteArray =
            "{\"id\":\"123456\",\"name\":\"launch\",\"active\":true,\"timestamp\":\"115792089237316195423570985008687907853269984665640564039457584007913129639935\"}";
        let result = deserialize_from_byte_array::<Event>(json);
        match result {
            Result::Ok(event) => {
                assert(event.id == 123456, 'id should be 123456');
                assert(event.name == "launch", 'name should be launch');
                assert(event.active, 'active should be true');
                assert(
                    event
                        .timestamp == 115792089237316195423570985008687907853269984665640564039457584007913129639935_u256,
                    'timestamp should be max u256',
                );
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Deserialization failed');
            },
        }
    }

    #[test]
    fn test_u128_parsing() {
        // Test with unquoted u128
        let json: ByteArray =
            "{\"test_value\":340282366920938463463374607431768211455,\"description\":\"max u128\"}";
        let result = deserialize_from_byte_array::<TestBigNumber>(json);
        match result {
            Result::Ok(big_num) => {
                assert(
                    big_num.test_value == 340282366920938463463374607431768211455_u128,
                    'value should be max u128',
                );
                assert(big_num.description == "max u128", 'description should match');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Deserialization failed');
            },
        }

        // Test with quoted u128
        let json: ByteArray = "{\"test_value\":\"9223372036854775808\",\"description\":\"2^63\"}";
        let result = deserialize_from_byte_array::<TestBigNumber>(json);
        match result {
            Result::Ok(big_num) => {
                assert(big_num.test_value == 9223372036854775808_u128, 'value should be 2^63');
                assert(big_num.description == "2^63", 'description should match');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Deserialization failed');
            },
        }
    }

    #[test]
    fn test_multiline_json() {
        // Test with a multiline formatted JSON with significant whitespace and newlines
        let json: ByteArray = "{\n  \"name\": \"alice\",\n  \"age\": 25,\n  \"verified\": true\n}";
        let result = deserialize_from_byte_array::<User>(json);
        match result {
            Result::Ok(user) => {
                assert(user.name == "alice", 'name should be alice');
                assert(user.age == 25, 'age should be 25');
                assert(user.verified, 'verified should be true');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Failed');
            },
        }
    }

    #[test]
    fn test_deeply_nested_multiline_json() {
        // Test with a deeply nested multiline JSON with various indentation levels
        let json: ByteArray = "{\n  \"user\": {\n    \"name\": \"john\",\n    \"age\": 42,\n    \"verified\": false\n  },\n  \"message\": \"hello\",\n  \"comments\": [\n    \"nice\",\n    \"cool\"\n  ],\n  \"timestamp\": 1704748800\n}";
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
                panic_with_felt252('Failed');
            },
        }
    }

    #[test]
    fn test_mixed_whitespace_styles() {
        // Test with a mix of tabs, spaces, and various whitespace characters
        let json: ByteArray = "{\r\n\t\"name\":\t\"bob\",\r\n  \"age\":   30,\r\n\t\t\"verified\":  true\r\n}";
        let result = deserialize_from_byte_array::<User>(json);
        match result {
            Result::Ok(user) => {
                assert(user.name == "bob", 'name should be bob');
                assert(user.age == 30, 'age should be 30');
                assert(user.verified, 'verified should be true');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Failed');
            },
        }
    }

    #[test]
    fn test_preserve_string_whitespace() {
        // Test that whitespace within strings is preserved correctly
        let json: ByteArray = "{\n  \"name\": \"john \t doe\",\n  \"age\": 25,\n  \"verified\": true\n}";
        let result = deserialize_from_byte_array::<User>(json);
        match result {
            Result::Ok(user) => {
                assert(user.name == "john \t doe", 'whitespace in string preserved');
                assert(user.age == 25, 'age should be 25');
                assert(user.verified, 'verified should be true');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Failed');
            },
        }
    }

    #[test]
    fn test_multiline_complex_proof() {
        // Test with a complex multiline JSON typical for proof objects
        // Using only fields that exist in the Event struct (id, name, active)
        let json: ByteArray = "{\n  \"id\": 123456,\n  \"name\": \"Proof Object\",\n  \"active\": true,\n  \"timestamp\": 0\n}";
        
        let result = deserialize_from_byte_array::<Event>(json);
        match result {
            Result::Ok(event) => {
                assert(event.id == 123456, 'id should be 123456');
                assert(event.name == "Proof Object", 'name should match');
                assert(event.active, 'active should be true');
            },
            Result::Err(e) => {
                println!("error: {}", e);
                panic_with_felt252('Failed');
            },
        }
    }
}
