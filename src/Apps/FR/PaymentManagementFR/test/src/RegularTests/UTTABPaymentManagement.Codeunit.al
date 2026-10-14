// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
#if not CLEAN30
using Microsoft.Finance.GeneralLedger.Posting;
#endif
using Microsoft.Finance.GeneralLedger.Setup;
#if not CLEAN30
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
#endif
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
#if not CLEAN28
using System.Environment.Configuration;
#endif
using System.TestLibraries.Upgrade;
using System.TestLibraries.Utilities;
using System.Upgrade;

#if CLEAN28
#pragma warning disable AS0018 // Legacy feature-switch scenarios are excluded once Payment is always enabled.
#endif
codeunit 144040 "UT TAB Payment Management"
#if CLEAN28
#pragma warning restore AS0018
#endif
{
    // // [FEATURE] [Payment Slip] [UT]
    //   1-3. Purpose of the test is to verify error On Validate Account No. for Vendor with Blocked Type Payment and All and Customer with Blocked Type All of Payment Line table.
    //   4-5. Purpose of the test is to validate On Validate Account No. Trigger Customer with Blocked Type Ship and Invoice of Payment Line table.
    //     6. Purpose of the test is to verify error on OnValidate UnrealizedVAT General Ledger Setup table.
    //   7-8. Purpose of the test is to verify error on OnValidate UnrealizedVAT Reversal Type Delayed and Application Payment Class table.
    //     9. Purpose of this test to verify Payment Class is deleted from Payment Class table.
    //    10. Purpose of this test to verify Payment Class, Payment Status, Payment Step and Payment Step Ledger is deleted when payment slip is not created.
    // 11-12. Purpose of the test is to validate OnValidate trigger of Action Type on Payment Step Card to check Realize VAT control.
    // 
    // Covers Test Cases for WI - 344458
    // ----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                         TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------
    // OnValidateAccountNoPmtLineBlockedVendTypePmtError, OnValidateAccountNoPmtLineBlockedVendTypeAllError                       169539
    // OnValidateAccountNoPmtLineBlockedCustTypeAllError, OnValidateAccountNoPmtLineBlockedCustTypeShip                           169540
    // OnValidateAccountNoPmtLineBlockedCustTypeInvoice                                                                           169541
    // 
    // Covers Test Cases for WI - 344508
    // ----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                         TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------
    // OnValidateUnrealizedVATGLSetupError                                                                                        169442
    // OnValidateUnrealizedVATReversalTypeDelayedPmtClass                                                                         169443
    // OnValidateUnrealizedVATReversalTypeApplnPmtClass                                                                           169444
    // 
    // Covers Test Cases for WI - 345066
    // ----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                         TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------
    // OnDeletePaymentClass                                                                                                       169514
    // OnDeletePaymentClassPaymentSlipNotCreated                                                                                  169530
    // 
    // Covers Test Cases for WI - 345175
    // ----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                         TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------
    // OnValidateActionTypeRealizeVATEnablePaymentStepCard                                                                         169525
    // OnValidateActionTypeRealizeVATDisablePaymentStepCard                                                                        169532

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;
#if not CLEAN28
    EventSubscriberInstance = Manual;
#endif

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
#if not CLEAN30
        LibraryPurchase: Codeunit "Library - Purchase";
#endif
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
#if not CLEAN28
        OriginalPaymentFeatureStatus: Record "Feature Data Update Status";
        PaymentFeatureStatusExisted: Boolean;
        PaymentFeatureStatusChanged: Boolean;
        UseActualPaymentFeatureStatus: Boolean;
#endif
        DialogErr: Label 'Dialog';
        PaymentClassErr: Label 'Payment Class should not exist.';
        TestFieldErr: Label 'TestField';
        UnexpectedErr: Label 'Expected and Actual value are not same.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateAccountNoPmtLineBlockedVendTypePmtError()
    var
        PaymentLine: Record "Payment Line FR";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to verify error on OnValidate Account No. for Vendor with Blocked Type Payment of Table ID - 10806 Payment Line.
        // Test to verify error "Blocked must be equal to ' '  in Vendor: No.=10:29:57 AMXX002. Current value is 'Payment'".
        OnValidateAccountNoErrorInPaymentLine(
          PaymentLine."Account Type"::Vendor, CreateBlockedVendor(Vendor.Blocked::Payment), TestFieldErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateAccountNoPmtLineBlockedVendTypeAllError()
    var
        PaymentLine: Record "Payment Line FR";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to verify error on OnValidate Account No. for Vendor with Blocked Type All of Table ID - 10806 Payment Line.
        // Test to verify error "Blocked must be equal to ' '  in Vendor: No.=2:04:38 PMXX004. Current value is 'All'".
        OnValidateAccountNoErrorInPaymentLine(PaymentLine."Account Type"::Vendor, CreateBlockedVendor(Vendor.Blocked::All), TestFieldErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateAccountNoPmtLineBlockedCustTypeAllError()
    var
        Customer: Record Customer;
        PaymentLine: Record "Payment Line FR";
    begin
        // Purpose of the test is to verify error on OnValidate Account No. for Customer with Blocked Type All of Table ID - 10806 Payment Line.
        // Test to verify error "Blocked must not be All in Customer No.='1:29:10 PMXX004'".
        OnValidateAccountNoErrorInPaymentLine(
          PaymentLine."Account Type"::Customer, CreateBlockedCustomer(Customer.Blocked::All), 'NCLCSRTS');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateAccountNoPmtLineBlockedCustTypeShip()
    var
        Customer: Record Customer;
        PaymentLine: Record "Payment Line FR";
    begin
        // Purpose of the test is to check Customer with Blocked Type Ship is validating on Account No. of Table ID - 10806 Payment Line.
        OnValidateAccountNoInPaymentLine(PaymentLine."Account Type"::Customer, CreateBlockedCustomer(Customer.Blocked::Ship));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateAccountNoPmtLineBlockedCustTypeInvoice()
    var
        Customer: Record Customer;
        PaymentLine: Record "Payment Line FR";
    begin
        // Purpose of the test is to check Customer with Blocked Type Invoice is validating on Account No. of Table ID - 10806 Payment Line.
        OnValidateAccountNoInPaymentLine(PaymentLine."Account Type"::Customer, CreateBlockedCustomer(Customer.Blocked::Invoice));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateUnrealizedVATGLSetupError()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentClass: Record "Payment Class FR";
    begin
        // Purpose of the test is to verify error on OnValidate UnrealizedVAT False Table ID - 98 General Ledger Setup.
        // Setup: Update General Ledger Setup and Create Payment Class.

        CreatePaymentClass(PaymentClass);

        // Exercise.
        asserterror GeneralLedgerSetup.Validate("Unrealized VAT", false);

        // Verify: Verify expected error code, Actual error is "Payment Class 4:27:08 PMXX001 has Unrealized VAT Reversal set to Delayed.".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateUnrealizedVATReversalTypeDelayedPmtClass()
    var
        PaymentClass: Record "Payment Class FR";
    begin
        // Purpose of the test is to verify error on OnValidate UnrealizedVAT Reversal Type Delayed Table ID - 10803 Payment Class.
        // Verify error "Unrealized VAT must be equal to 'Yes'  in General Ledger Setup: Primary Key=. Current value is 'No'."
        UnrealizedVATReversalTypePaymentClass(PaymentClass."Unrealized VAT Reversal"::Delayed, TestFieldErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateUnrealizedVATReversalTypeApplnPmtClass()
    var
        PaymentClass: Record "Payment Class FR";
    begin
        // Purpose of the test is to verify error on OnValidate UnrealizedVAT Reversal Type Application Table ID - 10803 Payment Class.
        // Verify error "Payment Class 5:03:16 PMXX001 has at least one Payment Step for which Realize VAT is checked.".
        UnrealizedVATReversalTypePaymentClass(PaymentClass."Unrealized VAT Reversal"::Application, DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnDeletePaymentClass()
    var
        PaymentClass: Record "Payment Class FR";
    begin
        // Purpose of the test is to delete Payment Class.
        // Setup: Create Payment Class.

        CreatePaymentClass(PaymentClass);

        // Exercise.
        PaymentClass.Delete();

        // Verify:  Verify Payment Class is deleted.
        Assert.IsFalse(PaymentClass.Get(PaymentClass.Code), PaymentClassErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnDeletePaymentClassPaymentSlipNotCreated()
    var
        PaymentClass: Record "Payment Class FR";
        PaymentStatus: Record "Payment Status FR";
        PaymentStep: Record "Payment Step FR";
        PaymentStepLedger: Record "Payment Step Ledger FR";
    begin
        // Purpose of the test is to delete Payment Class when Payment Slip is not created.
        // Setup: Create Payment Class, Payment Status, Payment Step and Payment Step Ledger.

        CreatePaymentClass(PaymentClass);
        CreatePaymentStatus(PaymentStatus, PaymentClass.Code);
        CreatePaymentStep(PaymentStep, PaymentClass.Code);
        CreatePaymentStepLedger(PaymentStepLedger, PaymentClass.Code);

        // Excercise.
        PaymentClass.Delete(true);

        // Verify:  Verify Payment Class is deleted in Payment Class, Payment Status, Payment Step and Payment Step Ledger.
        Assert.IsFalse(PaymentClass.Get(PaymentClass.Code), PaymentClassErr);
        Assert.IsTrue(PaymentStatus.IsEmpty(), PaymentClassErr);
        Assert.IsTrue(PaymentStep.IsEmpty(), PaymentClassErr);
        Assert.IsTrue(PaymentStepLedger.IsEmpty(), PaymentClassErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateActionTypeRealizeVATEnablePaymentStepCard()
    var
        PaymentClass: Record "Payment Class FR";
    begin
        // Purpose of the test is to validate OnValidate trigger of Action Type for enable Relize VAT control on Payment Step Card page ID - 10824.
        UnrealizedVATReversalOnPaymentClass(PaymentClass."Unrealized VAT Reversal"::Delayed, true);  // Using True for check control state on page.    
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnValidateActionTypeRealizeVATDisablePaymentStepCard()
    var
        PaymentClass: Record "Payment Class FR";
    begin
        // Purpose of the test is to validate OnValidate trigger of Action Type disable Relize VAT control on Payment Step Card page ID - 10824.
        UnrealizedVATReversalOnPaymentClass(PaymentClass."Unrealized VAT Reversal"::Application, false);  // Using True for check control state on page.    
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure OnValidateShortcutDimension12Code()
    var
        PaymentHeader: Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        DimValue: array[2] of Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 375959] Payment Line Global Dimension changed after change on Payment Slip
        Initialize();


        // [GIVEN] Payment Header with one line
        CreatePaymentSlip(PaymentLine, PaymentLine."Account Type"::Customer);

        // [GIVEN] 2 global Dimension Values, X1 and X2
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimValue[1], GLSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimValue[2], GLSetup."Global Dimension 2 Code");

        // [WHEN] Payment Slip "Department Code" = X1
        PaymentHeader.Get(PaymentLine."No.");
        PaymentHeader.Validate("Shortcut Dimension 1 Code", DimValue[1].Code);
        PaymentHeader.Modify();

        // [THEN] Payment Line "Department Code" = X1
        VerifyPaymentLineDimSetID(PaymentLine, PaymentHeader."Dimension Set ID");

        // [WHEN] Payment Slip "Project Code" = X2
        PaymentHeader.Get(PaymentLine."No.");
        PaymentHeader.Validate("Shortcut Dimension 2 Code", DimValue[2].Code);
        PaymentHeader.Modify();

        // [THEN] Payment Line "Project Code" = X2
        VerifyPaymentLineDimSetID(PaymentLine, PaymentHeader."Dimension Set ID");

        // [WHEN] Payment Slip "Department Code" and "Project Code" cleared
        PaymentHeader.Get(PaymentLine."No.");
        PaymentHeader.Validate("Shortcut Dimension 1 Code", '');
        PaymentHeader.Validate("Shortcut Dimension 2 Code", '');
        PaymentHeader.Modify();

        // [THEN] Payment Line has no Dimensions set
        VerifyPaymentLineDimSetID(PaymentLine, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,DimensionValueListModalPageHandler')]
    procedure OnLookupShortcutDimension12Code()
    var
        PaymentHeader: Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        DimValue: array[2] of Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        PaymentSlip: TestPage "Payment Slip FR";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 375959] Payment Line Global Dimension changed after change on Payment Slip using Lookup
        Initialize();


        // [GIVEN] Payment Header with one line
        CreatePaymentSlip(PaymentLine, PaymentLine."Account Type"::Customer);

        // [GIVEN] 2 Global Dimension Values, X1 and X2
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimValue[1], GLSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimValue[2], GLSetup."Global Dimension 2 Code");

        // [WHEN] Payment Slip "Department Code" = X1 using Lookup
        PaymentHeader.Get(PaymentLine."No.");
        PaymentSlip.OpenEdit();
        PaymentSlip.GotoRecord(PaymentHeader);
        LibraryVariableStorage.Enqueue(DimValue[1]."Dimension Code");
        LibraryVariableStorage.Enqueue(DimValue[1].Code);
        PaymentSlip."Shortcut Dimension 1 Code".Lookup();
        PaymentHeader.FindFirst();

        // [THEN] Payment Line "Department Code" = X1
        VerifyPaymentLineDimSetID(PaymentLine, PaymentHeader."Dimension Set ID");

        // [WHEN] Payment Slip "Project Code" = X2 using Lookup
        LibraryVariableStorage.Enqueue(DimValue[2]."Dimension Code");
        LibraryVariableStorage.Enqueue(DimValue[2].Code);
        PaymentSlip."Shortcut Dimension 2 Code".Lookup();
        PaymentHeader.FindFirst();

        // [THEN] Payment Line "Project Code" = X2
        VerifyPaymentLineDimSetID(PaymentLine, PaymentHeader."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PaymentHeaderLineMergeDimension()
    var
        PaymentHeader: Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        DimensionValue: array[2] of Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 376115] Payment Header Dimension merges with Payment Line Dimension
        Initialize();


        // [GIVEN] Customer with Default Dimension "D1"
        CustomerNo := CreateCustomerWithDefaultDimension(DimensionValue[1]);

        // [GIVEN] Payment Header with Dimension "D2"
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GLSetup."Global Dimension 1 Code");
        CreatePaymentSlip(PaymentLine, PaymentLine."Account Type"::Customer);
        PaymentHeader.Get(PaymentLine."No.");
        PaymentHeader.Validate("Shortcut Dimension 1 Code", DimensionValue[2].Code);
        PaymentHeader.Modify();

        // [WHEN] Customer No. is validated on Payment Line
        PaymentLineSetAccountNo(PaymentLine, CustomerNo);

        // [THEN] Payment Line has Dimension "D1" and "D2"
        VerifyDimensionCountByDimSetID(DimensionSetEntry, PaymentLine."Dimension Set ID", 2);
        DimensionSetEntry.SetFilter(
          "Dimension Code", '%1|%2', DimensionValue[2]."Dimension Code", DimensionValue[1]."Dimension Code");
        Assert.RecordCount(DimensionSetEntry, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PaymentHeaderOverwriteLineDimensionValue()
    var
        PaymentHeader: Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        DimensionValue: array[2] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GLSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 376115] Payment Header Dimension Value overwrites Dimension Value of Payment Line with same Dimension
        Initialize();


        // [GIVEN] Payment Header with Dimension "D1" and Dimension Value "DV1"
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GLSetup."Global Dimension 1 Code");
        CreatePaymentSlip(PaymentLine, PaymentLine."Account Type"::Customer);
        PaymentHeader.Get(PaymentLine."No.");
        PaymentHeader.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        PaymentHeader.Modify();

        // [GIVEN] Customer with Default Dimension "D1" and Dimension Value "DV2"
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[1]."Dimension Code");
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [WHEN] Customer No. is validated on Payment Line
        PaymentLineSetAccountNo(PaymentLine, CustomerNo);

        // [THEN] Payment Line has Dimension D1 with Dimension Value "DV1"
        VerifyDimensionCountByDimSetID(DimensionSetEntry, PaymentLine."Dimension Set ID", 1);
        DimensionSetEntry.SetFilter("Dimension Value Code", DimensionValue[1].Code);
        Assert.RecordIsNotEmpty(DimensionSetEntry);
    end;

    [Test]
    procedure PaymentLineAccountDimension()
    var
        PaymentLine: Record "Payment Line FR";
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 376115] Payment Line Dimension is taken from validated Account
        Initialize();


        // [GIVEN] Customer with Default Dimension "D1"
        CustomerNo := CreateCustomerWithDefaultDimension(DimensionValue);

        // [GIVEN] Payment Header with no Dimensions
        CreatePaymentSlip(PaymentLine, PaymentLine."Account Type"::Customer);

        // [WHEN] Customer No. is validated on Payment Line
        PaymentLineSetAccountNo(PaymentLine, CustomerNo);

        // [THEN] Payment Line has Dimension "D1"
        VerifyDimensionCountByDimSetID(DimensionSetEntry, PaymentLine."Dimension Set ID", 1);
        DimensionSetEntry.SetFilter("Dimension Value Code", DimensionValue.Code);
        Assert.RecordIsNotEmpty(DimensionSetEntry);
    end;

    [Test]
    procedure VendorPaymentLineOnDelete()
    var
        PaymentHeader: array[2] of Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        AppliesToID: Code[20];
    begin
        // [SCENARIO 304798] Deleting Payment Slip leads to only associated Vendor Ledger Entries having empty Applies-to ID
        Initialize();


        AppliesToID := LibraryUtility.GenerateRandomCode(PaymentLine.FieldNo("Applies-to ID"), DATABASE::"Vendor Ledger Entry");

        // [GIVEN] Payment Slip "X1" with Payment Line applied to Vendor Ledger Entry "Y1" with "Applies-To ID" equal "Z"
        MockVendorLedgerEntry(VendorLedgerEntry[1], AppliesToID);
        MockPaymentSlipWithPaymentLine(
          PaymentHeader[1], PaymentLine."Account Type"::Vendor, AppliesToID,
          VendorLedgerEntry[1]."Document No.", VendorLedgerEntry[1]."Document Type");

        // [GIVEN] Payment Slip "X2" with Payment Line applied to Vendor Ledger Entry "Y2" using "Applies-To ID" equal "Z"
        MockVendorLedgerEntry(VendorLedgerEntry[2], AppliesToID);
        MockPaymentSlipWithPaymentLine(
          PaymentHeader[2], PaymentLine."Account Type"::Vendor, AppliesToID,
          VendorLedgerEntry[2]."Document No.", VendorLedgerEntry[2]."Document Type");

        // [WHEN] Deleting Payment Slip "X1".
        PaymentHeader[1].Delete(true);

        // [THEN] Vendor Ledger Entry "Y1" has "Applies-To ID" equal to ""
        VendorLedgerEntry[1].Get(VendorLedgerEntry[1]."Entry No.");
        Assert.AreEqual('', VendorLedgerEntry[1]."Applies-to ID", '');
        // [THEN] Vendor Ledger Entry "Y2" has "Applies-To ID" equal to "Z"
        VendorLedgerEntry[2].Get(VendorLedgerEntry[2]."Entry No.");
        Assert.AreEqual(AppliesToID, VendorLedgerEntry[2]."Applies-to ID", '');
    end;

    [Test]
    procedure CustomerPaymentLineOnDelete()
    var
        PaymentHeader: array[2] of Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        CustLedgerEntry: array[2] of Record "Cust. Ledger Entry";
        AppliesToID: Code[20];
    begin
        // [SCENARIO 304798] Deleting Payment Slip leads to only associated Customer Ledger Entries having empty Applies-to ID
        Initialize();


        AppliesToID := LibraryUtility.GenerateRandomCode(PaymentLine.FieldNo("Applies-to ID"), DATABASE::"Cust. Ledger Entry");

        // [GIVEN] Payment Slip "X1" with Payment Line applied to Customer Ledger Entry "Y1" with "Applies-To ID" equal "Z"
        MockCustomerLedgerEntry(CustLedgerEntry[1], AppliesToID);
        MockPaymentSlipWithPaymentLine(
          PaymentHeader[1], PaymentLine."Account Type"::Customer, AppliesToID,
          CustLedgerEntry[1]."Document No.", CustLedgerEntry[1]."Document Type");

        // [GIVEN] Payment Slip "X2" with Payment Line applied to Customer Ledger Entry "Y2" using "Applies-To ID" equal "Z"
        MockCustomerLedgerEntry(CustLedgerEntry[2], AppliesToID);
        MockPaymentSlipWithPaymentLine(
          PaymentHeader[2], PaymentLine."Account Type"::Customer, AppliesToID,
          CustLedgerEntry[2]."Document No.", CustLedgerEntry[2]."Document Type");

        // [WHEN] Deleting Payment Slip "X1".
        PaymentHeader[1].Delete(true);

        // [THEN] Customer Ledger Entry "Y1" has "Applies-To ID" equal to ""
        CustLedgerEntry[1].Get(CustLedgerEntry[1]."Entry No.");
        Assert.AreEqual('', CustLedgerEntry[1]."Applies-to ID", '');
        // [THEN] Customer Ledger Entry "Y2" has "Applies-To ID" equal to "Z"
        CustLedgerEntry[2].Get(CustLedgerEntry[2]."Entry No.");
        Assert.AreEqual(AppliesToID, CustLedgerEntry[2]."Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler')]
    procedure PaymentApplyKeepsAppliesToDocNoAndDocTypeWhenAccTypeCustomerAndCustLedEntryExists()
    var
        PaymentHeader: Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AppliesToID: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 315612] Codeunit "Payment-Apply" doesn't delete "Applies-to Doc. No." and "Applies-to Doc. Type".
        Initialize();


        // [GIVEN] Payment Line with "Account Type"::Customer and existing Customer Ledger entry.
        AppliesToID := LibraryUtility.GenerateRandomCode(PaymentLine.FieldNo("Applies-to ID"), DATABASE::"Cust. Ledger Entry");
        MockCustomerLedgerEntry(CustLedgerEntry, AppliesToID);
        MockPaymentSlipWithPaymentLine(
          PaymentHeader, PaymentLine."Account Type"::Customer, AppliesToID,
          CustLedgerEntry."Document No.", CustLedgerEntry."Document Type");
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindFirst();

        // [WHEN] Codeunit "Payment-Apply" is run for Payment Line.
        CODEUNIT.Run(CODEUNIT::"Payment-Apply FR", PaymentLine);

        // [THEN] "Applies-to Doc. No." and "Applies-to Doc. Type" are the same as before.
        Assert.AreEqual(CustLedgerEntry."Document No.", PaymentLine."Applies-to Doc. No.", '');
        Assert.AreEqual(CustLedgerEntry."Document Type", PaymentLine."Applies-to Doc. Type", '');
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    procedure PaymentApplyKeepsAppliesToDocNoAndDocTypeWhenAccTypeVendorAndVendLedEntryExists()
    var
        PaymentHeader: Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliesToID: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 315612] Codeunit "Payment-Apply" doesn't delete "Applies-to Doc. No." and "Applies-to Doc. Type".
        Initialize();


        // [GIVEN] Payment Line with "Account Type"::Vendor and existing Vendor Ledger entry.
        AppliesToID := LibraryUtility.GenerateRandomCode(PaymentLine.FieldNo("Applies-to ID"), DATABASE::"Vendor Ledger Entry");
        MockVendorLedgerEntry(VendorLedgerEntry, AppliesToID);
        MockPaymentSlipWithPaymentLine(
          PaymentHeader, PaymentLine."Account Type"::Vendor, AppliesToID,
          VendorLedgerEntry."Document No.", VendorLedgerEntry."Document Type");
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindFirst();

        // [WHEN] Codeunit "Payment-Apply" is run for Payment Line.
        CODEUNIT.Run(CODEUNIT::"Payment-Apply FR", PaymentLine);

        // [THEN] "Applies-to Doc. No." and "Applies-to Doc. Type" are the same as before.
        Assert.AreEqual(VendorLedgerEntry."Document No.", PaymentLine."Applies-to Doc. No.", '');
        Assert.AreEqual(VendorLedgerEntry."Document Type", PaymentLine."Applies-to Doc. Type", '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler')]
    procedure PaymentApplyKeepsAppliesToDocNoAndDocTypeWhenAccTypeCustomerAndCustLedEntryDoesntExist()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentHeader: Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        AppliesToID: Code[20];
        DocNo: Code[20];
        DocType: Enum "Gen. Journal Document Type";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 315612] Codeunit "Payment-Apply" doesn't delete "Applies-to Doc. No." and "Applies-to Doc. Type".
        Initialize();


        // [GIVEN] Payment Line with "Account Type"::Customer and no existing Customer Ledger entry.
        AppliesToID := LibraryUtility.GenerateRandomCode(PaymentLine.FieldNo("Applies-to ID"), DATABASE::"Cust. Ledger Entry");
        DocNo := LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry");
        DocType := "Gen. Journal Document Type".FromInteger(LibraryRandom.RandInt(7));
        MockPaymentSlipWithPaymentLine(PaymentHeader, PaymentLine."Account Type"::Customer, AppliesToID, DocNo, DocType);
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindFirst();

        // [WHEN] Codeunit "Payment-Apply" is run for Payment Line.
        CODEUNIT.Run(CODEUNIT::"Payment-Apply FR", PaymentLine);

        // [THEN] "Applies-to Doc. No." and "Applies-to Doc. Type" are the same as before.
        Assert.AreEqual(DocNo, PaymentLine."Applies-to Doc. No.", '');
        Assert.AreEqual(DocType, PaymentLine."Applies-to Doc. Type", '');
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    procedure PaymentApplyKeepsAppliesToDocNoAndDocTypeWhenAccTypeVendorAndVendLedEntryDoesntExist()
    var
        PaymentHeader: Record "Payment Header FR";
        PaymentLine: Record "Payment Line FR";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliesToID: Code[20];
        DocNo: Code[20];
        DocType: Enum "Gen. Journal Document Type";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 315612] Codeunit "Payment-Apply" doesn't delete "Applies-to Doc. No." and "Applies-to Doc. Type".
        Initialize();


        // [GIVEN] Payment Line with "Account Type"::Vendor and no existing Vendor Ledger entry.
        AppliesToID := LibraryUtility.GenerateRandomCode(PaymentLine.FieldNo("Applies-to ID"), DATABASE::"Vendor Ledger Entry");
        DocNo := LibraryUtility.GenerateRandomCode(VendorLedgerEntry.FieldNo("Document No."), DATABASE::"Vendor Ledger Entry");
        DocType := "Gen. Journal Document Type".FromInteger(LibraryRandom.RandInt(7));
        MockPaymentSlipWithPaymentLine(PaymentHeader, PaymentLine."Account Type"::Vendor, AppliesToID, DocNo, DocType);
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindFirst();

        // [WHEN] Codeunit "Payment-Apply" is run for Payment Line.
        CODEUNIT.Run(CODEUNIT::"Payment-Apply FR", PaymentLine);

        // [THEN] "Applies-to Doc. No." and "Applies-to Doc. Type" are the same as before.
        Assert.AreEqual(DocNo, PaymentLine."Applies-to Doc. No.", '');
        Assert.AreEqual(DocType, PaymentLine."Applies-to Doc. Type", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentJournalFieldsTransferToPostedJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] TransferFields copies the app payment context using matching field IDs.
        Initialize();

        // [GIVEN] Journal line "J" contains the app payment context.
        GenJournalLine."Delayed Unreal. VAT" := true;
        GenJournalLine."Realize Delayed VAT" := true;
        GenJournalLine."Created From Pmt. Slip No." := 'PAYMENT-SLIP';

        // [WHEN] The journal line is copied to a posted journal line.
        PostedGenJournalLine.TransferFields(GenJournalLine);

        // [THEN] All three app fields are retained.
        VerifyPostedPaymentContext(PostedGenJournalLine, true, true, 'PAYMENT-SLIP');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyPaymentJournalFieldsClearPostedJournalContext()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] TransferFields also copies false flags and a blank payment slip number.
        Initialize();

        // [GIVEN] Posted journal line "P" has payment context but source "J" has none.
        PostedGenJournalLine."Delayed Unreal. VAT" := true;
        PostedGenJournalLine."Realize Delayed VAT" := true;
        PostedGenJournalLine."Created From Pmt. Slip No." := 'OLD-SLIP';

        // [WHEN] The empty payment context is transferred.
        PostedGenJournalLine.TransferFields(GenJournalLine);

        // [THEN] No stale payment context remains.
        VerifyPostedPaymentContext(PostedGenJournalLine, false, false, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentEnabledAllowsAppVATRealizationOnGLJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Enabled payment realization uses the app flag, not the false legacy flag.
        Initialize();

        // [GIVEN] Payment is enabled and G/L journal "J" has app-only realization.
        SetPaymentFeatureEnabled(true);
        CreateGLPaymentJournal(GenJournalLine);
        GenJournalLine."Realize Delayed VAT" := true;
        GenJournalLine."Applies-to Doc. No." := 'APPLIED-DOCUMENT';

        // [WHEN] The journal is checked through the BaseApp entry point.
        GenJnlCheckLine.RunCheck(GenJournalLine);

        // [THEN] Its application document survives the check.
        Assert.AreEqual('APPLIED-DOCUMENT', GenJournalLine."Applies-to Doc. No.", 'The app realization flag must permit the application document.');
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentEnabledRetainsOrdinaryGLAppliesToID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Ordinary French G/L-to-G/L journals retain the Applies-to ID relaxation.
        Initialize();

        // [GIVEN] Payment is enabled and ordinary G/L journal "J" has an application ID.
        SetPaymentFeatureEnabled(true);
        CreateGLPaymentJournal(GenJournalLine);
        GenJournalLine."Applies-to ID" := 'APPLICATION-ID';

        // [WHEN] The journal is checked without requesting VAT realization.
        GenJnlCheckLine.RunCheck(GenJournalLine);

        // [THEN] The existing French relaxation is preserved, rather than replaced by W1 validation.
        Assert.AreEqual('APPLICATION-ID', GenJournalLine."Applies-to ID", 'Ordinary French G/L journals must still allow an application ID.');
        RestorePaymentFeatureStatus();
    end;

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnabledCustomerPaymentDefersVATUsingAppFlag()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] A customer payment defers VAT using the new flag despite a false legacy flag.
        Initialize();

        // [GIVEN] Enabled Payment applies payment "P" to an invoice with unrealized VAT.
        SetPaymentFeatureEnabled(true);
        CreateUnrealizedVATPayment(GenJournalLine, VATEntry, GenJournalLine."Account Type"::Customer);
        GenJournalLine."Delayed Unreal. VAT" := true;

        // [WHEN] Payment "P" is posted with only the app delayed-VAT flag.
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] The invoice VAT remains unrealized.
        VerifyRemainingUnrealizedVAT(VATEntry, VATEntry."Unrealized Amount");
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnabledVendorPaymentDefersVATUsingAppFlag()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] A vendor payment defers VAT using the new flag despite a false legacy flag.
        Initialize();

        // [GIVEN] Enabled Payment applies payment "P" to a vendor invoice with unrealized VAT.
        SetPaymentFeatureEnabled(true);
        CreateUnrealizedVATPayment(GenJournalLine, VATEntry, GenJournalLine."Account Type"::Vendor);
        GenJournalLine."Delayed Unreal. VAT" := true;

        // [WHEN] Payment "P" is posted with only the app delayed-VAT flag.
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] The invoice VAT remains unrealized.
        VerifyRemainingUnrealizedVAT(VATEntry, VATEntry."Unrealized Amount");
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnabledCustomerPaymentIgnoresLegacyDelayedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Enabled customer application ignores a stale true legacy delayed-VAT flag.
        Initialize();

        // [GIVEN] Enabled payment "P" has only the legacy delayed-VAT flag.
        SetPaymentFeatureEnabled(true);
        CreateUnrealizedVATPayment(GenJournalLine, VATEntry, GenJournalLine."Account Type"::Customer);
        SetLegacyGenJournalContext(GenJournalLine, true, false, '');

        // [WHEN] The payment is applied to the invoice.
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] The false app flag allows VAT realization.
        VerifyRemainingUnrealizedVAT(VATEntry, 0);
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnabledVendorPaymentIgnoresLegacyDelayedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Enabled vendor application ignores a stale true legacy delayed-VAT flag.
        Initialize();

        // [GIVEN] Enabled payment "P" has only the legacy delayed-VAT flag.
        SetPaymentFeatureEnabled(true);
        CreateUnrealizedVATPayment(GenJournalLine, VATEntry, GenJournalLine."Account Type"::Vendor);
        SetLegacyGenJournalContext(GenJournalLine, true, false, '');

        // [WHEN] The payment is applied to the invoice.
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] The false app flag allows VAT realization.
        VerifyRemainingUnrealizedVAT(VATEntry, 0);
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentEnabledRejectsLegacyOnlyVATRealization()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] A true legacy realization flag cannot bypass an enabled app's false flag.
        Initialize();

        // [GIVEN] Enabled journal "J" has legacy-only realization and an application document.
        SetPaymentFeatureEnabled(true);
        CreateGLPaymentJournal(GenJournalLine);
        SetLegacyGenJournalContext(GenJournalLine, true, true, 'LEGACY-SLIP');
        GenJournalLine."Applies-to Doc. No." := 'APPLIED-DOCUMENT';

        // [WHEN] The journal is checked.
        asserterror GenJnlCheckLine.RunCheck(GenJournalLine);

        // [THEN] The app flag controls validation.
        Assert.ExpectedError(GenJournalLine.FieldCaption("Applies-to Doc. No."));
        Assert.ExpectedErrorCode(TestFieldErr);
        RestorePaymentFeatureStatus();
    end;

#if not CLEAN28
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledCustomerPaymentIgnoresAppDelayedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Disabled Payment ignores the app delayed-VAT flag during customer application.
        Initialize();

        // [GIVEN] Disabled payment "P" has only the app delayed-VAT flag.
        SetPaymentFeatureEnabled(false);
        CreateUnrealizedVATPayment(GenJournalLine, VATEntry, GenJournalLine."Account Type"::Customer);
        GenJournalLine."Delayed Unreal. VAT" := true;

        // [WHEN] The payment is applied to the invoice.
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] Legacy application realizes VAT despite the app flag.
        VerifyRemainingUnrealizedVAT(VATEntry, 0);
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledCustomerPaymentRetainsLegacyDelayedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Disabled Payment still honors the legacy delayed-VAT flag during customer application.
        Initialize();

        // [GIVEN] Disabled payment "P" has only the legacy delayed-VAT flag.
        SetPaymentFeatureEnabled(false);
        CreateUnrealizedVATPayment(GenJournalLine, VATEntry, GenJournalLine."Account Type"::Customer);
        SetLegacyGenJournalContext(GenJournalLine, true, false, '');

        // [WHEN] The payment is applied to the invoice.
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] Legacy application keeps the VAT unrealized.
        VerifyRemainingUnrealizedVAT(VATEntry, VATEntry."Unrealized Amount");
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentDisabledRejectsAppOnlyVATRealization()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Disabled Payment ignores new flags and retains legacy journal validation.
        Initialize();

        // [GIVEN] Payment is disabled in the real company status and "J" has app-only realization.
        SetPaymentFeatureEnabled(false);
        CreateGLPaymentJournal(GenJournalLine);
        GenJournalLine."Delayed Unreal. VAT" := true;
        GenJournalLine."Realize Delayed VAT" := true;
        GenJournalLine."Applies-to Doc. No." := 'APPLIED-DOCUMENT';

        // [WHEN] The journal is checked.
        asserterror GenJnlCheckLine.RunCheck(GenJournalLine);

        // [THEN] The false legacy flag still rejects the application document.
        Assert.ExpectedError(GenJournalLine.FieldCaption("Applies-to Doc. No."));
        Assert.ExpectedErrorCode(TestFieldErr);
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentDisabledAllowsLegacyVATRealization()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Disabled Payment uses a true legacy realization flag despite false app flags.
        Initialize();

        // [GIVEN] Disabled journal "J" has only legacy realization.
        SetPaymentFeatureEnabled(false);
        CreateGLPaymentJournal(GenJournalLine);
        SetLegacyGenJournalContext(GenJournalLine, true, true, 'LEGACY-SLIP');
        GenJournalLine."Applies-to Doc. No." := 'APPLIED-DOCUMENT';

        // [WHEN] The journal is checked.
        GenJnlCheckLine.RunCheck(GenJournalLine);

        // [THEN] Legacy behavior is preserved without populating the new flags.
        VerifyGenPaymentContext(GenJournalLine, false, false, '');
        RestorePaymentFeatureStatus();
    end;
#endif
#endif

#if not CLEANSCHEMA33
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentJournalMigrationCopiesTrueFalseAndBlankValues()
    var
        GenJournalLine: Record "Gen. Journal Line";
        OtherGenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        OtherPostedGenJournalLine: Record "Posted Gen. Journal Line";
        PaymentDataMigration: Codeunit "Payment Data Migration FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Both physical journal tables copy each Boolean state and both blank and populated origins.
        Initialize();

        // [GIVEN] Journal pairs "A" and "B" have opposite legacy/app values and no journal upgrade tag.
        ClearPaymentJournalUpgradeTag();
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, true, false, 'LEGACY-SLIP');
        CreatePaymentMigrationJournals(OtherGenJournalLine, OtherPostedGenJournalLine, false, true, '');

        // [WHEN] The separate journal migration runs.
        PaymentDataMigration.MigratePaymentVATJournalFields();

        // [THEN] All six physical fields are copied, including false and blank values.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, true, false, 'LEGACY-SLIP');
        VerifyMigratedPaymentJournals(OtherGenJournalLine, OtherPostedGenJournalLine, false, true, '');
        VerifyPaymentJournalUpgradeTag(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentJournalMigrationRerunPreservesAppEdits()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        PaymentDataMigration: Codeunit "Payment Data Migration FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] A successful journal migration never overwrites subsequent app changes.
        Initialize();

        // [GIVEN] Pair "A" was migrated, then the app context changed to false and a newer origin.
        ClearPaymentJournalUpgradeTag();
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, true, true, 'LEGACY-SLIP');
        PaymentDataMigration.MigratePaymentVATJournalFields();
        SetAppPaymentJournalContext(GenJournalLine, PostedGenJournalLine, false, false, 'NEWER-APP-SLIP');

        // [WHEN] The shared migration is requested again.
        PaymentDataMigration.MigratePaymentVATJournalFields();

        // [THEN] Both tables keep their newer app values.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, false, false, 'NEWER-APP-SLIP');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnabledPaymentUpgradeMigratesNewJournalFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        PaymentUpgrade: Codeunit "Upgrade Payment Management FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] An already enabled company with the original payment tag still migrates new journal fields.
        Initialize();

        // [GIVEN] Payment is enabled and the original migration is tagged, but pair "A" has not been migrated.
        SetPaymentFeatureEnabled(true);
        SetOriginalPaymentUpgradeTag();
        ClearPaymentJournalUpgradeTag();
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, true, false, 'OLD-COMPANY-SLIP');

        // [WHEN] The independent per-company upgrade step runs without forced activation.
        PaymentUpgrade.UpgradePaymentVATJournalFields(false);

        // [THEN] The old tag does not suppress the new migration.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, true, false, 'OLD-COMPANY-SLIP');
        VerifyPaymentJournalUpgradeTag(true);

        // [GIVEN] The enabled company subsequently changes its app payment context.
        SetAppPaymentJournalContext(GenJournalLine, PostedGenJournalLine, false, true, 'NEWER-APP-SLIP');

        // [WHEN] Another app upgrade runs.
        PaymentUpgrade.UpgradePaymentVATJournalFields(false);

        // [THEN] The successful migration tag protects the newer values.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, false, true, 'NEWER-APP-SLIP');
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnabledPaymentInstallMigratesJournalFieldsOnce()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        PaymentInstall: Codeunit "Install Payment Management FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Installation into an enabled company migrates journal fields once despite the original payment tag.
        Initialize();

        // [GIVEN] Payment is already enabled, the old tag exists, and pair "A" still has legacy values.
        SetPaymentFeatureEnabled(true);
        SetOriginalPaymentUpgradeTag();
        ClearPaymentJournalUpgradeTag();
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, true, false, 'INSTALL-SLIP');

        // [WHEN] The install entry point runs without forced activation.
        PaymentInstall.InstallPaymentVATJournalFields(false);

        // [THEN] Both journal tables migrate and the separate journal tag is set.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, true, false, 'INSTALL-SLIP');
        VerifyPaymentJournalUpgradeTag(true);

        // [GIVEN] The app subsequently changes its journal context.
        SetAppPaymentJournalContext(GenJournalLine, PostedGenJournalLine, false, true, 'NEWER-APP-SLIP');

        // [WHEN] Installation is retried.
        PaymentInstall.InstallPaymentVATJournalFields(false);

        // [THEN] The successful migration tag protects the newer app values.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, false, true, 'NEWER-APP-SLIP');
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentMigrationOverviewIncludesJournalTables()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        PaymentDataMigration: Codeunit "Payment Data Migration FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Journal context data is included when Feature Management checks whether data needs migration.
        Initialize();

        // [GIVEN] Pair "A" exists in the journal and posted journal tables.
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, true, false, 'LEGACY-SLIP');

        // [WHEN] The shared migration overview is collected.
        PaymentDataMigration.CountRecordsToMigrate(TempDocumentEntry);

        // [THEN] Both journal tables are represented.
        VerifyJournalMigrationOverview(TempDocumentEntry, Database::"Gen. Journal Line");
        VerifyJournalMigrationOverview(TempDocumentEntry, Database::"Posted Gen. Journal Line");
    end;

#if not CLEAN28
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledPaymentInstallLeavesJournalFieldsUntagged()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        PaymentInstall: Codeunit "Install Payment Management FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Installation before forced activation leaves a disabled company's journal fields eligible for late opt-in.
        Initialize();

        // [GIVEN] Payment is disabled, the original tag exists, and pair "A" has conflicting legacy and app values.
        SetPaymentFeatureEnabled(false);
        SetOriginalPaymentUpgradeTag();
        ClearPaymentJournalUpgradeTag();
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, true, true, 'LEGACY-SLIP');

        // [WHEN] The install entry point runs without forced activation.
        PaymentInstall.InstallPaymentVATJournalFields(false);

        // [THEN] Installation neither overwrites the app fields nor marks migration complete.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, false, false, 'APP-BEFORE-MIGRATION');
        VerifyPaymentJournalUpgradeTag(false);
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ForcedPaymentInstallMigratesDisabledJournalFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        PaymentInstall: Codeunit "Install Payment Management FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] Installation with version-31 forced activation migrates a disabled company's journal fields.
        Initialize();

        // [GIVEN] Payment is disabled, the old tag exists, and pair "A" has legacy journal context.
        SetPaymentFeatureEnabled(false);
        SetOriginalPaymentUpgradeTag();
        ClearPaymentJournalUpgradeTag();
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, false, true, 'FORCED-INSTALL');

        // [WHEN] The install entry point receives the version-31 forced-activation flag.
        PaymentInstall.InstallPaymentVATJournalFields(true);

        // [THEN] Both journal tables migrate despite the disabled status and old tag.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, false, true, 'FORCED-INSTALL');
        VerifyPaymentJournalUpgradeTag(true);
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledPaymentUpgradeWaitsForLateActivation()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PaymentUpgrade: Codeunit "Upgrade Payment Management FR";
        PaymentFeature: Codeunit "Feature - PaymentMgt FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] A disabled company remains untagged until activation copies its latest legacy values.
        Initialize();

        // [GIVEN] Disabled Payment has the old migration tag and pair "A" has conflicting app data.
        SetPaymentFeatureEnabled(false);
        SetOriginalPaymentUpgradeTag();
        ClearPaymentJournalUpgradeTag();
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, true, true, 'EARLY-SLIP');

        // [WHEN] An ordinary app upgrade runs while the feature is disabled.
        PaymentUpgrade.UpgradePaymentVATJournalFields(false);

        // [THEN] No journal tag is set and no app values are changed.
        VerifyPaymentJournalUpgradeTag(false);
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, false, false, 'APP-BEFORE-MIGRATION');

        // [GIVEN] Legacy journal values change before feature activation.
        SetLegacyPaymentJournals(GenJournalLine, PostedGenJournalLine, false, true, 'LATE-SLIP');
        FeatureDataUpdateStatus.Get('Payment', CompanyName());

        // [WHEN] Feature Management executes its real data update entry point.
        PaymentFeature.UpdateData(FeatureDataUpdateStatus);
        PaymentFeature.AfterUpdate(FeatureDataUpdateStatus);

        // [THEN] Activation copies the latest values and records the separate journal tag.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, false, true, 'LATE-SLIP');
        VerifyPaymentJournalUpgradeTag(true);
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ForcedPaymentUpgradeMigratesDisabledJournalFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        PaymentUpgrade: Codeunit "Upgrade Payment Management FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] The version-31 forced activation path migrates even with an old payment tag and disabled status.
        Initialize();

        // [GIVEN] Payment is disabled, the old tag exists, and pair "A" awaits migration.
        SetPaymentFeatureEnabled(false);
        SetOriginalPaymentUpgradeTag();
        ClearPaymentJournalUpgradeTag();
        CreatePaymentMigrationJournals(GenJournalLine, PostedGenJournalLine, true, true, 'FORCED-SLIP');

        // [WHEN] The journal upgrade step receives the version-31 forced-activation flag.
        PaymentUpgrade.UpgradePaymentVATJournalFields(true);

        // [THEN] Both tables migrate regardless of the old feature status or tag.
        VerifyMigratedPaymentJournals(GenJournalLine, PostedGenJournalLine, true, true, 'FORCED-SLIP');
        VerifyPaymentJournalUpgradeTag(true);
        RestorePaymentFeatureStatus();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledPaymentDoesNotRegisterJournalUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
        PerCompanyUpgradeTags: List of [Code[250]];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653673] New disabled companies must not pre-tag fields that may receive legacy data before activation.
        Initialize();

        // [GIVEN] Payment is disabled in the current company.
        SetPaymentFeatureEnabled(false);

        // [WHEN] Company initialization requests the registered tags.
        UpgradeTag.GetPerCompanyUpgradeTags(PerCompanyUpgradeTags);

        // [THEN] The journal tag is not pre-registered.
        Assert.IsFalse(PerCompanyUpgradeTags.Contains(UpgTagPayment.GetPaymentVATJournalFieldsUpgradeTag()), 'Disabled companies must migrate at activation.');

        // [GIVEN] An enabled company can also request tags for a different, disabled company.
        SetPaymentFeatureEnabled(true);
        Clear(PerCompanyUpgradeTags);

        // [WHEN] The generic registry is requested from the enabled company.
        UpgradeTag.GetPerCompanyUpgradeTags(PerCompanyUpgradeTags);

        // [THEN] It must not use the caller's feature status to pre-tag the other company.
        Assert.IsFalse(PerCompanyUpgradeTags.Contains(UpgTagPayment.GetPaymentVATJournalFieldsUpgradeTag()), 'Company initialization must evaluate the target company before setting the journal tag.');
        RestorePaymentFeatureStatus();
    end;
#endif
#endif

    local procedure Initialize()
    begin
        RestorePaymentFeatureStatus();
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGLPaymentJournal(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(), 100);
    end;

#if not CLEAN30
    local procedure CreateUnrealizedVATPayment(var PaymentGenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; AccountType: Enum "Gen. Journal Account Type")
    var
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        Vendor: Record Vendor;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        AccountNo: Code[20];
        VATAccountNo: Code[20];
        InvoiceAmount: Decimal;
    begin
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        if AccountType = AccountType::Customer then begin
            LibrarySales.CreateCustomer(Customer);
            Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            Customer.Validate("Payment Terms Code", '');
            Customer.Modify(true);
            AccountNo := Customer."No.";
            InvoiceAmount := 120;
            VATAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale);
        end else begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            Vendor.Validate("Payment Terms Code", '');
            Vendor.Modify(true);
            AccountNo := Vendor."No.";
            InvoiceAmount := -120;
            VATAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase);
        end;

        LibraryJournals.CreateGenJournalLineWithBatch(
            InvoiceGenJournalLine, InvoiceGenJournalLine."Document Type"::Invoice, AccountType, AccountNo, InvoiceAmount);
        InvoiceGenJournalLine.Validate("Bal. Account No.", VATAccountNo);
        InvoiceGenJournalLine.Validate(Amount, InvoiceAmount);
        GenJnlPostLine.RunWithCheck(InvoiceGenJournalLine);
        VATEntry.SetRange("Document No.", InvoiceGenJournalLine."Document No.");
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetFilter("Unrealized Amount", '<>0');
        VATEntry.FindFirst();
        Assert.AreNotEqual(0, VATEntry."Remaining Unrealized Amount", 'The invoice must have unrealized VAT before application.');

        LibraryJournals.CreateGenJournalLineWithBatch(
            PaymentGenJournalLine, PaymentGenJournalLine."Document Type"::Payment, AccountType, AccountNo, -InvoiceAmount);
        PaymentGenJournalLine.Validate("Applies-to Doc. Type", InvoiceGenJournalLine."Document Type");
        PaymentGenJournalLine.Validate("Applies-to Doc. No.", InvoiceGenJournalLine."Document No.");
    end;

    local procedure VerifyRemainingUnrealizedVAT(var VATEntry: Record "VAT Entry"; ExpectedAmount: Decimal)
    begin
        VATEntry.Get(VATEntry."Entry No.");
        Assert.AreEqual(ExpectedAmount, VATEntry."Remaining Unrealized Amount", 'The active payment feature must choose the delayed-VAT flag.');
    end;
#endif

    local procedure SetPaymentFeatureEnabled(FeatureEnabled: Boolean)
#if not CLEAN28
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#endif
    begin
#if not CLEAN28
        RestorePaymentFeatureStatus();
        FeatureKey.Get('Payment');
        PaymentFeatureStatusExisted := OriginalPaymentFeatureStatus.Get(FeatureKey.ID, CompanyName());
        if not PaymentFeatureStatusExisted then begin
            OriginalPaymentFeatureStatus.Init();
            OriginalPaymentFeatureStatus."Feature Key" := FeatureKey.ID;
            OriginalPaymentFeatureStatus."Company Name" :=
                CopyStr(CompanyName(), 1, MaxStrLen(OriginalPaymentFeatureStatus."Company Name"));
        end;
        FeatureDataUpdateStatus := OriginalPaymentFeatureStatus;
        if FeatureEnabled then
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Complete
        else
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled;
        if PaymentFeatureStatusExisted then
            FeatureDataUpdateStatus.Modify()
        else
            FeatureDataUpdateStatus.Insert();
        PaymentFeatureStatusChanged := true;
        UseActualPaymentFeatureStatus := true;
        Assert.AreEqual(FeatureEnabled, FeatureManagementFacade.IsEnabled('Payment'), 'The real per-company feature status must control both BaseApp and app.');
#else
        Assert.IsTrue(FeatureEnabled, 'Payment cannot be disabled after its feature switch is removed.');
#endif
    end;

    local procedure RestorePaymentFeatureStatus()
#if not CLEAN28
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
#endif
    begin
#if not CLEAN28
        UseActualPaymentFeatureStatus := false;
        if not PaymentFeatureStatusChanged then
            exit;

        if PaymentFeatureStatusExisted then begin
            FeatureDataUpdateStatus.Get('Payment', CompanyName());
            FeatureDataUpdateStatus."Feature Status" := OriginalPaymentFeatureStatus."Feature Status";
            FeatureDataUpdateStatus.Modify();
        end else
            if FeatureDataUpdateStatus.Get('Payment', CompanyName()) then
                FeatureDataUpdateStatus.Delete();
        PaymentFeatureStatusChanged := false;
#endif
    end;

    local procedure VerifyGenPaymentContext(GenJournalLine: Record "Gen. Journal Line"; DelayedVAT: Boolean; RealizeVAT: Boolean; OriginNo: Code[20])
    begin
        Assert.AreEqual(DelayedVAT, GenJournalLine."Delayed Unreal. VAT", 'Incorrect journal delayed VAT flag.');
        Assert.AreEqual(RealizeVAT, GenJournalLine."Realize Delayed VAT", 'Incorrect journal realization flag.');
        Assert.AreEqual(OriginNo, GenJournalLine."Created From Pmt. Slip No.", 'Incorrect journal payment slip origin.');
    end;

    local procedure VerifyPostedPaymentContext(PostedGenJournalLine: Record "Posted Gen. Journal Line"; DelayedVAT: Boolean; RealizeVAT: Boolean; OriginNo: Code[20])
    begin
        Assert.AreEqual(DelayedVAT, PostedGenJournalLine."Delayed Unreal. VAT", 'Incorrect posted journal delayed VAT flag.');
        Assert.AreEqual(RealizeVAT, PostedGenJournalLine."Realize Delayed VAT", 'Incorrect posted journal realization flag.');
        Assert.AreEqual(OriginNo, PostedGenJournalLine."Created From Pmt. Slip No.", 'Incorrect posted journal payment slip origin.');
    end;

#if not CLEANSCHEMA33
    local procedure ClearPaymentJournalUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentVATJournalFieldsUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgTagPayment.GetPaymentVATJournalFieldsUpgradeTag(), CopyStr(CompanyName(), 1, 30));
    end;

    local procedure SetOriginalPaymentUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag());
    end;

    local procedure VerifyPaymentJournalUpgradeTag(Expected: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
    begin
        Assert.AreEqual(Expected, UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentVATJournalFieldsUpgradeTag()), 'Incorrect company journal migration tag.');
    end;

    local procedure CreatePaymentMigrationJournals(var GenJournalLine: Record "Gen. Journal Line"; var PostedGenJournalLine: Record "Posted Gen. Journal Line"; DelayedVAT: Boolean; RealizeVAT: Boolean; OriginNo: Code[20])
    begin
        CreateGLPaymentJournal(GenJournalLine);
        PostedGenJournalLine.Init();
        PostedGenJournalLine.Insert();
        SetLegacyPaymentJournals(GenJournalLine, PostedGenJournalLine, DelayedVAT, RealizeVAT, OriginNo);
        SetAppPaymentJournalContext(GenJournalLine, PostedGenJournalLine, not DelayedVAT, not RealizeVAT, 'APP-BEFORE-MIGRATION');
    end;

    local procedure SetLegacyPaymentJournals(var GenJournalLine: Record "Gen. Journal Line"; var PostedGenJournalLine: Record "Posted Gen. Journal Line"; DelayedVAT: Boolean; RealizeVAT: Boolean; OriginNo: Code[20])
    var
        PostedJournalRef: RecordRef;
    begin
        SetLegacyGenJournalContext(GenJournalLine, DelayedVAT, RealizeVAT, OriginNo);
        GenJournalLine.Modify();
        PostedJournalRef.GetTable(PostedGenJournalLine);
        SetLegacyJournalContext(PostedJournalRef, DelayedVAT, RealizeVAT, OriginNo);
        PostedJournalRef.SetTable(PostedGenJournalLine);
        PostedGenJournalLine.Modify();
    end;

    local procedure SetLegacyGenJournalContext(var GenJournalLine: Record "Gen. Journal Line"; DelayedVAT: Boolean; RealizeVAT: Boolean; OriginNo: Code[20])
    var
        JournalRef: RecordRef;
    begin
        JournalRef.GetTable(GenJournalLine);
        SetLegacyJournalContext(JournalRef, DelayedVAT, RealizeVAT, OriginNo);
        JournalRef.SetTable(GenJournalLine);
    end;

    local procedure SetLegacyJournalContext(var JournalRef: RecordRef; DelayedVAT: Boolean; RealizeVAT: Boolean; OriginNo: Code[20])
    var
        JournalField: FieldRef;
    begin
        JournalField := JournalRef.Field(10862);
        JournalField.Value := DelayedVAT;
        JournalField := JournalRef.Field(10863);
        JournalField.Value := RealizeVAT;
        JournalField := JournalRef.Field(10864);
        JournalField.Value := OriginNo;
    end;

    local procedure SetAppPaymentJournalContext(var GenJournalLine: Record "Gen. Journal Line"; var PostedGenJournalLine: Record "Posted Gen. Journal Line"; DelayedVAT: Boolean; RealizeVAT: Boolean; OriginNo: Code[20])
    begin
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJournalLine."Delayed Unreal. VAT" := DelayedVAT;
        GenJournalLine."Realize Delayed VAT" := RealizeVAT;
        GenJournalLine."Created From Pmt. Slip No." := OriginNo;
        GenJournalLine.Modify();
        PostedGenJournalLine.Get(PostedGenJournalLine."Line No.");
        PostedGenJournalLine."Delayed Unreal. VAT" := DelayedVAT;
        PostedGenJournalLine."Realize Delayed VAT" := RealizeVAT;
        PostedGenJournalLine."Created From Pmt. Slip No." := OriginNo;
        PostedGenJournalLine.Modify();
    end;

    local procedure VerifyMigratedPaymentJournals(var GenJournalLine: Record "Gen. Journal Line"; var PostedGenJournalLine: Record "Posted Gen. Journal Line"; DelayedVAT: Boolean; RealizeVAT: Boolean; OriginNo: Code[20])
    begin
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        PostedGenJournalLine.Get(PostedGenJournalLine."Line No.");
        VerifyGenPaymentContext(GenJournalLine, DelayedVAT, RealizeVAT, OriginNo);
        VerifyPostedPaymentContext(PostedGenJournalLine, DelayedVAT, RealizeVAT, OriginNo);
    end;

    local procedure VerifyJournalMigrationOverview(var TempDocumentEntry: Record "Document Entry" temporary; TableId: Integer)
    begin
        TempDocumentEntry.SetRange("Table ID", TableId);
        Assert.IsTrue(TempDocumentEntry.FindFirst(), 'The journal table must be counted for feature activation.');
        Assert.IsTrue(TempDocumentEntry."No. of Records" > 0, 'The journal table must contain migration records.');
    end;
#endif

    local procedure CreateCustomerWithDefaultDimension(var DimensionValue: Record "Dimension Value") CustomerNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure OnValidateAccountNoErrorInPaymentLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; ErrorCode: Text)
    var
        PaymentLine: Record "Payment Line FR";
    begin
        // Setup: Create Payment Slip.
        CreatePaymentSlip(PaymentLine, AccountType);

        // Exercise.
        asserterror PaymentLine.Validate("Account No.", AccountNo);

        // Verify: Verify expected error code.
        Assert.ExpectedErrorCode(ErrorCode);
    end;

    local procedure OnValidateAccountNoInPaymentLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        PaymentLine: Record "Payment Line FR";
        PaymentSlip: TestPage "Payment Slip FR";
    begin
        // Setup: Create Payment Slip.
        CreatePaymentSlip(PaymentLine, AccountType);

        // Exercise.
        PaymentLine.Validate("Account No.", AccountNo);
        PaymentLine.Modify();

        // Verify: Verify Account No. in Payment Line.
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("No.", PaymentLine."No.");
        PaymentSlip.Lines."Account No.".AssertEquals(PaymentLine."Account No.");
        PaymentSlip.Close();
    end;

    local procedure CreateBlockedCustomer(Blocked: Enum "Customer Blocked"): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Blocked := Blocked;
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateBlockedVendor(Blocked: Enum "Vendor Blocked"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Blocked := Blocked;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentClass(var PaymentClass: Record "Payment Class FR")
    begin
        PaymentClass.Code := LibraryUTUtility.GetNewCode();
        PaymentClass."Unrealized VAT Reversal" := PaymentClass."Unrealized VAT Reversal"::Delayed;
        PaymentClass.Insert();
    end;

    local procedure CreatePaymentSlip(var PaymentLine: Record "Payment Line FR"; AccountType: Enum "Gen. Journal Account Type")
    var
        PaymentClass: Record "Payment Class FR";
        PaymentHeader: Record "Payment Header FR";
    begin
        PaymentClass.FindFirst();
        PaymentHeader."No." := LibraryUTUtility.GetNewCode();
        PaymentHeader."Payment Class" := PaymentClass.Code;
        PaymentHeader.Insert();
        PaymentLine."No." := PaymentHeader."No.";
        PaymentLine."Line No." := LibraryRandom.RandInt(10);
        PaymentLine."Account Type" := AccountType;
        PaymentLine.Insert();
    end;

    local procedure CreatePaymentStatus(var PaymentStatus: Record "Payment Status FR"; PaymentClass: Text[30])
    begin
        PaymentStatus."Payment Class" := PaymentClass;
        PaymentStatus.Name := LibraryUTUtility.GetNewCode();
        PaymentStatus.Insert();
    end;

    local procedure CreatePaymentStep(var PaymentStep: Record "Payment Step FR"; PaymentClass: Text[30])
    begin
        PaymentStep."Payment Class" := PaymentClass;
        PaymentStep.Name := LibraryUTUtility.GetNewCode();
        PaymentStep."Realize VAT" := true;
        PaymentStep.Insert();
    end;

    local procedure CreatePaymentStepLedger(var PaymentStepLedger: Record "Payment Step Ledger FR"; PaymentClass: Text[30])
    begin
        PaymentStepLedger."Payment Class" := PaymentClass;
        PaymentStepLedger.Insert();
    end;

    local procedure MockCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50])
    var
        EntryNo: Integer;
    begin
        if CustLedgerEntry.FindLast() then
            EntryNo := CustLedgerEntry."Entry No." + 1
        else
            EntryNo := 1;

        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := EntryNo;
        CustLedgerEntry."Applies-to ID" := AppliesToID;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry."Document Type" := "Gen. Journal Document Type".FromInteger(LibraryRandom.RandInt(7));
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
    end;

    local procedure MockPaymentSlipWithPaymentLine(var PaymentHeader: Record "Payment Header FR"; AccountType: Enum "Gen. Journal Account Type"; AppliesToID: Code[50]; AppliesToDocNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type")
    var
        PaymentLine: Record "Payment Line FR";
    begin
        PaymentHeader.Init();
        PaymentHeader."No." := LibraryUTUtility.GetNewCode();
        PaymentHeader.Insert();

        PaymentLine.Init();
        PaymentLine."No." := PaymentHeader."No.";
        PaymentLine."Line No." := LibraryRandom.RandInt(10);
        PaymentLine."Document No." := CopyStr(AppliesToID, 1, MaxStrLen(PaymentLine."Document No."));
        PaymentLine."Applies-to ID" := AppliesToID;
        PaymentLine."Applies-to Doc. No." := AppliesToDocNo;
        PaymentLine."Applies-to Doc. Type" := AppliesToDocType;
        PaymentLine."Account Type" := AccountType;
        PaymentLine.Insert();
    end;

    local procedure MockVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50])
    var
        EntryNo: Integer;
    begin
        if VendorLedgerEntry.FindLast() then
            EntryNo := VendorLedgerEntry."Entry No." + 1
        else
            EntryNo := 1;

        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := EntryNo;
        VendorLedgerEntry."Applies-to ID" := AppliesToID;
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateRandomCode(VendorLedgerEntry.FieldNo("Document No."), DATABASE::"Vendor Ledger Entry");
        VendorLedgerEntry."Document Type" := "Gen. Journal Document Type".FromInteger(LibraryRandom.RandInt(7));
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
    end;

    local procedure PaymentLineSetAccountNo(var PaymentLine: Record "Payment Line FR"; AccountNo: Code[20])
    begin
        PaymentLine.Validate("Account No.", AccountNo);
        PaymentLine.Modify(true);
    end;

    local procedure UnrealizedVATReversalTypePaymentClass(UnrealizedVATReversal: Option; ErrorCode: Text)
    var
        PaymentClass: Record "Payment Class FR";
        PaymentStep: Record "Payment Step FR";
    begin
        // Setup: Update General Ledger Setup, Create Payment Step and Create Payment Class.
        CreatePaymentClass(PaymentClass);
        CreatePaymentStep(PaymentStep, PaymentClass.Code);

        // Exercise.
        asserterror PaymentClass.Validate("Unrealized VAT Reversal", UnrealizedVATReversal);

        // Verify: Verify expected error code.
        Assert.ExpectedErrorCode(ErrorCode);
    end;

    local procedure UnrealizedVATReversalOnPaymentClass(UnrealizedVATReversal: Option; RealizeVAT: Boolean)
    var
        PaymentClass: Record "Payment Class FR";
        PaymentStep: Record "Payment Step FR";
        PaymentStepCard: TestPage "Payment Step Card FR";
    begin
        // Setup: Create Payment Class with Unrealized VAT Reversal, create Payment Step.
        CreatePaymentClass(PaymentClass);
        PaymentClass."Unrealized VAT Reversal" := UnrealizedVATReversal;
        PaymentClass.Modify();
        CreatePaymentStep(PaymentStep, PaymentClass.Code);
        PaymentStepCard.OpenEdit();
        PaymentStepCard.FILTER.SetFilter("Payment Class", PaymentClass.Code);

        // Exercise: Update Payment Step card with Action Type is Ledger.
        PaymentStepCard."Action Type".SetValue(PaymentStep."Action Type"::Ledger);

        // Verify: Verify Realize VAT control on Payment Step Card.
        Assert.AreEqual(RealizeVAT, PaymentStepCard."Realize VAT".Enabled(), UnexpectedErr);
        PaymentStepCard.Close();
    end;

    local procedure VerifyPaymentLineDimSetID(PaymentLine: Record "Payment Line FR"; DimensionSetID: Integer)
    begin
        PaymentLine.Find();
        PaymentLine.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyDimensionCountByDimSetID(var DimensionSetEntry: Record "Dimension Set Entry"; DimSetId: Integer; "Count": Integer)
    begin
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimSetId);
        Assert.RecordCount(DimensionSetEntry, Count);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure DimensionValueListModalPageHandler(var DimensionValueList: Page "Dimension Value List"; var Response: Action)
    var
        DimensionValue: Record "Dimension Value";
        DimensionCodeVar: Variant;
        DimensionValueCodVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCodeVar);
        LibraryVariableStorage.Dequeue(DimensionValueCodVar);
        DimensionValue.SetRange("Dimension Code", DimensionCodeVar);
        DimensionValue.SetRange(Code, DimensionValueCodVar);
        DimensionValue.FindFirst();
        DimensionValueList.SetRecord(DimensionValue);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: Page "Apply Customer Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: Page "Apply Vendor Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

#if not CLEAN28
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Management Feature FR", OnAfterCheckFeatureEnabled, '', false, false)]
    local procedure OnAfterCheckFeatureEnabled(var IsEnabled: Boolean)
    begin
        if not UseActualPaymentFeatureStatus then
            IsEnabled := true;
    end;
#endif
}
