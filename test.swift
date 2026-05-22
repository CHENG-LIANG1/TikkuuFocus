import Foundation

let str1 = "确认清除数据"
print(str1.unicodeScalars.map { String($0.value, radix: 16) })
