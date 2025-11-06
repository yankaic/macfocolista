//
//  UUIDMap.swift
//  Focolista
//
//  Created by Yan Kaic on 04/11/25.
//

import Foundation

class UUIDMap {
  private var ints: [UUID: Int] = [:]
  private var uuids: [Int: UUID] = [:]
  private var lastInt: Int = 0
  
  func save(uuid: UUID, int:Int) {
    uuids[int] = uuid
    ints[uuid] = int
  }
  
  func find(int: Int) -> UUID {
    if let found = uuids[int] {
      return found
    }
    let newUUID = UUID()
    save(uuid: newUUID, int: int)
    return newUUID
  }
  
  func find (uuid: UUID)-> Int {
    if let found = ints[uuid] {
      return found
    }
    let newInt = nextInt()
    save(uuid: uuid, int: newInt)
    return newInt
  }
  
  func setLastInt(value: Int){
    lastInt = value
  }
  
  private func nextInt() -> Int {
    lastInt += 1
    return lastInt
  }
  
}

