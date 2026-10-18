import Flutter
import Security
import UIKit
import XCTest

class RunnerTests: XCTestCase {
  func testKeychainCanPersistSession() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "bugpilot.keychain-test",
      kSecAttrAccount as String: UUID().uuidString,
    ]
    defer { SecItemDelete(query as CFDictionary) }

    let data = Data("test-session".utf8)
    var writeQuery = query
    writeQuery[kSecValueData as String] = data
    XCTAssertEqual(SecItemAdd(writeQuery as CFDictionary, nil), errSecSuccess)

    var readQuery = query
    readQuery[kSecReturnData as String] = true
    var stored: CFTypeRef?
    XCTAssertEqual(SecItemCopyMatching(readQuery as CFDictionary, &stored), errSecSuccess)
    XCTAssertEqual(stored as? Data, data)
  }
}
