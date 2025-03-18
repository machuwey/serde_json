pub mod parser;
pub mod traits;
use core::byte_array::ByteArray;
use core::result::Result;
use core::traits::Drop;

pub use parser::json_parser;
pub use traits::JsonDeserialize;

pub fn deserialize_from_byte_array<T, impl TDeserialize: JsonDeserialize<T>, impl TDrop: Drop<T>>(
    json_data: ByteArray,
) -> Result<T, ByteArray> {
    let mut pos = 0;
    json_parser::skip_whitespace(@json_data, ref pos);
    json_parser::parse_object::<T, TDeserialize, TDrop>(@json_data, ref pos)
}
