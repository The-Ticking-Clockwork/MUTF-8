# MUTF-8
An implementation of the Modified UTF-8 encoder and decoder from Java,
meant for use within [TagForge](https://github.com/Nimberite-Development/TagForge-Nim),
an NBT parser and dumper!

## Usage
```nim
import mutf8

assert decodeMutf8([0xE3.byte, 0x81, 0x82]) == "あ"
assert encodeMutf8("Hello☆") == [0x48.byte, 0x65, 0x6c, 0x6c, 0x6f, 0xe2, 0x98, 0x86]
```