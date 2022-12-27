@inlinable
func _parseUUIDString(_ uuidString: String) -> RawUUID? {
  guard uuidString.utf8.count == 36 else { return nil }

  var rawUUID = _emptyUUIDRawValue()

  let didParse: Bool = withUnsafeMutablePointer(to: &rawUUID) { (rawUUIDPointer) -> Bool in
    rawUUIDPointer.withMemoryRebound(
      to: UInt8.self,
      capacity: MemoryLayout<RawUUID>.size
    ) { (rawUUIDHead) -> Bool in
      var currentPointer = rawUUIDHead
      var uuidUTF8 = uuidString.enumeratedSubstringUTF8

      while let (i, first) = uuidUTF8.popFirst() {
        switch i {
        case 8, 13, 18, 23: // "-"
          if first == 45 { continue }
        default:
          break
        }

        guard
          let firstNorm = first._normalizedHexNibbleFromUTF8CodeUnit(),
          let (_, second) = uuidUTF8.popFirst(),
          let secondNorm = second._normalizedHexNibbleFromUTF8CodeUnit()
        else { return false }

        let byte = (firstNorm << 4) | secondNorm
        currentPointer.pointee = byte
        currentPointer = currentPointer.advanced(by: 1)
      }
      return true
    }
  }
  guard didParse else { return nil }
  return rawUUID
}

@inlinable
func _uuidString(from storage: UUIDStorage) -> String {
  let first = storage[0..<4]
  let second = storage[4..<6]
  let third = storage[6..<8]
  let fourth = storage[8..<10]
  let fifth = storage[10..<16]

  var output = [UTF8.CodeUnit]()
  output.reserveCapacity(36)

  func appendByte(_ byte: UInt8) {
    output._appendHex(from: byte)
  }

  func appendDash() {
    output.append(45) // "-"
  }

  for byte in first {
    appendByte(byte)
  }
  appendDash()
  for byte in second {
    appendByte(byte)
  }
  appendDash()
  for byte in third {
    appendByte(byte)
  }
  appendDash()
  for byte in fourth {
    appendByte(byte)
  }
  appendDash()
  for byte in fifth {
    appendByte(byte)
  }

  return String(decoding: output, as: UTF8.self)
}

// MARK: - Extensions

extension UInt8 {
  @inlinable
  internal func _utf8CodeUnitFromNormalizedNibble() -> UInt8 {
    precondition(self < 16)
    switch self {
    case 0...9: return self + 48
    case 10...15: return self + 55
    default: fatalError()
    }
  }

  @inlinable
  func _normalizedHexNibbleFromUTF8CodeUnit() -> UInt8? {
    switch self {
    case 48...57: // 0...9
      return self - 48
    case 65...70: // A...F
      return self - 55
    case 97...102: // a...f
      return self - 87
    default:
      return nil
    }
  }
}

extension Array where Element == UTF8.CodeUnit {
  @inlinable
  mutating func _appendHex(from byte: UInt8) {
    let first = (0b11110000 & byte) &>> 4
    let second = 0b00001111 & byte

    self.append(first._utf8CodeUnitFromNormalizedNibble())
    self.append(second._utf8CodeUnitFromNormalizedNibble())
  }
}

extension String {
  @inlinable
  internal var enumeratedSubstringUTF8: EnumeratedUTF8View {
    EnumeratedUTF8View(utf8: self[...].utf8)
  }

  @usableFromInline
  internal struct EnumeratedUTF8View {
    @usableFromInline
    var utf8: Substring.UTF8View

    @usableFromInline
    var offset: Int

    @inlinable
    init(utf8: Substring.UTF8View) {
      self.utf8 = utf8
      self.offset = 0
    }

    @inlinable
    mutating func popFirst() -> (offset: Int, codeUnit: UInt8)? {
      guard let codeUnit = utf8.popFirst() else { return nil }
      defer { offset += 1 }
      return (offset, codeUnit)
    }
  }
}
