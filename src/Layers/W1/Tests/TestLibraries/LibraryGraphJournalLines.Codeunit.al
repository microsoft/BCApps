codeunit 130622 "Library - Graph Journal Lines"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        Assert: Codeunit Assert;
        LibraryAPIGeneralJournal: Codeunit "Library API - General Journal";
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
        AmountNameTxt: Label 'amount';
        LineNumberNameTxt: Label 'lineNumber';
        DocumentNoNameTxt: Label 'documentNumber';
        ExternalDocumentNoNameTxt: Label 'externalDocumentNumber';
        DescriptionNameTxt: Label 'description';
        CommentNameTxt: Label 'comment';
        PostingDateNameTxt: Label 'postingDate';
        IsInitialized: Boolean;

    [Normal]
    procedure Initialize()
    begin
        if not IsInitialized then
            IsInitialized := true;

        EmptyJournals();

        Commit();
    end;

    local procedure EmptyJournals()
    var
        APIEntitiesSetup: Record "API Entities Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        APIEntitiesSetup.SafeGet();
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName());

        GenJournalLine.DeleteAll();

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName());

        GenJournalLine.DeleteAll();
    end;

    procedure GetNextJournalLineNo(JournalName: Code[10]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          GenJournalLine.GetNewLineNo(GraphMgtJournal.GetDefaultJournalLinesTemplateName(), JournalName));
    end;

    procedure GetNextCustomerPaymentNo(JournalName: Code[10]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          GenJournalLine.GetNewLineNo(GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName(), JournalName));
    end;

    procedure GetNextVendorPaymentNo(JournalName: Code[10]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          GenJournalLine.GetNewLineNo(GraphMgtJournal.GetDefaultVendorPaymentsTemplateName(), JournalName));
    end;

    procedure CreateJournalLine(JournalLineBatchName: Code[10]; AccountNo: Code[20]; AccountId: Guid; Amount: Decimal; DocumentNo: Code[20]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
    begin
        GenJournalLine.Init();
        GenJournalLine."Line No." := GetNextJournalLineNo(JournalLineBatchName);
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalLineBatchName);
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName());
        GenJournalLine.Validate("Journal Batch Name", JournalLineBatchName);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate(Amount, Amount);
        if DocumentNo = '' then
            DocumentNo := LibraryUtility.GenerateGUID();
        GenJournalLine.Validate("Document No.", DocumentNo);
        if not IsNullGuid(AccountId) then
            GenJournalLine.Validate("Account Id", AccountId);
        if AccountNo <> '' then
            GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Insert(true);

        exit(GenJournalLine."Line No.");
    end;

    procedure CreateSimpleJournalLine(JournalLineBatchName: Code[10]): Integer
    var
        BlankGUID: Guid;
    begin
        exit(CreateJournalLine(JournalLineBatchName, '', BlankGUID, 0, ''));
    end;

    procedure CreateJournalLineWithAmountAndDocNo(JournalLineBatchName: Code[10]; Amount: Decimal; DocumentNo: Code[20]): Integer
    var
        BlankGUID: Guid;
    begin
        exit(CreateJournalLine(JournalLineBatchName, '', BlankGUID, Amount, DocumentNo));
    end;

    procedure CreateCustomerPayment(CustomerPaymentBatchName: Code[10]; CustomerNo: Code[20]; CustomerId: Guid; AppliesToDocumentNo: Code[20]; AppliesToDocumentId: Guid; Amount: Decimal; DocumentNo: Code[20]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        GraphMgtCustomerPayments: Codeunit "Graph Mgt - Customer Payments";
    begin
        GenJournalLine.Init();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", CustomerPaymentBatchName);
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName());
        GenJournalLine.Validate("Journal Batch Name", CustomerPaymentBatchName);
        GenJournalLine."Line No." := GetNextCustomerPaymentNo(CustomerPaymentBatchName);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        if not IsNullGuid(CustomerId) then
            GenJournalLine.Validate("Customer Id", CustomerId);
        if CustomerNo <> '' then
            GenJournalLine.Validate("Account No.", CustomerNo);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        if not IsNullGuid(AppliesToDocumentId) then
            GenJournalLine.Validate("Applies-to Invoice Id", AppliesToDocumentId);
        if AppliesToDocumentNo <> '' then
            GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocumentNo);
        GenJournalLine.Insert(true);

        exit(GenJournalLine."Line No.");
    end;

    procedure CreateVendorPayment(VendorPaymentBatchName: Code[10]; VendorNo: Code[20]; VendorId: Guid; AppliesToDocumentNo: Code[20]; AppliesToDocumentId: Guid; Amount: Decimal; DocumentNo: Code[20]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        GraphMgtVendorPayments: Codeunit "Graph Mgt - Vendor Payments";
    begin
        GenJournalLine.Init();
        GraphMgtVendorPayments.SetVendorPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", VendorPaymentBatchName);
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultVendorPaymentsTemplateName());
        GenJournalLine.Validate("Journal Batch Name", VendorPaymentBatchName);
        GenJournalLine."Line No." := GetNextVendorPaymentNo(VendorPaymentBatchName);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        if not IsNullGuid(VendorId) then
            GenJournalLine.Validate("Vendor Id", VendorId);
        if VendorNo <> '' then
            GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        if not IsNullGuid(AppliesToDocumentId) then
            GenJournalLine.Validate("Applies-to Invoice Id", AppliesToDocumentId);
        if AppliesToDocumentNo <> '' then
            GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocumentNo);
        GenJournalLine.Insert(true);

        exit(GenJournalLine."Line No.");
    end;

    [Normal]
    procedure CreateAccount(): Text[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Account Category", GLAccount."Account Category"::Expense);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    [Normal]
    procedure CreateCustomer(): Text[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Normal]
    procedure CreateVendor(): Text[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateJournal(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalName: Code[10];
    begin
        JournalName := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultJournalLinesTemplateName(), JournalName);
        exit(JournalName);
    end;

    procedure CreateCustomerPaymentsJournal(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalName: Code[10];
    begin
        JournalName := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName(), JournalName);
        exit(JournalName);
    end;

    procedure CreateVendorPaymentsJournal(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalName: Code[10];
    begin
        JournalName := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultVendorPaymentsTemplateName(), JournalName);
        exit(JournalName);
    end;

    procedure CreatePostedSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader.Modify();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        exit(InvoiceNo);
    end;

    procedure CreatePostedPurchaseInvoice(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        InvoiceNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader."Posting Date" := WorkDate();
        PurchaseHeader.Modify();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 2);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        exit(InvoiceNo);
    end;

    procedure CreateLineWithGenericLineValuesJSON(NewLineNo: Integer; var NewAmount: Decimal): Text
    var
        LineJSON: Text;
        NewDocumentNo: Text;
        NewExternalDocumentNo: Text;
        NewDescription: Text;
        NewComment: Text;
        NewPostingDate: Text;
    begin
        NewAmount := LibraryRandom.RandDecInRange(1, 500, 1);
        NewDocumentNo := 'DOC001';
        NewExternalDocumentNo := 'EXTDOC01';
        NewDescription := 'Test Description';
        NewPostingDate := Format(WorkDate(), 0, 9);
        NewComment := 'Test Comment';

        LineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', LineNumberNameTxt, Format(NewLineNo));
        LineJSON := LibraryGraphMgt.AddComplexTypetoJSON(LineJSON, AmountNameTxt, Format(NewAmount, 0, 9));
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, DocumentNoNameTxt, NewDocumentNo);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, ExternalDocumentNoNameTxt, NewExternalDocumentNo);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, DescriptionNameTxt, NewDescription);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, CommentNameTxt, NewComment);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, PostingDateNameTxt, NewPostingDate);

        exit(LineJSON);
    end;

    procedure CheckLineWithGenericLineValues(GenJournalLine: Record "Gen. Journal Line"; NewAmount: Decimal)
    var
        NewDocumentNo: Text;
        NewExternalDocumentNo: Text;
        NewDescription: Text;
        NewComment: Text;
        NewDate: Date;
    begin
        NewDocumentNo := 'DOC001';
        NewExternalDocumentNo := 'EXTDOC01';
        NewDescription := 'Test Description';
        NewDate := WorkDate();
        NewComment := 'Test Comment';

        Assert.AreEqual(NewAmount, GenJournalLine.Amount, 'Journal Line ' + AmountNameTxt + ' should be changed');
        Assert.AreEqual(NewDocumentNo, GenJournalLine."Document No.", 'Journal Line ' + DocumentNoNameTxt + ' should be changed');
        Assert.AreEqual(
          NewExternalDocumentNo, GenJournalLine."External Document No.",
          'Journal Line ' + ExternalDocumentNoNameTxt + ' should be changed');
        Assert.AreEqual(NewDescription, GenJournalLine.Description, 'Journal Line ' + DescriptionNameTxt + ' should be changed');
        Assert.AreEqual(NewComment, GenJournalLine.Comment, 'Journal Line ' + CommentNameTxt + ' should be changed');
        Assert.AreEqual(NewDate, GenJournalLine."Posting Date", 'Journal Line ' + PostingDateNameTxt + ' should be changed');
    end;
}

