use core::byte_array::ByteArray;
use super::parser::json_parser;

pub trait JsonDeserialize<T> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<T, ByteArray>;
}

// Implement JsonDeserialize for bool
impl BoolJsonDeserialize of JsonDeserialize<bool> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<bool, ByteArray> {
        json_parser::parse_bool(data, ref pos)
    }
}

// Implement JsonDeserialize for u64
impl U32JsonDeserialize of JsonDeserialize<u32> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<u32, ByteArray> {
        json_parser::parse_u32(data, ref pos)
    }
}

// Implement JsonDeserialize for u64
impl U64JsonDeserialize of JsonDeserialize<u64> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<u64, ByteArray> {
        json_parser::parse_u64(data, ref pos)
    }
}

// Implement JsonDeserialize for u128
impl U128JsonDeserialize of JsonDeserialize<u128> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<u128, ByteArray> {
        json_parser::parse_u128(data, ref pos)
    }
}

// Implement JsonDeserialize for u256
impl U256JsonDeserialize of JsonDeserialize<u256> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<u256, ByteArray> {
        json_parser::parse_u256(data, ref pos)
    }
}

// Implement JsonDeserialize for ByteArray
impl ByteArrayJsonDeserialize of JsonDeserialize<ByteArray> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<ByteArray, ByteArray> {
        json_parser::parse_string(data, ref pos)
    }
}

impl ArrayJsonDeserialize<
    T, impl TDeserialize: JsonDeserialize<T>, impl TDrop: Drop<T>,
> of JsonDeserialize<Array<T>> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<Array<T>, ByteArray> {
        json_parser::parse_array::<T, TDeserialize, TDrop>(data, ref pos)
    }
}

// Implement JsonDeserialize for felt252
impl Felt252JsonDeserialize of JsonDeserialize<felt252> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<felt252, ByteArray> {
        json_parser::parse_felt252(data, ref pos)
    }
}
