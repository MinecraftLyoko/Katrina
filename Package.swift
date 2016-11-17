import PackageDescription

let package = Package(
  name: "Katrina",
  dependencies: [
    .Package(url: "https://github.com/daltoniam/Starscream", majorVersion: 2)
    ]
)
