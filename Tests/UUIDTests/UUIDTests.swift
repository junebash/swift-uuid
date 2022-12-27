import Foundation
import XCTest
import UUID
import Lock

final class UUIDTests: XCTestCase {
  let totalUniquenessIterations = 1_000_000

  func testUniqueness() {
    var uuids = Set<MyUUID>(minimumCapacity: totalUniquenessIterations)
    for _ in 1...totalUniquenessIterations {
      let uuid = MyUUID()
      XCTAssert(uuids.insert(uuid).inserted)
    }
  }

  func testUniquenessAsync() async {
    let uuids = Lock(initialState: Set<MyUUID>(minimumCapacity: totalUniquenessIterations))
    let taskCount = 20
    let countPerTask = totalUniquenessIterations / taskCount
    let checkInterval = 2000
    await withTaskGroup(of: Void.self) { taskGroup in
      for _ in 1...taskCount {
        taskGroup.addTask {
          for i in 1...countPerTask {
            if i.isMultiple(of: checkInterval) {
              await Task.yield()
            }
            let uuid = MyUUID()
            uuids.withLock {
              XCTAssert($0.insert(uuid).inserted)
            }
          }
        }
      }
    }
    uuids.withLock {
      XCTAssertEqual($0.count, totalUniquenessIterations)
    }
  }

  func testUUIDStringValueIsCorrect() {
    for _ in 1...10_000 {
      let myUUID = MyUUID()
      let myString = myUUID.uuidString
      let foundationUUID = Foundation.UUID(uuid: myUUID.rawValue)
      let foundationString = foundationUUID.uuidString
      XCTAssertEqual(myString, foundationString)
    }
  }

  func testInitUUIDStringIsCorrect() throws {
    let uuidString = "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF"
    let uuid = try XCTUnwrap(MyUUID(uuidString: uuidString))
    XCTAssertEqual(uuid.uuidString, uuidString)
  }

  func testCoding() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for _ in 0...1_000 {
      let uuid = MyUUID()
      let data = try encoder.encode(uuid)
      let string = try XCTUnwrap(String(data: data, encoding: .utf8))
      XCTAssertEqual(string, "\"\(uuid.uuidString)\"")
      let reUUID = try decoder.decode(MyUUID.self, from: data)
      XCTAssertEqual(uuid, reUUID)
    }
  }

  func testLowercasedEncoding() throws {
    let encoder = JSONEncoder()
    encoder.uuidEncodingStrategy = .uuidString(lowercased: true)
    let uuid = try XCTUnwrap(MyUUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF"))
    let data = try encoder.encode(uuid)
    let dataString = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(dataString, "\"deadbeef-dead-beef-dead-beefdeadbeef\"")
  }

  func testLowercasedDecoding() throws {
    let decoder = JSONDecoder()
    let data = Data("\"deadbeef-dead-beef-dead-beefdeadbeef\"".utf8)
    let uuid = try decoder.decode(MyUUID.self, from: data)
    XCTAssertEqual(uuid, MyUUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF"))
  }
}

@available(macOS 13, *)
final class UUIDPerformanceTests: XCTestCase {
  func testRandomPerformance() {
    let numberOfGenerations = 10_000
    let clock = SuspendingClock()

    var foundationUUIDs = [Foundation.UUID]()
    foundationUUIDs.reserveCapacity(numberOfGenerations)
    var myUUIDs = [MyUUID]()
    myUUIDs.reserveCapacity(numberOfGenerations)

    let foundationUUIDTime = clock.measure {
      for _ in 1...numberOfGenerations {
        let uuid = Foundation.UUID()
        foundationUUIDs.append(uuid)
      }
    }
    let myUUIDTime = clock.measure {
      for _ in 1...numberOfGenerations {
        let uuid = MyUUID()
        myUUIDs.append(uuid)
      }
    }

    print("🏁 My UUID Generation Time:", myUUIDTime)
    print("🏁 Foundation UUID Generation Time:", foundationUUIDTime)
  }

  func testStringPerformance() {
    let numberOfGenerations = 10_000
    let clock = SuspendingClock()

    var foundationUUIDs = [String]()
    foundationUUIDs.reserveCapacity(numberOfGenerations)
    var myUUIDs = [String]()
    myUUIDs.reserveCapacity(numberOfGenerations)

    let foundationUUIDTime = clock.measure {
      for _ in 1...numberOfGenerations {
        let uuid = Foundation.UUID()
        foundationUUIDs.append(uuid.uuidString)
      }
    }
    let myUUIDTime = clock.measure {
      for _ in 1...numberOfGenerations {
        let uuid = MyUUID()
        myUUIDs.append(uuid.uuidString)
      }
    }

    print("🏁 My UUID String Time:", myUUIDTime)
    print("🏁 Foundation UUID String Time:", foundationUUIDTime)
  }

  func testInitUUIDStringPerformance() throws {
    let clock = SuspendingClock()
    let iterationCount = 10_000

    let myUUIDTime = try clock.measure {
      for _ in 1...iterationCount {
        let uuid = MyUUID()
        let string = uuid.uuidString
        let reUUID = try XCTUnwrap(MyUUID(uuidString: string))
        XCTAssertEqual(uuid, reUUID)
      }
    }

    let foundationUUIDTime = try clock.measure {
      for _ in 1...iterationCount {
        let uuid = Foundation.UUID()
        let string = uuid.uuidString
        let reUUID = try XCTUnwrap(Foundation.UUID(uuidString: string))
        XCTAssertEqual(uuid, reUUID)
      }
    }
    print("🏁 My String Init:", myUUIDTime)
    print("🏁 Foundation String Init:", foundationUUIDTime)
  }
}
