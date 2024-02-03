#! Copyright 2024 Yu-Vitaqua-fer-Chronos
#!
#! Licensed under the Apache License, Version 2.0 (the "License");
#! you may not use this file except in compliance with the License.
#! You may obtain a copy of the License at
#!
#!     http://www.apache.org/licenses/LICENSE-2.0
#!
#! Unless required by applicable law or agreed to in writing, software
#! distributed under the License is distributed on an "AS IS" BASIS,
#! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#! See the License for the specific language governing permissions and
#! limitations under the License.

# Heavily based on https://github.com/TkTech/mutf8/blob/master/mutf8/mutf8.py!
import std/unicode

type
  ModifiedUnicodeDecodeError* = object of CatchableError

func decodeMutf8*(s: openArray[byte]): string =
  ## Decodes a byte array to standard UTF-8 (in a Nim string).
  var sIx = 0
  let sLen = s.len

  while sIx < sLen:
    let b1 = s[sIx]
    inc sIx

    if b1 == 0:
      raise newException(ModifiedUnicodeDecodeError, "Embedded NULL byte in input, starting at position" &
        $(sIx - 1) & ", and ending as position " & $sIx & ".")

    elif b1 < 0x80:  # ASCII/one-byte codepoint.
      result.add(b1.char)

    elif (b1 and 0xE0) == 0xC0:  # Two-byte codepoint.
      if sIx >= sLen:
        raise newException(ModifiedUnicodeDecodeError, "2-byte codepoint started, but the " &
          "input too is short to finish, starting at position " & $(sIx - 1) & ", and ending at position " &
          $sIx & ".")

      result.add Rune(((b1 and 0x1F) shl 0x06) or (s[sIx] and 0x3F))
      inc sIx

    elif (b1 and 0xF0) == 0xE0:  # Three-byte codepoint.
      if (sIx + 1) >= sLen:
        raise newException(ModifiedUnicodeDecodeError, "3-byte or 6-byte codepoint started, but the input" &
          " was too short to finish, starting at position " & $(sIx - 1) & ", and ending as position " &
          $sIx & ".")

      let b2 = s[sIx]
      let b3 = s[sIx + 1]

      if (b1 == 0xED) and ((b2 and 0xF0) == 0xA0):  # Possible six-byte codepoint.
        if (sIx + 4) >= sLen:
          raise newException(ModifiedUnicodeDecodeError, "3-byte or 6-byte codepoint started, but the input" &
            " was too short to finish, starting at position " & $(sIx - 1) & ", and ending as position " &
            $sIx & ".")

        let b4 = s[sIx + 2]
        let b5 = s[sIx + 3]
        let b6 = s[sIx + 4]

        if (b4 == 0xED) and ((b5 and 0xF0) == 0xB0):  # Definite six-byte codepoint.
          result.add Rune(0x10000.int32 + (
            ((b2.int32 and 0x0F) shl 0x10) or
            ((b3.int32 and 0x3F) shl 0x0A) or
            ((b5.int32 and 0x0F) shl 0x06) or
            (b6.int32 and 0x3F)
          ))
          sIx += 5
          continue

      result.add Rune(
        ((b1.int32 and 0x0F) shl 0x0C) or
        ((b2.int32 and 0x3F) shl 0x06) or
        (b3.int32 and 0x3F)
      )
      sIx += 2
    else:
      raise newException(ModifiedUnicodeDecodeError, "Invalid MUTF8 encoding.")

func encodeMutf8*(u: string): seq[byte] =
  ## Encodes a strin into Modified UTF-8.
  for cc in u.runes:
    let c = cc.int32

    if c == 0x00:
      result &= [0xC0.byte, 0x80]

    elif c <= 0x7F:
      result.add cast[seq[byte]]($cc)

    elif c <= 0x7FF:
      result.add (0xC0 or (0x1F and (c shr 0x06).byte))
      result.add (0x80 or (0x3F and c).byte)

    elif c <= 0xFFFF:
      result.add (0xE0 or (0x0F and (c shr 0x0C).byte))
      result.add (0x80 or (0x3F and (c shr 0x06).byte))
      result.add (0x80 or (0x3F and c).byte)

    else:
      result.add 0xED
      result.add (0xA0 or (((c shr 0x10).byte - 1) and 0x0F))
      result.add (0x80 or ((c shr 0x0A).byte and 0x3F))
      result.add 0xED
      result.add (0xB0 or ((c shr 0x06).byte and 0x0F))
      result.add (0x80 or (c and 0x3F).byte)