// import Foundation: Thư viện nền tảng của Swift, cung cấp các kiểu dữ liệu cơ bản (String, Date, v.v.) và chức năng nền cần thiết cho hầu hết ứng dụng Swift.
import Foundation
// import Combine: Framework dùng cho quản lý dòng dữ liệu bất đồng bộ và reactive programming (kiểu event-driven, thường dùng với SwiftUI, @Published, ObservableObject, ...)
import Combine

/// App-wide session (auth + onboarding). Token stored in Keychain.
/// AppSession: Quản lý trạng thái phiên của ứng dụng (đăng nhập, onboarding, token user, ...).
@MainActor // Chạy tất cả các lệnh trong class này trên Main thread (bắt buộc cho cập nhật UI trong SwiftUI).
final class AppSession: ObservableObject { // "final": không class nào được kế thừa AppSession; "ObservableObject": cho phép view SwiftUI biết khi nào có thay đổi dữ liệu (qua @Published).
    enum Route { // Enum Route: Định nghĩa các màn hình hoặc trạng thái lớn app có thể chuyển tới.
        case splash         // Màn hình splash/loading ban đầu khi mở app
        case onboarding     // Màn hình hướng dẫn/onboarding cho người dùng mới
        case login          // Màn hình đăng nhập
        case main           // Màn hình chính ứng dụng (sau khi login xong)
    }

    // @Published: Khi biến này đổi giá trị, mọi View SwiftUI đang observe sẽ tự động update lại giao diện.
    // private(set): Biến chỉ cho phép chỉnh sửa bên trong class này, bên ngoài chỉ được đọc.
    @Published private(set) var route: Route = .splash // Điều hướng trạng thái màn hình của app (default là splash)
    @Published private(set) var userDisplayName: String // Lưu tên hiển thị của user (lấy từ storage lúc khởi tạo)
    @Published private(set) var sessionToken: String? // Token xác thực phiên đăng nhập, có thể nil nếu chưa login

    private let storage: AppStorageService // storage: Một service dùng để lưu/lấy thông tin từ local storage, ví dụ UserDefaults/Keychain...

    // Hàm khởi tạo. Nhận storage, mặc định là singleton AppStorageService.shared.
    // Khi init sẽ lấy ngay tên user và session token từ storage.
    init(storage: AppStorageService = .shared) {
        self.storage = storage
        self.userDisplayName = storage.userDisplayName
        self.sessionToken = storage.sessionToken
    }

    // Hàm bootstrap: logic khởi động giao diện lần đầu khi vào app.
    // async: chạy bất đồng bộ; cho delay mô phỏng splash screen.
    func bootstrap() async {
        try? await Task.sleep(nanoseconds: 1_200_000_000) // Ngủ 1.2 giây (tạo hiệu ứng splash screen/loading) - Task.sleep cần await do bất đồng bộ.
        if !storage.hasCompletedOnboarding { // Nếu user chưa hoàn thành onboarding
            route = .onboarding // Điều hướng sang màn hình onboarding
        } else if storage.isLoggedIn { // Nếu user đã đăng nhập (có token/session lưu trong storage)
            sessionToken = storage.sessionToken // Lấy lại token từ storage
            userDisplayName = storage.userDisplayName // Lấy lại tên user
            route = .main // Điều hướng vào màn hình chính
        } else { // Ngược lại, chưa login, đã onboarding
            route = .login // Điều hướng sang login
        }
    }

    // Hàm gọi khi onboarding hoàn thành
    func completeOnboarding() {
        storage.hasCompletedOnboarding = true // Đánh dấu vào storage đã hoàn thành onboarding
        route = .login // Chuyển sang màn hình đăng nhập
    }

    // Hàm gọi khi đăng nhập thành công
    func loginSucceeded(displayName: String) {
        userDisplayName = displayName // Cập nhật tên user
        storage.userDisplayName = displayName // Lưu tên user vào local storage
        sessionToken = storage.createSession() // Tạo mới session token (giả lập đăng nhập), lưu vào storage
        route = .main // Chuyển vào màn hình chính
    }

    // Hàm gọi khi user logout
    func logout() {
        storage.clearSession() // Xóa session (token + data liên quan) khỏi storage
        sessionToken = nil // Xóa token ở RAM
        route = .login // Điều hướng về login
    }
}
