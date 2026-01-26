codeunit 144092 "UT TAB Withhold"
{
    // Test for feature - WITHHOLD - Withholding Tax.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DialogErr: Label 'Dialog';
        ValueMustExistMsg: Label '%1 must exist.';

    [Test]
    [HandlerFunctions('PostedPurchaseInvoiceModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordShowInvoicePostedVendorBillLine()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        // Purpose of the test is to validate ShowInvoice Action of Table ID - 12184 Posted Vendor Bill Line.

        // Setup: Create Purchase Invoice Header and Posted Vendor Bill Line.
        Initialize();
        CreatePurchaseInvoiceHeader(PurchInvHeader);
        CreatePostedVendorBill(PostedVendorBillLine, PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."No.");

        // Enqueue values for PostedPurchaseInvoiceModalPageHandler.
        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Buy-from Vendor Name");

        // Exercise & Verify: Verify Purchase Invoice Header - Number and Buy From Vendor Number on handler - PostedPurchaseInvoiceModalPageHandler.
        PostedVendorBillLine.ShowInvoice();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBaseExcludedAmountError()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // Purpose of the test is to validate Base - Excluded Amount - OnValidate Trigger of Table ID - 12116 Withholding Tax.

        // Setup: Create Withholding Tax and validate Base - Excluded Amount.
        Initialize();
        CreateWithholdingTax(WithholdingTax);

        // Exercise.
        asserterror WithholdingTax.Validate(
            "Base - Excluded Amount", WithholdingTax."Total Amount" + LibraryRandom.RandDec(10, 2));

        // Verify: Verify expected error code: Actual error message: Base - Excluded Amount must not be greater than Total Amount.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertWithoutExistingEntryWithholdingTax()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 12116 Withholding Tax.

        // Setup.
        Initialize();
        WithholdingTax.DeleteAll();

        // Exercise.
        WithholdingTax.Insert(true);

        // Verify: Verify Entry Number with 1.
        WithholdingTax.TestField("Entry No.", 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertWithExistingEntryWithholdingTax()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTax2: Record "Withholding Tax";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 12116 Withholding Tax.

        // Setup.
        Initialize();
        WithholdingTax.DeleteAll();
        CreateWithholdingTax(WithholdingTax);

        // Exercise.
        WithholdingTax2.Insert(true);

        // Verify: Verify Withholding Tax - Entry Number.
        WithholdingTax2.TestField("Entry No.", WithholdingTax."Entry No." + 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnModifyReportedWithholdingTaxError()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // Purpose of the test is to validate OnModify Trigger of Table ID - 12116 Withholding Tax.

        // Setup.
        Initialize();
        CreateWithholdingTax(WithholdingTax);
        WithholdingTax.Reported := true;

        // Exercise.
        asserterror WithholdingTax.Modify(true);

        // Verify: Verify expected error code, actual error: Paid and/or certified withholding taxes cannot be modified.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteWithholdingTaxError()
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 12116 Withholding Tax and verify error - Operation cancelled.
        OnDeleteReportedPaidWithholdingTax(false, false);  // Reported as false and Paid as false.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteReportedWithholdingTaxError()
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 12116 Withholding Tax and verify error - Paid and certified withholding taxes cannot be deleted.
        OnDeleteReportedPaidWithholdingTax(true, false);  // Reported as true and Paid as false.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePaidWithholdingTaxError()
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 12116 Withholding Tax and verify error - Certified and not paid withholding taxes cannot be deleted.
        OnDeleteReportedPaidWithholdingTax(false, true);  // Reported as true and Paid as true.
    end;

    local procedure OnDeleteReportedPaidWithholdingTax(Reported: Boolean; Paid: Boolean)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // Setup.
        Initialize();
        CreateWithholdingTax(WithholdingTax);
        UpdateWithholdingTaxReportedAndPaid(WithholdingTax, Reported, Paid);

        // Exercise.
        asserterror WithholdingTax.Delete(true);

        // Verify: Verify expected error code for different errors.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateNonTaxableAmountByTreatyWithholdingTaxError()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 12116 Withholding Tax.

        // Setup.
        Initialize();
        CreateWithholdingTax(WithholdingTax);

        // Exercise.
        asserterror WithholdingTax.Validate("Non Taxable Amount By Treaty", LibraryRandom.RandDec(10, 2));

        // Verify: Verify expected error code, actual error: Non Taxable Amount By Treaty must not be greater than Total Amount - Base Excluded Amount.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckWithhEntryExistWithholdingTaxError()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WithholdingTax: Record "Withholding Tax";
    begin
        // Purpose of the test is to validate CheckWithhEntryExist function of Table ID - 12116 Withholding Tax.

        // Setup.
        Initialize();
        CreateVendLedgEntry(VendorLedgerEntry);
        CreateWithholdingTax(WithholdingTax);
        WithholdingTax."Document No." := VendorLedgerEntry."Document No.";
        WithholdingTax.Modify();

        // Exercise.
        asserterror WithholdingTax.CheckWithhEntryExist(VendorLedgerEntry);

        // Verify: Verify expected error code, actual error: Withholding Tax Entry already exists for Vendor Ledger Entry.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePaymentDateWithholdingTax()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // Purpose of the test is to validate Payment Date - OnValidate Trigger of Table ID - 12116 Withholding Tax.

        // Setup.
        Initialize();
        CreateWithholdingTax(WithholdingTax);
        CreateWithholdCodeLine(WithholdingTax."Withholding Tax Code");

        // Exercise.
        WithholdingTax.Validate("Payment Date", WorkDate());

        // Verify: Verify Year and Month on table Withholding Tax.
        WithholdingTax.TestField(Year, Date2DMY(WorkDate(), 3));
        WithholdingTax.TestField(Month, Date2DMY(WorkDate(), 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertWithholdTaxWithholdingTax()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WithholdingTax: Record "Withholding Tax";
        Vendor: Record Vendor;
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        // Purpose of the test is to validate InsertWithhold function of Table ID - 12116 Withholding Tax.

        // Setup.
        Initialize();
        CreateVendLedgEntry(VendorLedgerEntry);
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        WithholdCodeLine."Withhold Code" := Vendor."Withholding Tax Code";
        WithholdCodeLine.Insert();

        // Exercise.
        WithholdingTax.InsertWithholdTax(VendorLedgerEntry);

        // Verify: Verify Document Number and Document Date on Inserted record - Withholding Tax.
        WithholdingTax.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        Assert.IsTrue(WithholdingTax.FindFirst(), StrSubstNo(ValueMustExistMsg, WithholdingTax.TableCaption()));
        WithholdingTax.TestField("Document No.", VendorLedgerEntry."Document No.");
        WithholdingTax.TestField("Document Date", VendorLedgerEntry."Document Date");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertWithoutExistingEntryContributions()
    var
        Contributions: Record Contributions;
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 12117 Contributions.

        // Setup.
        Initialize();
        Contributions.DeleteAll();

        // Exercise.
        Contributions.Insert(true);

        // Verify: Verify Entry Number with 1.
        Contributions.TestField("Entry No.", 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertWithExistingEntryContributions()
    var
        Contributions: Record Contributions;
        Contributions2: Record Contributions;
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 12116 Withholding Tax.

        // Setup.
        Initialize();
        Contributions.DeleteAll();
        CreateContributions(Contributions);

        // Exercise.
        Contributions2.Insert(true);

        // Verify: Verify Contributions - Entry Number.
        Contributions2.TestField("Entry No.", Contributions."Entry No." + 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnModifyReportedContributionsError()
    var
        Contributions: Record Contributions;
    begin
        // Purpose of the test is to validate OnModify Trigger of Table ID - 12116 Withholding Tax.

        // Setup: Create Contributions.
        Initialize();
        CreateContributions(Contributions);
        Contributions.Reported := true;

        // Exercise.
        asserterror Contributions.Modify(true);

        // Verify: Verify expected error code, actual error: Paid and/or certified Social Security taxes cannot be modified.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteContributionsError()
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 12117 Withholding Tax and verify error - Operation cancelled.
        OnDeleteReportedINPSPaidContributions(false, false);  // Reported as false and Paid as false.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteReportedContributionsError()
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 12116 Withholding Tax and verify error - Certified and not paid Social Security taxes cannot be deleted.
        OnDeleteReportedINPSPaidContributions(true, false);  // Reported as true and Paid as false.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteINPSPaidContributionsError()
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 12116 Withholding Tax and verify error - Paid and not certified Social Security taxes cannot be deleted.
        OnDeleteReportedINPSPaidContributions(false, true);  // Reported as true and Paid as true.
    end;

    local procedure OnDeleteReportedINPSPaidContributions(Reported: Boolean; INPSPaid: Boolean)
    var
        Contributions: Record Contributions;
    begin
        // Setup.
        Initialize();
        CreateContributions(Contributions);
        UpdateContributionsReportedAndINPSPaid(Contributions, Reported, INPSPaid);

        // Exercise.
        asserterror Contributions.Delete(true);

        // Verify: Verify expected error code, and different actual error.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePaymentDateContributions()
    var
        Contributions: Record Contributions;
        ContributionCodeLine: Record "Contribution Code Line";
        SocialSecurityPct: Decimal;
        INAILPerMil: Decimal;
    begin
        // Purpose of the test is to validate Payment Date - OnValidate Trigger of Table ID - 12117 Contributions.

        // Setup: Create Contributions and Contribution Code Line with Contribution Type - INPS and INAIL.
        Initialize();
        CreateContributions(Contributions);
        SocialSecurityPct :=
          CreateContributionCodeLine(ContributionCodeLine."Contribution Type"::INPS, Contributions."Social Security Code");
        INAILPerMil := CreateContributionCodeLine(ContributionCodeLine."Contribution Type"::INAIL, Contributions."INAIL Code");

        // Exercise.
        Contributions.Validate("Payment Date", WorkDate());

        // Verify: Verify Year, Month, Social Security Percentage and INAIL Per Mil on table Contributions.
        Contributions.TestField(Year, Date2DMY(WorkDate(), 3));
        Contributions.TestField(Month, Date2DMY(WorkDate(), 2));
        Contributions.TestField("Social Security %", SocialSecurityPct);
        Contributions.TestField("INAIL Per Mil", INAILPerMil);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateWithholdingTaxCodeSourceWithholdingTaxIsSet()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdCode: Record "Withhold Code";
    begin
        // [SCENARIO 228203] "Source-Withholding Tax" is set when "Withholding Tax Code" is changed

        // [GIVEN] Withholding Tax "WT" without "Source-Withholding Tax"
        CreateEmptyWithholdingTax(WithholdingTax);

        // [GIVEN] Withhold Code "WC" with "Source-Withholding Tax" = TRUE
        CreateWithholdCode(WithholdCode);
        WithholdCode.Validate("Source-Withholding Tax", true);
        WithholdCode.Modify(true);
        CreateWithholdCodeLine(WithholdCode.Code);

        // [WHEN] Set "WT"."Withholding Tax Code" equal to "WC"
        WithholdingTax.Validate("Withholding Tax Code", WithholdCode.Code);
        WithholdingTax.Modify(true);

        // [THEN] "WT"."Source-Withholding Tax" is True
        WithholdingTax.TestField("Source-Withholding Tax", true);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateContributionCodeLine(ContributionType: Option; "Code": Code[20]): Decimal
    var
        ContributionCodeLine: Record "Contribution Code Line";
    begin
        ContributionCodeLine."Contribution Type" := ContributionType;
        ContributionCodeLine.Code := Code;
        ContributionCodeLine."Starting Date" := WorkDate();
        ContributionCodeLine."Social Security %" := LibraryRandom.RandDec(10, 2);
        ContributionCodeLine.Insert();
        exit(ContributionCodeLine."Social Security %");
    end;

    local procedure CreateContributions(var Contributions: Record Contributions)
    var
        Contributions2: Record Contributions;
    begin
        Contributions."Entry No." := 1;
        if Contributions2.FindLast() then
            Contributions."Entry No." := Contributions2."Entry No." + 1;
        Contributions."Social Security Code" := LibraryUTUtility.GetNewCode();
        Contributions."INAIL Code" := LibraryUTUtility.GetNewCode();
        Contributions.Insert();
    end;

    local procedure CreateWithholdingTax(var WithholdingTax: Record "Withholding Tax")
    begin
        CreateEmptyWithholdingTax(WithholdingTax);
        WithholdingTax."Vendor No." := CreateVendor();
        WithholdingTax."Withholding Tax Code" := CreateWithholdCodeCode();
        WithholdingTax."Posting Date" := WorkDate();
        WithholdingTax."Total Amount" := LibraryRandom.RandDec(10, 2);
        WithholdingTax.Modify();
    end;

    local procedure CreateEmptyWithholdingTax(var WithholdingTax: Record "Withholding Tax")
    var
        WithholdingTax2: Record "Withholding Tax";
    begin
        WithholdingTax."Entry No." := 1;
        if WithholdingTax2.FindLast() then
            WithholdingTax."Entry No." := WithholdingTax2."Entry No." + 1;
        WithholdingTax.Insert();
    end;

    local procedure CreateWithholdCodeCode(): Code[20]
    var
        WithholdCode: Record "Withhold Code";
    begin
        CreateWithholdCode(WithholdCode);
        exit(WithholdCode.Code);
    end;

    local procedure CreateWithholdCode(var WithholdCode: Record "Withhold Code")
    begin
        WithholdCode.Code := LibraryUTUtility.GetNewCode();
        WithholdCode.Insert();
    end;

    local procedure CreateWithholdCodeLine(WithholdCode: Code[20])
    var
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        WithholdCodeLine."Withhold Code" := WithholdCode;
        WithholdCodeLine."Starting Date" := WorkDate();
        WithholdCodeLine.Insert();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode10();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreatePurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Buy-from Vendor No." := CreateVendor();
        PurchInvHeader.Insert();
    end;

    local procedure CreatePostedVendorBill(var PostedVendorBillLine: Record "Posted Vendor Bill Line"; VendorNo: Code[20]; DocumentNo: Code[20])
    var
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
    begin
        PostedVendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        PostedVendorBillHeader."Bank Account No." := CreateBankAccount();
        PostedVendorBillHeader.Insert();

        PostedVendorBillLine."Vendor Bill No." := PostedVendorBillHeader."No.";
        PostedVendorBillLine."Document No." := DocumentNo;
        PostedVendorBillLine."Vendor No." := VendorNo;
        PostedVendorBillLine."Vendor Bank Acc. No." := PostedVendorBillHeader."Bank Account No.";
        PostedVendorBillLine.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Withholding Tax Code" := CreateWithholdCodeCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := CreateVendor();
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry."Document Date" := WorkDate();
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Insert();
    end;

    local procedure UpdateContributionsReportedAndINPSPaid(var Contributions: Record Contributions; Reported: Boolean; INPSPaid: Boolean)
    begin
        Contributions.Reported := Reported;
        Contributions."INPS Paid" := INPSPaid;
        Contributions.Modify();
    end;

    local procedure UpdateWithholdingTaxReportedAndPaid(var WithholdingTax: Record "Withholding Tax"; Reported: Boolean; Paid: Boolean)
    begin
        WithholdingTax.Reported := Reported;
        WithholdingTax.Paid := Paid;
        WithholdingTax.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceModalPageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    var
        No: Variant;
        BuyFromVendorName: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(BuyFromVendorName);
        PostedPurchaseInvoice.FILTER.SetFilter("No.", No);
        PostedPurchaseInvoice."Buy-from Vendor Name".AssertEquals(BuyFromVendorName);
        PostedPurchaseInvoice.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

