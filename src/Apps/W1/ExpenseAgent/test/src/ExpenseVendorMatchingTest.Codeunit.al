// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

codeunit 148337 "Expense Vendor Matching Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AlreadyApprovedErr: Label 'Expense Vendor %1 is already approved.', Comment = '%1 = Expense Vendor No.';
        RejectReasonRequiredErr: Label 'A rejection reason is required.';
        ExpenseVendorNoShouldBeEmptyErr: Label 'Expense Vendor No. should be empty, but was %1.', Comment = '%1 = Expense Vendor No.';
        ExpenseVendorNoShouldNotBeEmptyErr: Label 'Expense Vendor No. should not be empty.';
        StatusShouldBeErr: Label 'Expense Vendor Status should be %1, but was %2.', Comment = '%1 = Expected, %2 = Actual';
        VendorNoShouldBeErr: Label 'Expense Vendor.Vendor No. should be %1, but was %2.', Comment = '%1 = Expected, %2 = Actual';

    // =========================================================================
    // FindOrCreateExpenseVendor
    // =========================================================================

    [Test]
    procedure FindOrCreateExpenseVendor_NoMerchantName_DoesNotCreateExpenseVendor()
    var
        Expense: Record Expense;
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
    begin
        // [SCENARIO] An expense with no merchant name does not trigger Expense Vendor creation.
        Initialize();

        // [GIVEN] An expense with no merchant name.
        CreateMinimalExpense(Expense);

        // [WHEN] Vendor matching is attempted.
        ExpenseVendorMatching.FindOrCreateExpenseVendor(Expense);

        // [THEN] No Expense Vendor was created and the expense remains unlinked.
        Assert.AreEqual('', Expense."Expense Vendor No.", StrSubstNo(ExpenseVendorNoShouldBeEmptyErr, Expense."Expense Vendor No."));
    end;

    [Test]
    procedure FindOrCreateExpenseVendor_AlreadyLinked_DoesNotReLinkToNewExpenseVendor()
    var
        Expense: Record Expense;
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
        OriginalExpenseVendorNo: Code[20];
    begin
        // [SCENARIO] Calling FindOrCreateExpenseVendor on an already-linked expense does nothing.
        Initialize();

        // [GIVEN] An expense already linked to an Expense Vendor.
        CreateMinimalExpense(Expense);
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Unmatched);
        OriginalExpenseVendorNo := ExpenseVendor."No.";
        Expense."Merchant Name" := 'Some Merchant';
        Expense."Expense Vendor No." := ExpenseVendor."No.";
        Expense.Modify(false);

        // [WHEN] Vendor matching is called again.
        ExpenseVendorMatching.FindOrCreateExpenseVendor(Expense);

        // [THEN] The existing link is preserved; no new Expense Vendor was created.
        Assert.AreEqual(OriginalExpenseVendorNo, Expense."Expense Vendor No.", 'Expense Vendor No. should remain unchanged.');
    end;

    [Test]
    procedure FindOrCreateExpenseVendor_NoMatchFound_CreatesUnmatchedExpenseVendor()
    var
        Expense: Record Expense;
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
        MerchantName: Text[100];
    begin
        // [SCENARIO] When no matching BC Vendor exists the system creates an Expense Vendor with status Unmatched.
        Initialize();

        // [GIVEN] An expense whose merchant data does not match any existing vendor.
        MerchantName := CopyStr(LibraryUtility.GenerateRandomText(20), 1, MaxStrLen(MerchantName));
        CreateMinimalExpense(Expense);
        Expense."Merchant Name" := MerchantName;
        Expense."Merchant VAT Registration No." := CopyStr(LibraryUtility.GenerateRandomText(15), 1, 20);
        Expense.Modify(false);

        // [WHEN] Vendor matching is called.
        ExpenseVendorMatching.FindOrCreateExpenseVendor(Expense);

        // [THEN] An Expense Vendor with status Unmatched is created and linked to the expense.
        Assert.AreNotEqual('', Expense."Expense Vendor No.", ExpenseVendorNoShouldNotBeEmptyErr);
        ExpenseVendor.Get(Expense."Expense Vendor No.");
        Assert.AreEqual(
            ExpenseVendor.Status::Unmatched,
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::Unmatched, ExpenseVendor.Status));
        Assert.AreEqual(MerchantName, ExpenseVendor.Name, 'Expense Vendor Name should match the Merchant Name.');
    end;

    [Test]
    procedure FindOrCreateExpenseVendor_VATMatchesBCVendor_CreatesMatchedExpenseVendor()
    var
        CompanyInformation: Record "Company Information";
        Expense: Record Expense;
        Vendor: Record Vendor;
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
        VATRegistrationNo: Text[20];
    begin
        // [SCENARIO] When an expense's merchant VAT No. matches an existing BC Vendor, an Expense Vendor
        //            with status Matched is created, referencing the existing vendor.
        Initialize();

        // [GIVEN] A BC Vendor with a known VAT Registration No.
        CompanyInformation.Get();
        VATRegistrationNo := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Registration No.", VATRegistrationNo);
        Vendor.Modify(true);

        // [GIVEN] An expense whose merchant VAT No. matches that vendor.
        CreateMinimalExpense(Expense);
        Expense."Merchant Name" := CopyStr(LibraryUtility.GenerateRandomText(20), 1, MaxStrLen(Expense."Merchant Name"));
        Expense."Merchant VAT Registration No." := VATRegistrationNo;
        Expense.Modify(false);

        // [WHEN] Vendor matching is called.
        ExpenseVendorMatching.FindOrCreateExpenseVendor(Expense);

        // [THEN] An Expense Vendor with status Matched is created, linked to the BC Vendor.
        Assert.AreNotEqual('', Expense."Expense Vendor No.", ExpenseVendorNoShouldNotBeEmptyErr);
        ExpenseVendor.Get(Expense."Expense Vendor No.");
        Assert.AreEqual(
            ExpenseVendor.Status::Matched,
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::Matched, ExpenseVendor.Status));
        Assert.AreEqual(Vendor."No.", ExpenseVendor."Vendor No.", StrSubstNo(VendorNoShouldBeErr, Vendor."No.", ExpenseVendor."Vendor No."));
    end;

    [Test]
    procedure FindOrCreateExpenseVendor_NameMatchesBCVendor_CreatesMatchedExpenseVendor()
    var
        Expense: Record Expense;
        Vendor: Record Vendor;
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
        VendorName: Text[100];
    begin
        // [SCENARIO] When an expense's merchant name matches an existing BC Vendor name, an Expense Vendor
        //            with status Matched is created.
        Initialize();

        // [GIVEN] A BC Vendor with a specific name.
        VendorName := 'MatchByNameTestVendor' + LibraryUtility.GenerateRandomText(5);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := VendorName;
        Vendor.Modify();

        // [GIVEN] An expense whose merchant name matches that vendor.
        CreateMinimalExpense(Expense);
        Expense."Merchant Name" := CopyStr(VendorName, 1, MaxStrLen(Expense."Merchant Name"));
        Expense.Modify(false);

        // [WHEN] Vendor matching is called.
        ExpenseVendorMatching.FindOrCreateExpenseVendor(Expense);

        // [THEN] An Expense Vendor with status Matched is created, linked to the BC Vendor.
        Assert.AreNotEqual('', Expense."Expense Vendor No.", ExpenseVendorNoShouldNotBeEmptyErr);
        ExpenseVendor.Get(Expense."Expense Vendor No.");
        Assert.AreEqual(
            ExpenseVendor.Status::Matched,
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::Matched, ExpenseVendor.Status));
        Assert.AreEqual(Vendor."No.", ExpenseVendor."Vendor No.", StrSubstNo(VendorNoShouldBeErr, Vendor."No.", ExpenseVendor."Vendor No."));
    end;

    [Test]
    procedure FindOrCreateExpenseVendor_ExistingExpenseVendorByVAT_ReuseExpenseVendor()
    var
        CompanyInformation: Record "Company Information";
        Expense: Record Expense;
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
        VATRegNo: Text[20];
        ExistingExpenseVendorNo: Code[20];
    begin
        // [SCENARIO] When an Expense Vendor already exists with the same VAT No., it is reused instead
        //            of creating a duplicate.
        Initialize();

        // [GIVEN] An existing Expense Vendor with a known VAT Registration No.
        ExpenseVendor.DeleteAll(); // Remove any pre-existing vendors to ensure a clean test.
        CompanyInformation.Get();
        VATRegNo := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Unmatched);
        ExpenseVendor."VAT Registration No." := VATRegNo;
        ExpenseVendor.Modify(false);
        ExistingExpenseVendorNo := ExpenseVendor."No.";

        // [GIVEN] An expense whose merchant VAT No. matches the existing Expense Vendor.
        CreateMinimalExpense(Expense);
        Expense."Merchant Name" := 'Test Merchant';
        Expense."Merchant VAT Registration No." := VATRegNo;
        Expense.Modify(false);

        // [WHEN] Vendor matching is called.
        ExpenseVendorMatching.FindOrCreateExpenseVendor(Expense);

        // [THEN] The existing Expense Vendor is reused; no duplicate is created.
        Assert.AreEqual(ExistingExpenseVendorNo, Expense."Expense Vendor No.", 'Should reuse the existing Expense Vendor.');
    end;

    // =========================================================================
    // Approve
    // =========================================================================

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure Approve_UnmatchedVendor_CreatesBCVendorAndSetsApproved()
    var
        ExpenseVendor: Record "Expense Vendor";
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
        VendorName: Text[100];
    begin
        // [SCENARIO] Approving an Unmatched Expense Vendor creates a new BC Vendor and sets status to Approved.
        Initialize();

        // [GIVEN] An Expense Vendor in Unmatched status with a name and VAT Registration No.
        VendorName := 'Approval Test Vendor';
        CompanyInformation.Get();
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Unmatched);
        ExpenseVendor.Name := VendorName;
        ExpenseVendor."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        ExpenseVendor.Modify(false);

        // [WHEN] The accountant approves the Expense Vendor.
        ExpenseVendorMatching.Approve(ExpenseVendor);

        // [THEN] A new BC Vendor is created.
        ExpenseVendor.Get(ExpenseVendor."No.");
        Assert.AreNotEqual('', ExpenseVendor."Vendor No.", 'A BC Vendor No. should be assigned after approval.');
        Assert.IsTrue(Vendor.Get(ExpenseVendor."Vendor No."), 'BC Vendor record should exist.');

        // [THEN] The Expense Vendor status is Approved with approval metadata.
        Assert.AreEqual(
            ExpenseVendor.Status::Approved,
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::Approved, ExpenseVendor.Status));
        Assert.AreNotEqual('', ExpenseVendor."Approved By", 'Approved By should be set.');
        Assert.AreNotEqual(0D, ExpenseVendor."Approval Date", 'Approval Date should be set.');
        Assert.AreEqual('', ExpenseVendor."Rejection Reason", 'Rejection Reason should be cleared on approval.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure Approve_MatchedVendor_SetsApprovedWithExistingBCVendorNo()
    var
        ExpenseVendor: Record "Expense Vendor";
        Vendor: Record Vendor;
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
    begin
        // [SCENARIO] Approving a Matched Expense Vendor confirms the existing BC Vendor link
        //            without creating a new Vendor.
        Initialize();

        // [GIVEN] A BC Vendor exists.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] An Expense Vendor in Matched status, linked to the existing BC Vendor.
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Matched);
        ExpenseVendor.Name := Vendor.Name;
        ExpenseVendor."Vendor No." := Vendor."No.";
        ExpenseVendor.Modify(false);

        // [WHEN] The accountant approves the Expense Vendor.
        ExpenseVendorMatching.Approve(ExpenseVendor);

        // [THEN] The Expense Vendor status is Approved and the original BC Vendor No. is retained.
        ExpenseVendor.Get(ExpenseVendor."No.");
        Assert.AreEqual(
            ExpenseVendor.Status::Approved,
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::Approved, ExpenseVendor.Status));
        Assert.AreEqual(Vendor."No.", ExpenseVendor."Vendor No.", 'BC Vendor No. should be the original matched vendor.');
    end;

    [Test]
    procedure Approve_AlreadyApproved_ThrowsError()
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
    begin
        // [SCENARIO] Attempting to approve an already-approved Expense Vendor raises an error.
        Initialize();

        // [GIVEN] An Expense Vendor already in Approved status.
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Approved);
        ExpenseVendor.Name := 'Approved Vendor';
        ExpenseVendor.Modify(false);

        // [WHEN/THEN] Approving raises an error.
        asserterror ExpenseVendorMatching.Approve(ExpenseVendor);
        Assert.ExpectedError(StrSubstNo(AlreadyApprovedErr, ExpenseVendor."No."));
    end;

    [Test]
    procedure Approve_EmptyName_ThrowsError()
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
    begin
        // [SCENARIO] Attempting to approve an Expense Vendor with no name raises a TestField error.
        Initialize();

        // [GIVEN] An Expense Vendor with no name.
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Unmatched);
        ExpenseVendor.Name := '';
        ExpenseVendor.Modify(false);

        // [WHEN/THEN] Approving raises a TestField error on the Name field.
        asserterror ExpenseVendorMatching.Approve(ExpenseVendor);
        Assert.ExpectedErrorCode('TestField');
    end;

    // =========================================================================
    // Reject
    // =========================================================================

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure Reject_SetsStatusRejectedWithReasonAndClearsApproval()
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
        RejectReason: Text[250];
    begin
        // [SCENARIO] Rejecting an Expense Vendor sets status Rejected, stores the reason,
        //            and clears any prior approval metadata.
        Initialize();

        // [GIVEN] An Expense Vendor in Pending Approval status with prior approval metadata.
        RejectReason := 'Duplicate vendor entry';
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::"Pending Approval");
        ExpenseVendor.Name := 'Reject Test Vendor';
        ExpenseVendor."Approved By" := 'SOMEUSER';
        ExpenseVendor."Approval Date" := WorkDate();
        ExpenseVendor.Modify(false);

        // [WHEN] The accountant rejects the Expense Vendor.
        ExpenseVendorMatching.Reject(ExpenseVendor, RejectReason);

        // [THEN] Status is Rejected and the reason is stored; approval metadata is cleared.
        ExpenseVendor.Get(ExpenseVendor."No.");
        Assert.AreEqual(
            ExpenseVendor.Status::Rejected,
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::Rejected, ExpenseVendor.Status));
        Assert.AreEqual(RejectReason, ExpenseVendor."Rejection Reason", 'Rejection Reason should be stored.');
        Assert.AreEqual('', ExpenseVendor."Approved By", 'Approved By should be cleared on rejection.');
        Assert.AreEqual(0D, ExpenseVendor."Approval Date", 'Approval Date should be cleared on rejection.');
    end;

    [Test]
    procedure Reject_EmptyReason_ThrowsError()
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
    begin
        // [SCENARIO] Rejecting with an empty reason raises an error.
        Initialize();

        // [GIVEN] An Expense Vendor in Pending Approval status.
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::"Pending Approval");
        ExpenseVendor.Name := 'Reject No Reason';
        ExpenseVendor.Modify(false);

        // [WHEN/THEN] Rejecting with an empty reason raises an error.
        asserterror ExpenseVendorMatching.Reject(ExpenseVendor, '');
        Assert.ExpectedError(RejectReasonRequiredErr);
    end;

    // =========================================================================
    // RequestApproval
    // =========================================================================

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RequestApproval_Unmatched_SetsPendingApproval()
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
    begin
        // [SCENARIO] Requesting approval on an Unmatched Expense Vendor changes status to Pending Approval.
        Initialize();

        // [GIVEN] An Expense Vendor in Unmatched status with a name.
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Unmatched);
        ExpenseVendor.Name := 'Pending Approval Vendor';
        ExpenseVendor.Modify(false);

        // [WHEN] Request Approval is called.
        ExpenseVendorMatching.RequestApproval(ExpenseVendor);

        // [THEN] Status is set to Pending Approval.
        ExpenseVendor.Get(ExpenseVendor."No.");
        Assert.AreEqual(
            ExpenseVendor.Status::"Pending Approval",
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::"Pending Approval", ExpenseVendor.Status));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RequestApproval_Rejected_SetsPendingApproval()
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
    begin
        // [SCENARIO] Requesting approval on a Rejected Expense Vendor resets it to Pending Approval.
        Initialize();

        // [GIVEN] An Expense Vendor in Rejected status with a name.
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Rejected);
        ExpenseVendor.Name := 'Resubmit Vendor';
        ExpenseVendor."Rejection Reason" := 'Was wrong, now corrected';
        ExpenseVendor.Modify(false);

        // [WHEN] Request Approval is called.
        ExpenseVendorMatching.RequestApproval(ExpenseVendor);

        // [THEN] Status is set to Pending Approval.
        ExpenseVendor.Get(ExpenseVendor."No.");
        Assert.AreEqual(
            ExpenseVendor.Status::"Pending Approval",
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::"Pending Approval", ExpenseVendor.Status));
    end;

    [Test]
    procedure RequestApproval_Approved_DoesNotChangeStatus()
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
    begin
        // [SCENARIO] Calling RequestApproval on an Approved Expense Vendor is a no-op.
        Initialize();

        // [GIVEN] An Expense Vendor already in Approved status.
        CreateExpenseVendorDirectly(ExpenseVendor, ExpenseVendor.Status::Approved);
        ExpenseVendor.Name := 'Already Approved Vendor';
        ExpenseVendor.Modify(false);

        // [WHEN] Request Approval is called on an already-approved vendor.
        ExpenseVendorMatching.RequestApproval(ExpenseVendor);

        // [THEN] Status is unchanged.
        ExpenseVendor.Get(ExpenseVendor."No.");
        Assert.AreEqual(
            ExpenseVendor.Status::Approved,
            ExpenseVendor.Status,
            StrSubstNo(StatusShouldBeErr, ExpenseVendor.Status::Approved, ExpenseVendor.Status));
    end;

    // =========================================================================
    // Helpers
    // =========================================================================

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Vendor Matching Test");
        LibraryExpense.UpdateEnableAgentInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        if IsInitialized then
            exit;

        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        SetupExpenseVendorNos();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Vendor Matching Test");
    end;

    local procedure SetupExpenseVendorNos()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Expense Vendor Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ExpenseAgentSetup.Modify(true);
    end;

    /// <summary>Creates a minimal Expense record with no merchant data to avoid auto-triggering vendor matching.</summary>
    local procedure CreateMinimalExpense(var Expense: Record Expense)
    begin
        Expense.Init();
        Expense."No." := LibraryUtility.GenerateRandomCode(Expense.FieldNo("No."), Database::Expense);
        Expense.Insert(false);
    end;

    /// <summary>Creates an Expense Vendor record directly via the table OnInsert trigger (uses no. series).</summary>
    local procedure CreateExpenseVendorDirectly(var ExpenseVendor: Record "Expense Vendor"; Status: Enum "Expense Vendor Status")
    begin
        ExpenseVendor.Init();
        ExpenseVendor.Insert(true);
        ExpenseVendor.Status := Status;
        ExpenseVendor.Modify(false);
    end;

    // =========================================================================
    // Handlers
    // =========================================================================

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Consume the "Vendor X has been created" message.
    end;
}
