import std/[
  unittest
]

import mutf8

# Tests inspired by https://github.com/sciencesakura/mutf-8/blob/master/src/index.test.ts!

suite "Modified UTF-8":
  block: # Decoding testsuite
    test "Empty string decoding":
      check decodeMutf8(newSeq[byte]()) == ""

    test "1-byte character decoding":
      check decodeMutf8([0x41.byte]) == "A"

    test "2-byte character decoding":
      check decodeMutf8([0xC2.byte, 0xA9]) == "©"

    test "3-byte character decoding":
      check decodeMutf8([0xE3.byte, 0x81, 0x82]) == "あ"

    test "Supplementary character decoding":
      check decodeMutf8([0xED.byte, 0xA1, 0x80, 0xED, 0xB4, 0x94]) == "𠄔"

    test "Null character decoding":
      check decodeMutf8([0xC0.byte, 0x80]) == "\0"

    test "Decode a string":
      check decodeMutf8([
        0x48.byte, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0xe4,
        0xb8, 0x96, 0xe7, 0x95, 0x8c, 0x21, 0x20, 0x53,
        0x61, 0x6e, 0x74, 0xc3, 0xa9, 0xed, 0xa0, 0xbc,
        0xed, 0xbd, 0xbb
      ]) == "Hello 世界! Santé🍻"

    test "Decode another string":
      check decodeMutf8([0x48.byte, 0x65, 0x6c, 0x6c, 0x6f, 0xe2, 0x98, 0x86]) == "Hello☆"

    test "Decode failure":
      expect ModifiedUnicodeDecodeError:
        discard decodeMutf8([0x61.byte, 0x80, 0x62])
        discard decodeMutf8([0x61.byte, 0xc0, 0x40, 0x62])
        discard decodeMutf8([0x61.byte, 0xe0, 0x40, 0x80, 0x62])

  block: # Encoding testsuite
    test "Empty string encoding":
      check encodeMutf8("") == newSeq[byte]()

    test "1-byte character encoding":
      check encodeMutf8("A") == [0x41.byte]

    test "2-byte character encoding":
      check encodeMutf8("©") == @[0xC2.byte, 0xA9]

    test "3-byte character encoding":
      check encodeMutf8("あ") == @[0xE3.byte, 0x81, 0x82]

    test "Supplementary character encoding":
      check encodeMutf8("𠄔") == @[0xED.byte, 0xA1, 0x80, 0xED, 0xB4, 0x94]

    test "Null character encoding":
      check encodeMutf8("\0") == [0xC0.byte, 0x80]

    test "Encode a string":
      check encodeMutf8("Hello 世界! Santé🍻") == [
        0x48.byte, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0xe4,
        0xb8, 0x96, 0xe7, 0x95, 0x8c, 0x21, 0x20, 0x53,
        0x61, 0x6e, 0x74, 0xc3, 0xa9, 0xed, 0xa0, 0xbc,
        0xed, 0xbd, 0xbb
      ]

    test "Encode another string":
      check encodeMutf8("Hello☆") == [0x48.byte, 0x65, 0x6c, 0x6c, 0x6f, 0xe2, 0x98, 0x86]