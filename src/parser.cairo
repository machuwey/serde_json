use core::byte_array::{ByteArray, ByteArrayTrait};
use core::result::{Result};
use super::JsonDeserialize;

pub mod json_parser {
    use super::{ByteArray, ByteArrayTrait, Result};

    pub fn skip_whitespace(data: @ByteArray, ref pos: usize) {
        let space = 32_u8;
        let newline = 10_u8;
        let tab = 9_u8;
        while pos < data.len() && (data[pos] == space || data[pos] == newline || data[pos] == tab) {
            pos += 1;
        }
    }

    pub fn parse_string(data: @ByteArray, ref pos: usize) -> Result<ByteArray, ByteArray> {
        if pos >= data.len() || data[pos] != 34_u8 { // '"'
            let error: ByteArray = "Expected string quote";
            return Result::Err(error);
        }
        pos += 1;
        let mut result: ByteArray = "";
        while pos < data.len() && data[pos] != 34_u8 {
            result.append_byte(data[pos]);
            pos += 1;
        };
        if pos >= data.len() {
            let error: ByteArray = "Unterminated string";
            return Result::Err(error);
        }
        pos += 1;
        Result::Ok(result)
    }

    pub fn parse_u64(data: @ByteArray, ref pos: usize) -> Result<u64, ByteArray> {
        skip_whitespace(data, ref pos);
        let mut num: u64 = 0;
        let mut has_digits = false;
        while pos < data.len() && (data[pos] >= 48_u8 && data[pos] <= 57_u8) {
            num = num * 10 + (data[pos] - 48_u8).into();
            pos += 1;
            has_digits = true;
        };
        if !has_digits {
            let error: ByteArray = "Expected number";
            return Result::Err(error);
        };
        Result::Ok(num)
    }
    
    pub fn parse_object<T, impl TDeserialize: super::JsonDeserialize<T>, impl TDrop: Drop<T>>(
    data: @ByteArray, ref pos: usize
) -> Result<T, ByteArray> {
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
}
