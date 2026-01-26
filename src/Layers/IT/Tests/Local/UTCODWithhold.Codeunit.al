codeunit 144091 "UT COD Withhold"
{
    // Test for feature - WITHHOLD - Withholding Tax.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Withholding Tax] [UT]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FromSentToOpenFalseManualLineVendBilListChangeStatus()
    begin
        // Purpose of the test is to validate FromSentToOpen function of Codeunit - 12171 Vend. Bill List-Change Status.
        FromSentToOpenManualLineVendBilListChangeStatus(false);  // Manual Line as False.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FromSentToOpenTrueManualLineVendBilListChangeStatus()
    begin
        // Purpose of the test is to validate FromSentToOpen function of Codeunit - 12171 Vend. Bill List-Change Status.
        FromSentToOpenManualLineVendBilListChangeStatus(true);  // Manual Line as True.
    end;

    [Test]
    procedure WithholdingContribution_WithholdApplicable_ZeroTaxAmount()
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        WithholdingContribution: Codeunit "Withholding - Contribution";
    begin
        // [SCENARIO 395226] COD 12101 "Withholding - Contribution".WithholdApplicable() returns TRUE in case of
        // [SCENARIO 395226] "Non Taxable %" <> 100, "Withholding Tax Amount" = 0, CalledFromVendBillLine = TRUE

        // [GIVEN] Tmp Withholding Contribution record with "Non Taxable %" = 0
        TmpWithholdingContribution."Withholding Tax Code" := LibraryUTUtility.GetNewCode();
        TmpWithholdingContribution."Non Taxable %" := 0;
        TmpWithholdingContribution."Withholding Tax Amount" := 0;
        Assert.IsTrue(WithholdingContribution.WithholdApplicable(TmpWithholdingContribution, true), 'WithholdApplicable()');
    end;

    [TransactionModel(TransactionModel::AutoCommit)]
    local procedure FromSentToOpenManualLineVendBilListChangeStatus(ManualLine: Boolean)
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendBilListChangeStatus: Codeunit "Vend. Bill List-Change Status";
    begin
        // Setup: Create Vendor Bill Header, Vendor Bill Line and Vendor Ledger Entry.
        CreateVendorBillHeader(VendorBillHeader);
        CreateVendorBillLine(VendorBillHeader."No.", ManualLine);

        // Exercise.
        VendBilListChangeStatus.FromSentToOpen(VendorBillHeader);

        // Verify: Verify Vendor Bill Number with blank, Vendor Bill List Number with blank and List Status as Open.
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.FindFirst();
        VendorBillLine.TestField("Vendor Bill No.", '');
        VendorBillHeader.TestField("Vendor Bill List No.", '');
        VendorBillHeader.TestField("List Status", VendorBillHeader."List Status"::Open);
    end;

    local procedure CreateVendorBillHeader(var VendorBillHeader: Record "Vendor Bill Header")
    begin
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        VendorBillHeader."Vendor Bill List No." := LibraryUTUtility.GetNewCode();
        VendorBillHeader."List Status" := VendorBillHeader."List Status"::Sent;
        VendorBillHeader.Insert();
    end;

    local procedure CreateVendorBillLine(VendorBillListNo: Code[20]; ManualLine: Boolean)
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        VendorBillLine."Vendor Bill List No." := VendorBillListNo;
        VendorBillLine."Vendor Entry No." := CreateVendorLedgerEntry();
        VendorBillLine."Manual Line" := ManualLine;
        VendorBillLine.Insert();
    end;

    local procedure CreateVendorLedgerEntry(): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

