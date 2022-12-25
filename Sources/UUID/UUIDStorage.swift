@inlinable
internal func _uuidCollectionToRawValue<C: Collection>(_ array: C) -> UUID.RawValue
where C.Element == UInt8, C.Index: ExpressibleByIntegerLiteral {
  (
    array[0],
    array[1],
    array[2],
    array[3],
    array[4],
    array[5],
    array[6],
    array[7],
    array[8],
    array[9],
    array[10],
    array[11],
    array[12],
    array[13],
    array[14],
    array[15]
  )
}

@inlinable
internal func _emptyUUIDRawValue() -> UUID.RawValue {
  (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

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

@usableFromInline
internal final class UUIDStorage: Sendable {
  @usableFromInline
  let rawValue: RawUUID

  @inlinable
  init(rawValue: RawUUID) {
    self.rawValue = rawValue
  }

  @inlinable
  init(byteArray: [UInt8]) {
    switch byteArray.count {
    case ..<16:
      var newValue = byteArray
      while newValue.count < 16 {
        newValue.append(0)
      }
      self.rawValue = _uuidCollectionToRawValue(newValue)
    case 16:
      self.rawValue = _uuidCollectionToRawValue(byteArray)
    default:
      self.rawValue = _uuidCollectionToRawValue(byteArray)
    }
  }

  @inlinable
  static func empty() -> UUIDStorage {
    UUIDStorage(rawValue: _emptyUUIDRawValue())
  }
}

// MARK: - Equatable / Hashable

extension UUIDStorage: Equatable {
  @inlinable
  public static func == (lhs: UUIDStorage, rhs: UUIDStorage) -> Bool {
    lhs.elementsEqual(rhs)
  }
}

extension UUIDStorage: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    for byte in self {
      hasher.combine(byte)
    }
  }
}

// MARK: - Random

extension UUIDStorage {
  @inlinable
  static func random<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UUIDStorage {
    let range = UInt64.min ... .max
    let first = UInt64.random(in: range, using: &rng)
    let second = UInt64.random(in: range, using: &rng)
    var rawValue: RawUUID = (
      UInt8(truncatingIfNeeded: first),
      UInt8(truncatingIfNeeded: first &>> 8),
      UInt8(truncatingIfNeeded: first &>> 16),
      UInt8(truncatingIfNeeded: first &>> 24),
      UInt8(truncatingIfNeeded: first &>> 32),
      UInt8(truncatingIfNeeded: first &>> 40),
      UInt8(truncatingIfNeeded: first &>> 48),
      UInt8(truncatingIfNeeded: first &>> 56),
      UInt8(truncatingIfNeeded: second),
      UInt8(truncatingIfNeeded: second &>> 8),
      UInt8(truncatingIfNeeded: second &>> 16),
      UInt8(truncatingIfNeeded: second &>> 24),
      UInt8(truncatingIfNeeded: second &>> 32),
      UInt8(truncatingIfNeeded: second &>> 40),
      UInt8(truncatingIfNeeded: second &>> 48),
      UInt8(truncatingIfNeeded: second &>> 56)
    )
    // ensure uuid v4 marker bytes
    rawValue.6 = (rawValue.6 & 0x0F) | 0x40
    rawValue.8 = (rawValue.8 & 0x3F) | 0x80
    return UUIDStorage(rawValue: rawValue)
  }
}

// MARK: - Collection

extension UUIDStorage: Collection {
  @usableFromInline
  typealias Element = UInt8

  @usableFromInline
  typealias Index = UInt8

  @inlinable
  var startIndex: Index { 0 }

  @inlinable
  var endIndex: Index { 16 }

  @inlinable
  subscript(position: Index) -> UInt8 {
    get {
      precondition((0...15).contains(position))
      switch position {
      case 0: return rawValue.0
      case 1: return rawValue.1
      case 2: return rawValue.2
      case 3: return rawValue.3
      case 4: return rawValue.4
      case 5: return rawValue.5
      case 6: return rawValue.6
      case 7: return rawValue.7
      case 8: return rawValue.8
      case 9: return rawValue.9
      case 10: return rawValue.10
      case 11: return rawValue.11
      case 12: return rawValue.12
      case 13: return rawValue.13
      case 14: return rawValue.14
      case 15: return rawValue.15
      default:
        fatalError()
      }
    }
  }

  @inlinable
  func index(after i: Index) -> Index { i + 1 }
}

// MARK: - String

// "-" == 45
// 0—F: 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70

extension UUIDStorage {
  @inlinable
  var uuidString: String {
    let first = self[0..<4]
    let second = self[4..<6]
    let third = self[6..<8]
    let fourth = self[8..<10]
    let fifth = self[10..<16]

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

  @inlinable
  convenience init?(uuidString: String) {
    var first: UInt8?
    var second: UInt8?

    var bytes = [UInt8]()
    bytes.reserveCapacity(16)

    func assignNormalized(_ nibble: UInt8) {
      if first == nil {
        first = nibble
      } else {
        second = nibble
      }
    }

    for (i, codeUnit) in uuidString.utf8.enumerated() {
      switch codeUnit {
      case 45:
        guard
          i == 8 || i == 13 || i == 18 || i == 23
        else { return nil }
        continue
      case 48...57: // 0...9
        assignNormalized(codeUnit - 48)
      case 65...70: // A...F
        assignNormalized(codeUnit - 55)
      case 97...102: // a...f
        assignNormalized(codeUnit - 87)
      default:
        return nil
      }

      if let a = first, let b = second {
        let byte = (a << 4) | b
        bytes.append(byte)
        first = nil
        second = nil
      }
    }

    self.init(byteArray: bytes)
  }
}

