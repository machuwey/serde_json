use core::byte_array::{ByteArray, ByteArrayTrait};
use core::result::{Result};
use super::JsonDeserialize;
use core::array::{ArrayTrait, Array};

pub mod json_parser {
    use super::{ByteArray, ByteArrayTrait, Result, ArrayTrait, Array};

    pub fn skip_whitespace(data: @ByteArray, ref pos: usize) {
        let space = 32_u8;
        let newline = 10_u8;
        let tab = 9_u8;
        let carriage_return = 13_u8;  // '\r'
        
        while pos < data.len() && (
            data[pos] == space || 
            data[pos] == newline || 
            data[pos] == tab || 
            data[pos] == carriage_return
        ) {
            pos += 1;
        }
    }

    pub fn parse_string(data: @ByteArray, ref pos: usize) -> Result<ByteArray, ByteArray> {
        if pos >= data.len() || data[pos] != 34_u8 { // '"'
            let error: ByteArray = "Expected string quote at position "; // + pos.try_into();
            return Result::Err(error);
        }
        pos += 1;
        let mut result: ByteArray = "";
        let mut success: bool = true;
        let mut error: ByteArray = "";

        while pos < data.len() && data[pos] != 34_u8 && success {
            if data[pos] == 92_u8 { // '\'
                pos += 1;
                if pos >= data.len() {
                    error = "Unterminated string at position "; // + pos.try_into();
                    success = false;
                    break;
                }
                let escape_char = data[pos];
                if escape_char == 34_u8 { // '\"' -> '"'
                    result.append_byte(34_u8);
                } else if escape_char == 92_u8 { // '\\' -> '\'
                    result.append_byte(92_u8);
                } else if escape_char == 47_u8 { // '\/' -> '/'
                    result.append_byte(47_u8);
                } else if escape_char == 98_u8 { // '\b' -> backspace
                    result.append_byte(8_u8);
                } else if escape_char == 102_u8 { // '\f' -> form feed
                    result.append_byte(12_u8);
                } else if escape_char == 110_u8 { // '\n' -> newline
                    result.append_byte(10_u8);
                } else if escape_char == 114_u8 { // '\r' -> carriage return
                    result.append_byte(13_u8);
                } else if escape_char == 116_u8 { // '\t' -> tab
                    result.append_byte(9_u8);
                } else {
                    error = "Invalid escape sequence at position ";
                    break;
                }
                pos += 1;
            } else {
                result.append_byte(data[pos]);
                pos += 1;
            }
        };

        if !success {
            Result::Err(error)
        } else if pos >= data.len() || data[pos] != 34_u8 {
            let error: ByteArray = "Unterminated string at position "; // + pos.try_into();
            Result::Err(error)
        } else {
            pos += 1;
            Result::Ok(result)
        }
    }

    pub fn parse_u64(data: @ByteArray, ref pos: usize) -> Result<u64, ByteArray> {
        skip_whitespace(data, ref pos);
        
        // Check if we have a quoted number
        let is_quoted = pos < data.len() && data[pos] == 34_u8; // '"'
        if is_quoted {
            pos += 1; // Skip the opening quote
        }
        
        let mut num: u64 = 0;
        let mut has_digits = false;
        while pos < data.len() && (data[pos] >= 48_u8 && data[pos] <= 57_u8) {
            num = num * 10 + (data[pos] - 48_u8).into();
            pos += 1;
            has_digits = true;
        };
        
        if is_quoted {
            // If it's quoted, we should end with a closing quote
            if pos >= data.len() || data[pos] != 34_u8 {
                return Result::Err("Unterminated number string");
            }
            pos += 1; // Skip the closing quote
        }
        
        if !has_digits {
            let error: ByteArray = "Expected number";
            return Result::Err(error);
        };
        Result::Ok(num)
    }

    pub fn parse_felt252(data: @ByteArray, ref pos: usize) -> Result<felt252, ByteArray> {
        skip_whitespace(data, ref pos);
        
        // Check if we have a quoted number
        let is_quoted = pos < data.len() && data[pos] == 34_u8; // '"'
        if is_quoted {
            pos += 1; // Skip the opening quote
        }
        
        let mut num: felt252 = 0;
        let mut has_digits = false;
        while pos < data.len() && (data[pos] >= 48_u8 && data[pos] <= 57_u8) { // '0' to '9'
            num = num * 10 + (data[pos] - 48_u8).into();
            pos += 1;
            has_digits = true;
        };
        
        if is_quoted {
            // If it's quoted, we should end with a closing quote
            if pos >= data.len() || data[pos] != 34_u8 {
                return Result::Err("Unterminated number string");
            }
            pos += 1; // Skip the closing quote
        }
        
        if !has_digits {
            let error: ByteArray = "Expected number";
            return Result::Err(error);
        };
        Result::Ok(num)
    }

    pub fn parse_object<T, impl TDeserialize: super::JsonDeserialize<T>, impl TDrop: Drop<T>>(
        data: @ByteArray, ref pos: usize
    ) -> Result<T, ByteArray> {
        skip_whitespace(data, ref pos);
        if pos >= data.len() || data[pos] != 123_u8 { // '{'
            return Result::Err("Expected object");
        }
        pos += 1;
        skip_whitespace(data, ref pos);

        let result = TDeserialize::deserialize(data, ref pos);

        let obj = result?; // This propagates error immediately

        skip_whitespace(data, ref pos);
        if pos >= data.len() || data[pos] != 125_u8 { // '}'
            return Result::Err("Expected closing brace");
        }
        pos += 1;

        Result::Ok(obj)
    }

    pub fn parse_array<T, impl TDeserialize: super::JsonDeserialize<T>, impl TDrop: Drop<T>>(
        data: @ByteArray, ref pos: usize
    ) -> Result<Array<T>, ByteArray> {
        skip_whitespace(data, ref pos);
        if pos >= data.len() || data[pos] != 91_u8 { // '['
            return Result::Err("Expected array opening bracket");
        }
        pos += 1;
        
        let mut result = array![];
        skip_whitespace(data, ref pos);
        
        if pos < data.len() && data[pos] == 93_u8 { // ']'
            pos += 1;
            return Result::Ok(result);
        }
        
        let mut success = true;
        let mut error: ByteArray = "";
        
        loop {
            skip_whitespace(data, ref pos);
            match TDeserialize::deserialize(data, ref pos) {
                Result::Ok(value) => {
                    result.append(value);
                },
                Result::Err(err) => {
                    error = err;
                    success = false;
                    break;
                }
            };
            
            skip_whitespace(data, ref pos);
            if pos >= data.len() {
                error = "Unterminated array";
                success = false;
                break;
            }
            let next_char = data[pos];
            if next_char == 93_u8 { // ']'
                pos += 1;
                break;
            } else if next_char != 44_u8 { // ','
                error = "Expected comma in array";
                success = false;
                break;
            }
            pos += 1; // Skip the comma
            skip_whitespace(data, ref pos);
        };
        
        if !success {
            Result::Err(error)
        } else {
            Result::Ok(result)
        }
    }

    pub fn parse_bool(data: @ByteArray, ref pos: usize) -> Result<bool, ByteArray> {
        skip_whitespace(data, ref pos);
        if pos + 4 <= data.len() && 
            data[pos] == 116_u8 && data[pos+1] == 114_u8 && data[pos+2] == 117_u8 && data[pos+3] == 101_u8 { // "true"
            pos += 4;
            Result::Ok(true)
        } else if pos + 5 <= data.len() && 
            data[pos] == 102_u8 && data[pos+1] == 97_u8 && data[pos+2] == 108_u8 && 
            data[pos+3] == 115_u8 && data[pos+4] == 101_u8 { // "false"
            pos += 5;
            Result::Ok(false)
        } else {
            Result::Err("Expected boolean value")
        }
    }

    pub fn parse_u128(data: @ByteArray, ref pos: usize) -> Result<u128, ByteArray> {
        skip_whitespace(data, ref pos);
        
        // Check if we have a quoted number
        let is_quoted = pos < data.len() && data[pos] == 34_u8; // '"'
        if is_quoted {
            pos += 1; // Skip the opening quote
        }
        
        let mut num: u128 = 0;
        let mut has_digits = false;
        while pos < data.len() && (data[pos] >= 48_u8 && data[pos] <= 57_u8) {
            num = num * 10 + (data[pos] - 48_u8).into();
            pos += 1;
            has_digits = true;
        };
        
        if is_quoted {
            // If it's quoted, we should end with a closing quote
            if pos >= data.len() || data[pos] != 34_u8 {
                return Result::Err("Unterminated number string");
            }
            pos += 1; // Skip the closing quote
        }
        
        if !has_digits {
            let error: ByteArray = "Expected number";
            return Result::Err(error);
        };
        Result::Ok(num)
    }
}
