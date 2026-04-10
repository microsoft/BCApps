codeunit 139033 "Test Job Queue Status"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue Status field] [Background Posting]        
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        UnsupportedDocTypeErr: Label 'Test does not support this document type.';
        JobQueueErrorMsg: Label 'This is error.';
        JobQueueScheduledMsg: Label 'Scheduled for posting on  by .';
        JobQueuePostingMsg: Label 'In Process';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBackgroundPostingErrorTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueErrorMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::Invoice, DummySalesHeader."Job Queue Status"::Error);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderBackgroundPostingErrorTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueErrorMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::Order, DummySalesHeader."Job Queue Status"::Error);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoBackgroundPostingErrorTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueErrorMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::"Credit Memo", DummySalesHeader."Job Queue Status"::Error);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderBackgroundPostingErrorTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueErrorMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::"Return Order", DummySalesHeader."Job Queue Status"::Error);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceScheduledForBackgroundPostingTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueScheduledMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::Invoice, DummySalesHeader."Job Queue Status"::"Scheduled for Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderScheduledForBackgroundPostingTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueScheduledMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::Order, DummySalesHeader."Job Queue Status"::"Scheduled for Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoScheduledForBackgroundPostingTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueScheduledMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::"Credit Memo", DummySalesHeader."Job Queue Status"::"Scheduled for Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderScheduledForBackgroundPostingTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueScheduledMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::"Return Order", DummySalesHeader."Job Queue Status"::"Scheduled for Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBackgroundPostingTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueuePostingMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::Invoice, DummySalesHeader."Job Queue Status"::Posting);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderBackgroundPostingTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueuePostingMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::Order, DummySalesHeader."Job Queue Status"::Posting);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemorBackgroundPostingTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueuePostingMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::"Credit Memo", DummySalesHeader."Job Queue Status"::Posting);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderBackgroundPostingTest()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueuePostingMsg);
        VerifySalesDocumentBackgroundPostingState(
          DummySalesHeader."Document Type"::"Return Order", DummySalesHeader."Job Queue Status"::Posting);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceBackgroundPostingErrorTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueErrorMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::Invoice, DummyPurchaseHeader."Job Queue Status"::Error);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderBackgroundPostingErrorTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueErrorMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::Order, DummyPurchaseHeader."Job Queue Status"::Error);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoBackgroundPostingErrorTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueErrorMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::"Credit Memo", DummyPurchaseHeader."Job Queue Status"::Error);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderBackgroundPostingErrorTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueErrorMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::"Return Order", DummyPurchaseHeader."Job Queue Status"::Error);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceoScheduledForBackgroundPostingTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueScheduledMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::Invoice, DummyPurchaseHeader."Job Queue Status"::"Scheduled for Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderoScheduledForBackgroundPostingTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueScheduledMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::Order, DummyPurchaseHeader."Job Queue Status"::"Scheduled for Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemooScheduledForBackgroundPostingTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueScheduledMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::"Credit Memo", DummyPurchaseHeader."Job Queue Status"::"Scheduled for Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderoScheduledForBackgroundPostingTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueueScheduledMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::"Return Order", DummyPurchaseHeader."Job Queue Status"::"Scheduled for Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceBackgroundPostingTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueuePostingMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::Invoice, DummyPurchaseHeader."Job Queue Status"::Posting);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderBackgroundPostingTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueuePostingMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::Order, DummyPurchaseHeader."Job Queue Status"::Posting);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoBackgroundPostingTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueuePostingMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::"Credit Memo", DummyPurchaseHeader."Job Queue Status"::Posting);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderBackgroundPostingTest()
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(JobQueuePostingMsg);
        VerifyPurchaseDocumentBackgroundPostingState(
          DummyPurchaseHeader."Document Type"::"Return Order", DummyPurchaseHeader."Job Queue Status"::Posting);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Job Queue Status");

        DeleteAllJobQueueEntries();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Test Job Queue Status");
        SalesAndPurchSetup();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Test Job Queue Status");
    end;

    local procedure SalesAndPurchSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Post with Job Queue" := true;
        SalesSetup."Ext. Doc. No. Mandatory" := true;
        SalesSetup.Modify();
        PurchSetup.Get();
        PurchSetup."Post with Job Queue" := true;
        PurchSetup."Ext. Doc. No. Mandatory" := true;
        PurchSetup.Modify();
    end;

    local procedure DeleteAllJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader."External Document No." := SalesHeader."No.";
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Modify(true);

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", LibraryInventory.CreateItemNo());
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then
            PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Receive := true;
        PurchaseHeader.Invoice := true;
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then begin
            PurchaseLine.Validate("Direct Unit Cost", 1);
            PurchaseLine.Validate("Qty. to Receive", 0);
        end;
        PurchaseLine.Modify(true);
    end;

    local procedure VerifySalesDocumentBackgroundPostingState(DocumentType: Enum "Sales Document Type"; JobQueueStatus: Enum "Document Job Queue Status")
    var
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        CreateJobQueueEntryWithStatus(JobQueueEntry, GetJobQueueEntryStatusFromDocJobQueueStatus(JobQueueStatus), JobQueueErrorMsg);
        SalesHeader."Job Queue Entry ID" := JobQueueEntry.ID;
        SalesHeader."Job Queue Status" := JobQueueStatus;
        SalesHeader.Modify();

        InvokeJobStatusStateOnSalesDocument(SalesHeader);
    end;

    local procedure VerifyPurchaseDocumentBackgroundPostingState(DocumentType: Enum "Purchase Document Type"; JobQueueStatus: Enum "Document Job Queue Status")
    var
        PurchaseHeader: Record "Purchase Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType);
        CreateJobQueueEntryWithStatus(JobQueueEntry, GetJobQueueEntryStatusFromDocJobQueueStatus(JobQueueStatus), JobQueueErrorMsg);
        PurchaseHeader."Vendor Invoice No." := '';
        PurchaseHeader."Job Queue Entry ID" := JobQueueEntry.ID;
        PurchaseHeader."Job Queue Status" := JobQueueStatus;
        PurchaseHeader.Modify();

        InvokeJobStatusStateOnPurchaseDocument(PurchaseHeader);
    end;

    local procedure InvokeJobStatusStateOnSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
        SalesOrderList: TestPage "Sales Order List";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesInvoiceList.OpenView();
                    SalesInvoiceList.GotoRecord(SalesHeader);
                    SalesInvoiceList."Job Queue Status".Lookup();
                end;
            SalesHeader."Document Type"::Order:
                begin
                    SalesOrderList.OpenView();
                    SalesOrderList.GotoRecord(SalesHeader);
                    SalesOrderList."Job Queue Status".Lookup();
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesCreditMemos.OpenView();
                    SalesCreditMemos.GotoRecord(SalesHeader);
                    SalesCreditMemos."Job Queue Status".Lookup();
                end;
            SalesHeader."Document Type"::"Return Order":
                begin
                    SalesReturnOrderList.OpenView();
                    SalesReturnOrderList.GotoRecord(SalesHeader);
                    SalesReturnOrderList."Job Queue Status".Lookup();
                end;
            else
                Error(UnsupportedDocTypeErr);
        end;
    end;

    local procedure InvokeJobStatusStateOnPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrderList: TestPage "Purchase Order List";
        PurchaseInvoices: TestPage "Purchase Invoices";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Invoice:
                begin
                    PurchaseInvoices.OpenView();
                    PurchaseInvoices.GotoRecord(PurchaseHeader);
                    PurchaseInvoices."Job Queue Status".Lookup();
                end;
            PurchaseHeader."Document Type"::Order:
                begin
                    PurchaseOrderList.OpenView();
                    PurchaseOrderList.GotoRecord(PurchaseHeader);
                    PurchaseOrderList."Job Queue Status".Lookup();
                end;
            PurchaseHeader."Document Type"::"Credit Memo":
                begin
                    PurchaseCreditMemos.OpenView();
                    PurchaseCreditMemos.GotoRecord(PurchaseHeader);
                    PurchaseCreditMemos."Job Queue Status".Lookup();
                end;
            PurchaseHeader."Document Type"::"Return Order":
                begin
                    PurchaseReturnOrderList.OpenView();
                    PurchaseReturnOrderList.GotoRecord(PurchaseHeader);
                    PurchaseReturnOrderList."Job Queue Status".Lookup();
                end;
            else
                Error(UnsupportedDocTypeErr);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Msg, 'Unexpected message popped up.');
    end;

    local procedure CreateJobQueueEntryWithStatus(var JobQueueEntry: Record "Job Queue Entry"; Status: Option; StatusMessage: Text)
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();

        JobQueueEntry.Status := Status;
        if Status = JobQueueEntry.Status::Error then
            JobQueueEntry."Error Message" := CopyStr(StatusMessage, 1, MaxStrLen(JobQueueEntry."Error Message"));

        JobQueueEntry.Insert();
    end;

    local procedure GetJobQueueEntryStatusFromDocJobQueueStatus(DocumentJobQueueStatus: Enum "Document Job Queue Status"): Integer
    var
        DummySalesHeader: Record "Sales Header";
        DummyJobQueueEntry: Record "Job Queue Entry";
    begin
        case DocumentJobQueueStatus of
            DummySalesHeader."Job Queue Status"::Error:
                exit(DummyJobQueueEntry.Status::Error);
            DummySalesHeader."Job Queue Status"::Posting:
                exit(DummyJobQueueEntry.Status::"In Process");
            DummySalesHeader."Job Queue Status"::"Scheduled for Posting":
                exit(DummyJobQueueEntry.Status::Ready);
        end;
    end;
}

