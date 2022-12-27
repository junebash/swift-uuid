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

extension Array {
  @inlinable
  init(minimumCapacity: Int) {
    self.init()
    self.reserveCapacity(minimumCapacity)
  }
}
