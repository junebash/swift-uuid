extension UUID {
  public enum EncodingStrategy {
    case uuidString(lowercased: Bool)
    case custom((UUID, any Encoder) throws -> Void)

    static var uuidString: Self { .uuidString(lowercased: false) }
  }

  public enum DecodingStrategy {
    case uuidString
    case custom((any Decoder) throws -> UUID)
  }
}

extension CodingUserInfoKey {
  public static var uuidEncodingStrategy: CodingUserInfoKey {
    CodingUserInfoKey(rawValue: "uuidEncodingStrategy")!
  }
  public static var uuidDecodingStrategy: CodingUserInfoKey {
    CodingUserInfoKey(rawValue: "uuidDecodingStrategy")!
  }
}

extension Encoder {
  public var uuidEncodingStrategy: UUID.EncodingStrategy {
    userInfo[.uuidEncodingStrategy] as? UUID.EncodingStrategy ?? .uuidString(lowercased: false)
  }
}

extension Decoder {
  public var uuidDecodingStrategy: UUID.DecodingStrategy {
    userInfo[.uuidDecodingStrategy] as? UUID.DecodingStrategy ?? .uuidString
  }
}

#if canImport(Foundation)
import Foundation

extension JSONEncoder {
  public var uuidEncodingStrategy: UUID.EncodingStrategy {
    get {
      userInfo[.uuidEncodingStrategy] as? UUID.EncodingStrategy ?? .uuidString(lowercased: false)
    }
    set {
      userInfo[.uuidEncodingStrategy] = newValue
    }
  }
}

extension JSONDecoder {
  public var uuidDecodingStrategy: UUID.DecodingStrategy {
    get {
      userInfo[.uuidDecodingStrategy] as? UUID.DecodingStrategy ?? .uuidString
    }
    set {
      userInfo[.uuidDecodingStrategy] = newValue
    }
  }
}

#endif
