codeunit 144019 "Telebank - Manual Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        GlobalVendorNo: Code[20];

    [Test]
    [HandlerFunctions('EBBatchHandler,SuggestVendorPaymentsHandler')]
    [Scope('OnPrem')]
    procedure TotalRemitteeAmount()
    var
        ExportProtocol: Record "Export Protocol";
        BankAccount: Record "Bank Account";
        CountryRegion: Record "Country/Region";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        EBPaymentJournal: TestPage "EB Payment Journal";
        DocumentNo: Code[20];
        AmountInclVAT: Decimal;
        TotalAmountInclVAT: Decimal;
    begin
        // Init
        CountryRegion.SetRange(Code, 'BE');
        CountryRegion.ModifyAll("SEPA Allowed", true);

        CreateExportProtocol(ExportProtocol, ExportProtocol."Code Expenses"::SHA, 2000002, 2000001, '');
        CreateExportProtocol(ExportProtocol, ExportProtocol."Code Expenses"::SHA, 2000003, 2000002, '');
        CreateExportProtocol(ExportProtocol, ExportProtocol."Code Expenses"::SHA, 2000004, 2000001, LibraryERM.CreateNoSeriesCode());

        CreateBankAccount(BankAccount);
        CreateVendorWithBankAccount(Vendor);

        VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        VATPostingSetup.SetFilter("VAT %", '>%1', 0);
        if not VATPostingSetup.FindFirst() then
            VATPostingSetup.Init();

        LibraryInventory.CreateItem(Item);
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10, 100);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // interim validation
        ValidatePostedDoc(DocumentNo, 1000, VATPostingSetup."VAT %", AmountInclVAT);
        TotalAmountInclVAT += AmountInclVAT;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 20, 100);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // interim validation
        ValidatePostedDoc(DocumentNo, 2000, VATPostingSetup."VAT %", AmountInclVAT);
        TotalAmountInclVAT += AmountInclVAT;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 30, 100);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // interim validation
        ValidatePostedDoc(DocumentNo, 3000, VATPostingSetup."VAT %", AmountInclVAT);
        TotalAmountInclVAT += AmountInclVAT;

        // Execution
        GlobalVendorNo := Vendor."No.";
        EBPaymentJournal.OpenEdit();
        EBPaymentJournal.CurrentJnlBatchName.Lookup(); // Opens batch list. Create new batch and click OK
        Commit();
        EBPaymentJournal.SuggestVendorPayments.Invoke(); // Opens Suggest vendor payments. Run it.

        // Validation
        Assert.AreEqual(TotalAmountInclVAT, EBPaymentJournal.BalanceRem.AsDecimal(), '');
    end;

    [Test]
    [HandlerFunctions('EBBatchHandler,SuggestVendorPaymentsHandlerWithErr')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsForBlockedVendorAll()
    begin
        SuggestVendorPaymentsForBlockedVendor(true);
    end;

    [Test]
    [HandlerFunctions('EBBatchHandler,SuggestVendorPaymentsHandlerWithErr')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsForBlockedVendorPmt()
    begin
        SuggestVendorPaymentsForBlockedVendor(false);
    end;

    local procedure SuggestVendorPaymentsForBlockedVendor(BlockedAll: Boolean)
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        EBPaymentJournal: TestPage "EB Payment Journal";
    begin
        CreateVendorWithBankAccount(Vendor);
        Vendor.Modify();
        CreateBankAccount(BankAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name, false);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", -1210);
        GenJournalLine."External Document No." := '0001';
        GenJournalLine."Posting Date" := WorkDate();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        if BlockedAll then
            Vendor.Blocked := Vendor.Blocked::All
        else
            Vendor.Blocked := Vendor.Blocked::Payment;
        Vendor.Modify();
        GlobalVendorNo := Vendor."No.";

        // Execution and validation
        EBPaymentJournal.OpenEdit();
        EBPaymentJournal.CurrentJnlBatchName.Lookup(); // Opens batch list. Create new batch and click OK
        Commit();
        asserterror EBPaymentJournal.SuggestVendorPayments.Invoke(); // Opens Suggest vendor payments. Run it.
        Assert.IsTrue(StrPos(GetLastErrorText, 'You cannot create this type of document when Vendor') > 0, '');
    end;

    local procedure CreateExportProtocol(var ExportProtocol: Record "Export Protocol"; NewCodeExpenses: Option; NewCheckObjectID: Integer; NewExportObjectID: Integer; NewExportNoSeries: Code[20])
    begin
        ExportProtocol.Init();
        ExportProtocol.Code := CopyStr(CreateGuid(), 1, 10);
        ExportProtocol.Description := ExportProtocol.Code;

        ExportProtocol."Code Expenses" := NewCodeExpenses;
        ExportProtocol."Export Object Type" := ExportProtocol."Export Object Type"::Report;
        ExportProtocol."Check Object ID" := NewCheckObjectID;
        ExportProtocol."Export Object ID" := NewExportObjectID;
        ExportProtocol."Export No. Series" := NewExportNoSeries;
        ExportProtocol.Insert();
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify();
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Country/Region Code" := 'BE';
        BankAccount."SWIFT Code" := 'GKCCBEBB';
        BankAccount.IBAN := 'BE65 0631 1416 5496';
        BankAccount.Modify();
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify();
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateName: Code[10]; WithNoSeries: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateName);
        LibraryERM.CreateGLAccount(GLAccount);
        if WithNoSeries then
            GenJournalBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := GLAccount."No.";
        GenJournalBatch.Modify();
    end;

    local procedure ValidatePostedDoc(DocumentNo: Code[20]; Amount: Decimal; VatPct: Decimal; var AmountInclVAT: Decimal)
    var
        VATAmount: Decimal;
    begin
        VATAmount := Round(Amount * VatPct / 100);
        AmountInclVAT := Amount + VATAmount;
        ValidateGLentries(DocumentNo, Amount, VATAmount, -AmountInclVAT);
    end;

    local procedure ValidateGLentries(DocumentNo: Code[20]; Amount1: Decimal; Amount2: Decimal; Amount3: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Found: array[3] of Boolean;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        Found[1] := Amount1 = 0;
        Found[2] := Amount2 = 0;
        Found[3] := Amount3 = 0;
        repeat
            Found[1] := Found[1] or (Amount1 = GLEntry.Amount);
            Found[2] := Found[2] or (Amount2 = GLEntry.Amount);
            Found[3] := Found[3] or (Amount3 = GLEntry.Amount);
        until GLEntry.Next() = 0;
        Assert.IsTrue(Found[1], StrSubstNo('%1 was not found.', Amount1));
        Assert.IsTrue(Found[2], StrSubstNo('%1 was not found.', Amount2));
        Assert.IsTrue(Found[3], StrSubstNo('%1 was not found.', Amount3));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EBBatchHandler(var EBPaymentJournalBatches: TestPage "EB Payment Journal Batches")
    begin
        EBPaymentJournalBatches.New();
        EBPaymentJournalBatches.Name.Value := CopyStr(CreateGuid(), 1, 10);
        EBPaymentJournalBatches.Description.Value := EBPaymentJournalBatches.Name.Value();
        EBPaymentJournalBatches.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsHandler(var SuggestVendorPaymentsEB: TestRequestPage "Suggest Vendor Payments EB")
    begin
        SuggestVendorPaymentsEB.Vend.SetFilter("No.", GlobalVendorNo);
        SuggestVendorPaymentsEB.DueDate.SetValue(CalcDate('<02M-3D>', WorkDate()));
        SuggestVendorPaymentsEB.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsHandlerWithErr(var SuggestVendorPaymentsEB: TestRequestPage "Suggest Vendor Payments EB")
    begin
        SuggestVendorPaymentsEB.Vend.SetFilter("No.", GlobalVendorNo);
        SuggestVendorPaymentsEB.DueDate.SetValue(CalcDate('<02M-3D>', WorkDate()));
        SuggestVendorPaymentsEB.OK().Invoke();
    end;
}

