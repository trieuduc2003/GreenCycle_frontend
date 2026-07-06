# Layer Architecture trong dự án GreenCycle

Tài liệu này giải thích rõ vai trò của từng tầng trong cấu trúc layer architecture của dự án Flutter.

## 1. Presentation Layer

Tầng này chịu trách nhiệm hiển thị giao diện và xử lý tương tác người dùng.

### Vai trò
- Hiển thị màn hình, widget và giao diện người dùng
- Nhận input từ người dùng
- Gọi các use case hoặc repository ở tầng trên
- Không nên chứa logic nghiệp vụ phức tạp

### Ví dụ
- Trang chủ
- Widget giao diện
- Controller, Bloc, Provider

## 2. Domain Layer

Tầng này chứa logic nghiệp vụ của ứng dụng.

### Vai trò
- Định nghĩa các quy tắc nghiệp vụ
- Chứa entities và use cases
- Định nghĩa interface repository
- Không phụ thuộc vào Flutter UI
- Không phụ thuộc vào API hay database trực tiếp

### Ví dụ
- Entity: User, Product, AppInfo
- Use case: LoginUseCase, GetAppInfoUseCase
- Repository interface: AuthRepository

## 3. Service Layer

Tầng này dùng để tách phần giao tiếp với bên ngoài khỏi tầng data hoặc domain.

### Vai trò
- Gọi API, Firebase, GraphQL, Socket
- Xử lý request/response ở mức thấp
- Không chứa logic nghiệp vụ chính
- Chỉ tập trung vào việc cung cấp dữ liệu từ hệ thống bên ngoài

### Ví dụ
- ApiService
- AuthService
- UserService
- NotificationService

## 4. Data Layer

Tầng này chịu trách nhiệm lấy và lưu dữ liệu từ các nguồn bên ngoài.

### Vai trò
- Kết nối giữa domain và service
- Implement repository interface từ tầng domain
- Chuyển đổi dữ liệu từ service sang domain entity
- Quản lý dữ liệu cho ứng dụng

### Ví dụ
- Repository implementation
- Data model
- Local storage

## 4. Core Layer

Tầng này chứa các thành phần dùng chung cho toàn bộ dự án.

### Vai trò
- Theme, màu sắc, font chữ
- Constants
- Utility helper
- Config chung

### Ví dụ
- AppTheme
- AppConstants
- DateUtils, StringUtils

## Mối quan hệ giữa các tầng

Dòng chảy dữ liệu nên như sau:

1. Presentation gọi use case hoặc repository
2. Domain xử lý logic nghiệp vụ
3. Data lấy hoặc lưu dữ liệu
4. Kết quả trả về cho Presentation

## Quy tắc đơn giản

- Presentation: làm việc với giao diện
- Domain: làm việc với logic nghiệp vụ
- Data: làm việc với dữ liệu
- Core: làm việc với tiện ích chung

## Ví dụ thực tế trong dự án

- Presentation: HomePage
- Domain: AppInfo entity và AppRepository interface
- Data: AppRepositoryImpl
- Core: AppTheme

## Lời khuyên khi phát triển

- Không nên viết logic nghiệp vụ trực tiếp trong widget
- Không nên gọi API trực tiếp từ màn hình
- Nên tách rõ trách nhiệm giữa các tầng để dễ bảo trì và mở rộng
