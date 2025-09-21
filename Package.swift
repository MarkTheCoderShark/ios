// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "AITodoApp",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AITodoApp",
            targets: ["AITodoApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "AITodoApp",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "SocketIO", package: "socket.io-client-swift"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            path: "AITodoApp/Sources"),
        .testTarget(
            name: "AITodoAppTests",
            dependencies: ["AITodoApp"]),
    ]
)