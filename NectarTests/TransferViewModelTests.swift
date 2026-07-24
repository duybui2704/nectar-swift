import XCTest
@testable import Nectar

@MainActor
final class TransferViewModelTests: XCTestCase {
    func testValidateFormRejectsAmountBelowMinimum() async {
        let vm = TransferViewModel()
        await vm.load()
        vm.fromAccountId = vm.accounts.first?.id ?? ""
        vm.beneficiaryId = vm.beneficiaries.first?.id ?? ""
        vm.amountText = "5000"

        let error = vm.validateForm()
        XCTAssertNotNil(error)
        XCTAssertTrue(error?.contains("tối thiểu") == true)
    }

    func testValidateFormRejectsInsufficientBalance() async {
        let vm = TransferViewModel()
        await vm.load()
        vm.fromAccountId = vm.accounts.first?.id ?? ""
        vm.beneficiaryId = vm.beneficiaries.first?.id ?? ""
        vm.amountText = "999999999"

        let error = vm.validateForm()
        XCTAssertEqual(error, "Số dư không đủ.")
    }

    func testValidateFormAcceptsValidTransfer() async {
        let vm = TransferViewModel()
        await vm.load()
        vm.fromAccountId = vm.accounts.first?.id ?? ""
        vm.beneficiaryId = vm.beneficiaries.first?.id ?? ""
        vm.amountText = "50000"

        XCTAssertNil(vm.validateForm())
    }

    func testValidateFormRejectsEmptySavedBeneficiary() async {
        let vm = TransferViewModel()
        await vm.load()
        vm.fromAccountId = vm.accounts.first?.id ?? ""
        vm.beneficiaryId = ""

        XCTAssertEqual(vm.validateForm(), "Chọn người nhận.")
    }

    func testValidateFormRejectsInvalidNewRecipient() async {
        let vm = TransferViewModel()
        await vm.load()
        vm.fromAccountId = vm.accounts.first?.id ?? ""
        vm.recipientMode = .new
        vm.newName = ""
        vm.amountText = "50000"

        XCTAssertEqual(vm.validateForm(), "Nhập tên người nhận.")
    }
}
