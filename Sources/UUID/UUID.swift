/// 16 bytes.
public typealias RawUUID = (
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8,
  UInt8
)

public struct UUID: Sendable {
  public typealias RawValue = RawUUID

  @usableFromInline
  internal let storage: UUIDStorage

  @inlinable
  internal init(storage: UUIDStorage) {
    self.storage = storage
  }
}

// MARK: - RawValue

extension UUID: RawRepresentable {
  @inlinable
  public var rawValue: RawUUID { storage.rawValue }

  @inlinable
  public init(rawValue: UUID.RawValue) {
    self.init(storage: UUIDStorage(rawValue: rawValue))
  }

  @inlinable
  public init<Bytes: Sequence<UInt8>>(bytes: Bytes) {
    self.init(storage: UUIDStorage(byteArray: Array(bytes)))
  }

  public static func empty() -> UUID {
    UUID(rawValue: _emptyUUIDRawValue())
  }
}

// MARK: - Conformances

extension UUID: Equatable {
  @inlinable
  public static func == (lhs: UUID, rhs: UUID) -> Bool {
    lhs.storage == rhs.storage
  }
}

extension UUID: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    storage.hash(into: &hasher)
  }
}

// MARK: - Random

extension UUID {
  @inlinable
  public static func random<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UUID {
    UUID(storage: UUIDStorage.random(using: &rng))
  }

  @inlinable
  public static func random() -> UUID {
    var rng = SystemRandomNumberGenerator()
    return UUID.random(using: &rng)
  }

  @inlinable
  public init() {
    self = .random()
  }
}

// MARK: - String

extension UUID {
  @inlinable
  public var uuidString: String {
    storage.uuidString
  }

  @inlinable
  public init?(uuidString: String) {
    guard let storage = UUIDStorage(uuidString: uuidString) else { return nil }
    self.init(storage: storage)
  }
}

// MARK: - Coding

extension UUID: Encodable {
  public func encode(to encoder: Encoder) throws {
    switch encoder.uuidEncodingStrategy {
    case .uuidString(let lowercased):
      var container = encoder.singleValueContainer()
      if lowercased {
        try container.encode(self.uuidString.lowercased())
      } else {
        try container.encode(self.uuidString)
      }
    case .custom(let encode):
      try encode(self, encoder)
    }
  }
}

extension UUID: Decodable {
  public init(from decoder: Decoder) throws {
    switch decoder.uuidDecodingStrategy {
    case .uuidString:
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)
      guard let storage = UUIDStorage(uuidString: string) else {
        throw DecodingError.dataCorrupted(DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Attempted to decode UUID from invalid UUID string."
        ))
      }
      self.init(storage: storage)
    case .custom(let decode):
      self = try decode(decoder)
    }
  }
}
