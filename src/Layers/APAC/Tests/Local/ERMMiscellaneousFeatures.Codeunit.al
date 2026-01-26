codeunit 141020 "ERM Miscellaneous Features"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustEqualMsg: Label 'Amount must be equal';
        BankAccPostingGroupErr: Label 'Bank Acc. Posting Group must have a value in Bank Account';
        DirectPostingErr: Label 'Direct Posting must be equal to ''Yes''  in G/L Account';
        GLAccountCap: Label 'glAccount';
        LedgerEntryNotExistErr: Label '%1 %2 does not exist';
        NodeValueCap: Label 'no';
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryApplicationArea: Codeunit "Library - Application Area";

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCrMemoAdjustmentMandatoryTrue()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        Amount: Decimal;
        OldAdjustmentMandatory: Boolean;
    begin
        // [FEATURE] [Adjustment Mandatory]
        // [SCENARIO] post service credit memo without any warning message when Adjustment Mandatory - True on General Ledger Setup.

        // [GIVEN] Create Customer with Adjustment Mandatory - TRUE on General Ledger Setup.
        Initialize();
        OldAdjustmentMandatory := UpdateGLSetupAdjustmentMandatory(true);
        LibrarySales.CreateCustomer(Customer);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        // [WHEN] Create and Post Service Credit Memo.
        Amount := CreateAndPostServiceCreditMemo(Customer."No.");

        // [THEN] Verify G/L Entry created successfully for posted Service Credit Memo, with Adjustment Mandatory - TRUE on General Ledger Setup.
        VerifyGLEntry(FindServiceCrMemoHeader(Customer."No."), CustomerPostingGroup."Receivables Account", -Amount);

        // Tear down.
        UpdateGLSetupAdjustmentMandatory(OldAdjustmentMandatory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodWithoutBankAccPostingGrpError()
    var
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Payment Method]
        // [SCENARIO] System does not allow to post the purchase order with payment methods code while Bank Acc. Posting Group - Blank.

        // [GIVEN] Create Payment Method with Bank Account without Bank Account Posting Group. Create Purchase Order with that Payment method Code.
        Initialize();
        CreatePaymentMethod(PaymentMethod, PaymentMethod."Bal. Account Type"::"Bank Account", CreateBankAccount());
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, Vendor."No.",
          PaymentMethod.Code, PurchaseLine.Type::"G/L Account", CreateGLAccount());

        // [WHEN] Post Purchase Order.
        asserterror PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [THEN] Verify Error - Bank Acc. Posting Group must have a value in Bank Account.
        Assert.ExpectedError(BankAccPostingGroupErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodWithoutDirectPostingGrpError()
    var
        PaymentMethod: Record "Payment Method";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Payment Method]
        // [SCENARIO] System does not allow posting of purchase invoice with Payment Method Code when direct Posting - FALSE  on G\L Account which one is defined on Bal Account No of Payment method code.

        // [GIVEN] Create Payment Method with G/L Account without Direct Posting. Create Purchase Invoice with that Payment method Code.
        Initialize();
        CreatePaymentMethod(PaymentMethod, PaymentMethod."Bal. Account Type"::"G/L Account", CreateGLAccount());
        UpdateGLAccountDirectPosting(PaymentMethod."Bal. Account No.", false);  // Direct Posting - FALSE.
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, Vendor."No.",
          PaymentMethod.Code, PurchaseLine.Type::"G/L Account", CreateGLAccount());

        // [WHEN] Post Purchase Invoice.
        asserterror PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [THEN] Verify Error - Direct Posting must be equal to 'Yes' in G/L Account.
        Assert.ExpectedError(DirectPostingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithInvoiceAdjustmentApplies()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Adjustment Applies-to]
        // [SCENARIO] Posted Sales Credit Memo and update Adjustment Applies To for posted Invoice.

        // [GIVEN] Create and post Sales Invoice. Create Sales Credit Memo and update Adjustment Applies To for posted Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, Customer."No.", LibraryInventory.CreateItem(Item), '');  // Location - Blank.
        DocumentNo := PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", Customer."No.", SalesLine."No.", '');
        UpdateAdjustmentAppliesToSalesCrMemo(SalesLine."Document No.", DocumentNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        // [WHEN] Post Sales Credit Memo.
        DocumentNo := PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.");

        // [THEN] Verify G/L Entry created for Sales Credit Memo.
        VerifyGLEntry(DocumentNo, CustomerPostingGroup."Receivables Account", -SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoWithInvoiceAdjustmentApplies()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Adjustment Applies-to]
        // [SCENARIO] Posted Purchase Credit Memo and update Adjustment Applies To for posted Invoice.

        // [GIVEN] Create and post Purchase Invoice. Create Purchase Credit Memo and update Adjustment Applies To for posted Invoice.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, Vendor."No.", '', PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item));  // Payment Method Code - Blank.
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", Vendor."No.", '', PurchaseLine.Type::Item, PurchaseLine."No.");  // Payment Method Code - Blank.
        UpdateAdjustmentAppliesToPurchaseCrMemo(PurchaseLine."Document No.", DocumentNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");

        // [WHEN] Post Purchase Credit Memo.
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [THEN] Verify G/L Entry created for Purchase Credit Memo.
        VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithInvoiceRandAdjustmentAppliesToError()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AdjustmentAppliesTo: Code[10];
    begin
        // [FEATURE] [Adjustment Applies-to]
        // [SCENARIO] Posted Sales Credit Memo and update Adjustment Applies To for posted Invoice with random value.

        // [GIVEN] Create and post Sales Invoice. Create Sales Credit Memo and update Adjustment Applies To for posted Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, Customer."No.", LibraryInventory.CreateItem(Item), '');  // Location - Blank.
        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", Customer."No.", SalesLine."No.", '');  // Location - Blank.
        AdjustmentAppliesTo := LibraryUtility.GenerateGUID();

        // [WHEN] Update Adjustment Applies To with random value.
        asserterror UpdateAdjustmentAppliesToSalesCrMemo(SalesLine."Document No.", AdjustmentAppliesTo);

        // [THEN] Verify Error - Customer Ledger Entry does not exist.
        Assert.ExpectedError(StrSubstNo(LedgerEntryNotExistErr, CustLedgerEntry.TableCaption(), AdjustmentAppliesTo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoWithInvoiceRandAdjustmentAppliesToError()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AdjustmentAppliesTo: Code[10];
    begin
        // [FEATURE] [Adjustment Applies-to]
        // [SCENARIO] Posted Purchase Credit Memo and update Adjustment Applies To for posted Invoice with random value.

        // [GIVEN] Create and post Purchase Invoice. Create Purchase Credit Memo and update Adjustment Applies To for posted Invoice.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, Vendor."No.", '', PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item));  // Payment Method Code - Blank.
        PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", Vendor."No.", '', PurchaseLine.Type::Item, PurchaseLine."No.");  // Payment Method Code - Blank.
        AdjustmentAppliesTo := LibraryUtility.GenerateGUID();

        // [WHEN] Update Adjustment Applies To with random value.
        asserterror UpdateAdjustmentAppliesToPurchaseCrMemo(PurchaseLine."Document No.", AdjustmentAppliesTo);

        // [THEN] Verify Error - Vendor Ledger Entry does not exist.
        Assert.ExpectedError(StrSubstNo(LedgerEntryNotExistErr, VendorLedgerEntry.TableCaption(), AdjustmentAppliesTo));
    end;

    [Test]
    [HandlerFunctions('ExportConsolidationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportConsolidationForAccountTypePosting()
    var
        GLAccount: Record "G/L Account";
        ExportConsolidation: Report "Export Consolidation";
        FilePath: Text[250];
    begin
        // [FEATURE] [Export Consolidation]
        // [SCENARIO] program does not populate any error message while doing the export on the consolidation report.

        // [GIVEN] Find G/L Account of Account Type Posting.
        Initialize();
        FilePath := TemporaryPath + LibraryUtility.GenerateGUID() + '.xml';
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.FindFirst();
        Commit();  // Commit required.
        LibraryVariableStorage.Enqueue(FilePath);  // Required inside ExportConsolidationRequestPageHandler.
        Clear(ExportConsolidation);

        // Exercise.
        ExportConsolidation.Run();

        // [THEN]  Verify Export Consolidation Report successfully showing data for G/L Account of Type Posting on XML.
        LibraryXMLRead.Initialize(FilePath);
        LibraryXMLRead.VerifyAttributeValue(GLAccountCap, NodeValueCap, GLAccount."No.");
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunRemittanceAdviceJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Purchase] [Remittance Advice]
        // [SCENARIO 272925] Remittance Advice - Journal report can be run from payment journal with #Suite application area
        Initialize();

        // [GIVEN] Enable Suite application area setup
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Payment journal line
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Open payment journal page with created line
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.GotoRecord(GenJournalLine);

        // [WHEN] Print Remittance Advance is being hit
        PaymentJournal.PrintRemittanceAdvance.Invoke();

        // [THEN] Report Remittance Advice - Journal opened
        // Verified by having RemittanceAdviceJournalRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('PrintRemitranceAdvanceStrMenuHandler,SelectSendingOptionModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunRemittanceAdviceEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        NameValueBuffer: Record "Name/Value Buffer";
        ERMMiscellaneousFeatures: Codeunit "ERM Miscellaneous Features";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Purchase] [Remittance Advice]
        // [SCENARIO 272925] Remittance Advice - Entries report can be run from vendor ledger entries page with #Suite application area
        Initialize();

        // [GIVEN] Enable Suite application area setup
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Mock payment vendor ledger entry
        MockPaymentVendorLedgerEntry(VendorLedgerEntry);

        // [GIVEN] Open vendor ledger entries page with created entry
        Commit();
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.GotoRecord(VendorLedgerEntry);

        BindSubscription(ERMMiscellaneousFeatures);

        // [WHEN] Print Remittance Advance is being hit
        VendorLedgerEntries.RemittanceAdvance.Invoke();

        // [THEN] Report Remittance Advice - Entries run (saved by OnAfterSaveReportAsPDF)
        NameValueBuffer.Get(SessionId());
        Assert.IsTrue(FILE.Exists(NameValueBuffer.Value), '');
        UnbindSubscription(ERMMiscellaneousFeatures);
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunRemittanceAdviceJournalByDefault()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Purchase] [Remittance Advice]
        // [SCENARIO 419949] Remittance Advice - Journal report by default is run when Report Selection for V. Remittance is empty
        Initialize();

        // [GIVEN] Enable Suite application area setup
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Payment journal line
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Report Selection for V.Remittance is empty
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        ReportSelections.DeleteAll(true);

        // [GIVEN] Open payment journal page with created line
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.GotoRecord(GenJournalLine);

        // [WHEN] Print Remittance Advance is being hit
        PaymentJournal.PrintRemittanceAdvance.Invoke();

        // [THEN] Report Remittance Advice - Journal opened
        // Verified by having RemittanceAdviceJournalRequestPageHandler
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostServiceCreditMemo(CustomerNo: Code[20]) Amount: Decimal
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", CreateGLAccount());
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        Amount := ServiceLine."Amount Including VAT";
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Ship and Invoice -TRUE, Consume - FALSE.
    end;

    local procedure CreatePaymentMethod(var PaymentMethod: Record "Payment Method"; BalAccountType: Enum "Payment Balance Account Type"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", BalAccountType);
        PaymentMethod.Validate("Bal. Account No.", BalAccountNo);
        PaymentMethod.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PaymentMethodCode: Code[10]; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Method Code", PaymentMethodCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Acc. Posting Group", '');
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Modify(true);
    end;

    local procedure FindServiceCrMemoHeader(CustomerNo: Code[20]): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure MockPaymentVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        EntryNo: Integer;
    begin
        VendorLedgerEntry.Reset();
        if VendorLedgerEntry.FindLast() then;
        EntryNo := VendorLedgerEntry."Entry No." + 1;
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := EntryNo;
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Payment;
        VendorLedgerEntry.Insert();
    end;

    local procedure UpdateGLSetupAdjustmentMandatory(AdjustmentMandatory: Boolean) OldAdjustmentMandatory: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdjustmentMandatory := GeneralLedgerSetup."Adjustment Mandatory";
        GeneralLedgerSetup.Validate("Adjustment Mandatory", AdjustmentMandatory);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGLAccountDirectPosting(No: Code[20]; DirectPosting: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(No);
        GLAccount.Validate("Direct Posting", DirectPosting);
        GLAccount.Modify(true);
    end;

    local procedure UpdateAdjustmentAppliesToSalesCrMemo(No: Code[20]; AdjustmentAppliesTo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", No);
        SalesHeader.Validate("Adjustment Applies-to", AdjustmentAppliesTo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateAdjustmentAppliesToPurchaseCrMemo(No: Code[20]; AdjustmentAppliesTo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", No);
        PurchaseHeader.Validate("Adjustment Applies-to", AdjustmentAppliesTo);
        PurchaseHeader.Modify(true);
    end;

    local procedure PostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(GLEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustEqualMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportConsolidationRequestPageHandler(var ExportConsolidation: TestRequestPage "Export Consolidation")
    var
        FilePath: Variant;
    begin
        LibraryVariableStorage.Dequeue(FilePath);
        ExportConsolidation.ClientFileNameControl.SetValue(FilePath);
        ExportConsolidation.StartDate.SetValue(WorkDate());
        ExportConsolidation.EndDate.SetValue(WorkDate());
        ExportConsolidation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceAdviceJournalRequestPageHandler(var RemittanceAdviceJournal: TestRequestPage "Remittance Advice - Journal")
    begin
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PrintRemitranceAdvanceStrMenuHandler(Options: Text; var Choice: Integer; Instructions: Text);
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options");
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        SelectSendingOptions.Printer.SetValue(DocumentSendingProfile.Printer::No);
        SelectSendingOptions."E-Mail".SetValue(DocumentSendingProfile."E-Mail"::No);
        SelectSendingOptions.Disk.SetValue(DocumentSendingProfile.Disk::PDF);
        SelectSendingOptions."Electronic Document".SetValue(DocumentSendingProfile."Electronic Document"::No);
        SelectSendingOptions.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure OnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.Init();
        NameValueBuffer.ID := SessionId();
        NameValueBuffer.Value := FromFileName;
        NameValueBuffer.Insert(true);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnAfterSaveReportAsPDF', '', false, false)]
    local procedure OnAfterSaveReportAsPDF(ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; FilePath: Text[250]; SaveToBlob: Boolean; var TempBlob: Codeunit "Temp Blob");
    var
        NameValueBuffer: Record "Name/Value Buffer";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        if TempBlob.HasValue() then begin
            // export the BLOB to a new temp server file.
            FileName := FileManagement.ServerTempFileName('pdf');
            FileManagement.BLOBExportToServerFile(TempBlob, FileName);

            NameValueBuffer.Init();
            NameValueBuffer.ID := SessionId();
            NameValueBuffer.Value := FileName;
            NameValueBuffer.Insert(true);
        end;
    end;

}

