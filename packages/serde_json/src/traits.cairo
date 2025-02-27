use core::byte_array::ByteArray;

pub trait JsonDeserialize<T> {
    fn deserialize(data: @ByteArray, ref pos: usize) -> Result<T, ByteArray>;
}