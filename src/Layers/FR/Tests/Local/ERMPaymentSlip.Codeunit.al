codeunit 144562 "ERM Payment Slip"
{
    // // [FEATURE] [Payment Slip]
    // 1.Check that programm populates correct value on payment header as on posted sales invoice through suggest customer payment report.
    // 
    // Bug = 324389
    // ----------------------------------------------------------------
    // Test Function Name
    // ----------------------------------------------------------------
    // CheckAmountLCYOnPaymentHeader

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        TransferTypeExportedErr: Label 'Wrong exported SEPA Transfer Type';
        TransferTypeTok: Label '"%1"';
        LibraryFRLocalization: Codeunit "Library - FR Localization";

    [Test]
    [HandlerFunctions('SuggestCustomerPaymentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckAmountLCYOnPaymentHeader()
    var
        PaymentClass: Record "Payment Class";
        SalesHeader: Record "Sales Header";
        PaymentHeader: Record "Payment Header";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SuggestCustomerPayments: Report "Suggest Customer Payments";
        LibraryERM: Codeunit "Library - ERM";
        PostedDocumentNo: Code[20];
    begin
        // Check that programm populates correct value on payment header as on posted sales invoice through suggest customer payment report.

        // Setup: Create payment slip setup & Create and post sales invoice.
        Initialize();
        CreatePaymentClass(PaymentClass);
        CreatePaymentStatus(PaymentClass.Code, true);
        CreateCustomerWithPaymentTermsCode(Customer);
        CreateSalesInvoice(SalesHeader, Customer."No.");
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreatePaymentHeader(PaymentHeader, PaymentClass.Code);
        LibraryVariableStorage.Enqueue(Customer."No.");
        SuggestCustomerPayments.SetGenPayLine(PaymentHeader);

        // Exercise: Run Suggest Customer Payments report.
        Commit();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, SalesHeader."Document Type"::Invoice, PostedDocumentNo);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Due Date");
        SuggestCustomerPayments.Run();

        // Verify: Verify Payment Header Amount LCY as on Posted Sales Invoice.
        VerifyAmountOnPaymentHeader(PostedDocumentNo, PaymentHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentClassExport()
    var
        PaymentClass: Record "Payment Class";
        StreamReader: DotNet StreamReader;
        Name: Text[50];
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 376206] Export Payment Class via XML Port "Import/Export Parameters"
        Name := LibraryUtility.GenerateGUID();

        // [GIVEN] Payment Class "A" with "SEPA Transfer Type" = "Credit Transfer"
        InitPaymentClassWithSEPATransferType(PaymentClass, PaymentClass."SEPA Transfer Type"::"Credit Transfer", Name);
        // [GIVEN] Payment Class "B" with "SEPA Transfer Type" = "Direct Debit"
        InitPaymentClassWithSEPATransferType(PaymentClass, PaymentClass."SEPA Transfer Type"::"Direct Debit", Name);

        // [WHEN] Export Payment Classes "A" and "B" via XML Port "Import/Export Parameters"
        PaymentClass.SetRange(Name, Name);
        StreamReader := StreamReader.StreamReader(ExportPaymentClass(PaymentClass));

        // [THEN] Exported Payment Class "A" line has "Credit Transfer" entry
        VerifyExportPaymentClassLine(StreamReader, Format(PaymentClass."SEPA Transfer Type"::"Credit Transfer"));

        // [THEN] Exported Payment Class "B" line has "Direct Debit" entry
        VerifyExportPaymentClassLine(StreamReader, Format(PaymentClass."SEPA Transfer Type"::"Direct Debit"));
    end;

    [Test]
    [HandlerFunctions('PaymentStepConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentInProgressIsTrueWhenStepNextStatusWithTrueValue()
    var
        PaymentHeader: Record "Payment Header";
        PaymentStep: Record "Payment Step";
        PaymentManagement: Codeunit "Payment Management";
        Status: array[2] of Integer;
    begin
        // [SCENARIO 381553] "Payment in Progress" = TRUE after step next status with "Payment in Progress" = TRUE, "Action Type" = "None"
        Initialize();

        // [GIVEN] Payment class with two status: "S1" with "Payment in Progress" = FALSE, "S2" with "Payment in Progress" = TRUE
        // [GIVEN] Payment step: "Previous Status" = "S1", "Next Status" = "S2", "Action Type" := "None"
        CreatePaymentClassWithTwoStatus(PaymentStep, Status, false, true);
        // [GIVEN] Payment with "Status No." = "S1"
        CreatePaymentHeaderWithLine(PaymentHeader, PaymentStep."Payment Class");

        // [WHEN] Process payment's next step.
        PaymentManagement.ProcessPaymentSteps(PaymentHeader, PaymentStep);

        // [THEN] Payment Line's "Status No." = "S2", "Payment in Progress" = TRUE
        VerifyPaymentLine(PaymentHeader."No.", Status[2], true);
    end;

    [Test]
    [HandlerFunctions('PaymentStepConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentInProgressIsFalseWhenStepNextStatusWithFalseValue()
    var
        PaymentHeader: Record "Payment Header";
        PaymentStep: Record "Payment Step";
        PaymentManagement: Codeunit "Payment Management";
        Status: array[2] of Integer;
    begin
        // [SCENARIO 381553] "Payment in Progress" = FALSE after step next status with "Payment in Progress" = FALSE, "Action Type" = "None"
        Initialize();

        // [GIVEN] Payment class with two status: "S1" with "Payment in Progress" = TRUE, "S2" with "Payment in Progress" = FALSE
        // [GIVEN] Payment step: "Previous Status" = "S1", "Next Status" = "S2", "Action Type" := "None"
        CreatePaymentClassWithTwoStatus(PaymentStep, Status, true, false);
        // [GIVEN] Payment with "Status No." = "S1"
        CreatePaymentHeaderWithLine(PaymentHeader, PaymentStep."Payment Class");

        // [WHEN] Process payment's next step.
        PaymentManagement.ProcessPaymentSteps(PaymentHeader, PaymentStep);

        // [THEN] Payment Line's "Status No." = "S2", "Payment in Progress" = FALSE
        VerifyPaymentLine(PaymentHeader."No.", Status[2], false);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePaymentClassWithTwoStatus(var PaymentStep: Record "Payment Step"; var Status: array[2] of Integer; PaymentInProgress1: Boolean; PaymentInProgress2: Boolean)
    var
        PaymentClass: Record "Payment Class";
    begin
        CreatePaymentClass(PaymentClass);
        Status[1] := CreatePaymentStatus(PaymentClass.Code, PaymentInProgress1);
        Status[2] := CreatePaymentStatus(PaymentClass.Code, PaymentInProgress2);
        CreatePaymentStep(PaymentStep, PaymentClass.Code, Status[1], Status[2]);
    end;

    local procedure CreateCustomerWithPaymentTermsCode(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePaymentClass(var PaymentClass: Record "Payment Class")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryFRLocalization.CreatePaymentClass(PaymentClass);
        PaymentClass.Validate(Suggestions, PaymentClass.Suggestions::Customer);
        PaymentClass.Validate("Header No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        PaymentClass.Modify(true);
    end;

    local procedure CreatePaymentHeaderWithLine(var PaymentHeader: Record "Payment Header"; PaymentClassCode: Text[30])
    var
        PaymentLine: Record "Payment Line";
    begin
        CreatePaymentHeader(PaymentHeader, PaymentClassCode);
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");
    end;

    local procedure CreatePaymentHeader(var PaymentHeader: Record "Payment Header"; PaymentClassCode: Text[30])
    begin
        InitPaymentHeader(PaymentHeader);
        PaymentHeader.Validate("Payment Class", PaymentClassCode);
        PaymentHeader.Validate("Posting Date", CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), WorkDate()));
        PaymentHeader.Validate("Document Date", CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), WorkDate()));
        PaymentHeader.Modify(true);
    end;

    local procedure CreatePaymentStatus(PaymentClassCode: Text[30]; NewPaymentInProgress: Boolean): Integer
    var
        PaymentStatus: Record "Payment Status";
    begin
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClassCode);
        PaymentStatus.Validate(RIB, true);
        PaymentStatus.Validate(Debit, true);
        PaymentStatus.Validate(Credit, true);
        PaymentStatus.Validate("Bank Account", true);
        PaymentStatus.Validate("Payment in Progress", NewPaymentInProgress);
        PaymentStatus.Modify(true);
        exit(PaymentStatus.Line);
    end;

    local procedure CreatePaymentStep(var PaymentStep: Record "Payment Step"; PaymentClassCode: Text[30]; PreviousStatus: Integer; NextStatus: Integer)
    begin
        LibraryFRLocalization.CreatePaymentStep(PaymentStep, PaymentClassCode);
        PaymentStep.Validate("Previous Status", PreviousStatus);
        PaymentStep.Validate("Next Status", NextStatus);
        PaymentStep.Validate("Action Type", PaymentStep."Action Type"::None);
        PaymentStep.Modify(true);
    end;

    local procedure ExportPaymentClass(var PaymentClass: Record "Payment Class"): Text
    var
        FileMgt: Codeunit "File Management";
        ServerFile: File;
        Fileoutstream: OutStream;
        ServerFileName: Text;
    begin
        ServerFileName := FileMgt.ServerTempFileName('');
        ServerFile.Create(ServerFileName);
        ServerFile.CreateOutStream(Fileoutstream);
        XMLPORT.Export(XMLPORT::"Import/Export Parameters", Fileoutstream, PaymentClass);
        ServerFile.Close();
        exit(ServerFileName);
    end;

    local procedure InitPaymentClassWithSEPATransferType(var PaymentClass: Record "Payment Class"; SEPATransferType: Option; Name: Text[50])
    begin
        LibraryFRLocalization.CreatePaymentClass(PaymentClass);
        PaymentClass.Name := Name;
        PaymentClass."SEPA Transfer Type" := SEPATransferType;
        PaymentClass.Modify();
    end;

    local procedure InitPaymentHeader(var PaymentHeader: Record "Payment Header")
    begin
        PaymentHeader.Init();
        PaymentHeader.Validate(
          "No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(PaymentHeader.FieldNo("No."), DATABASE::"Payment Header"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Payment Header", PaymentHeader.FieldNo("No."))));
        PaymentHeader.Insert(true);
    end;

    local procedure VerifyAmountOnPaymentHeader(DocumentNo: Code[20]; PaymentHeaderCode: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentHeader: Record "Payment Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        PaymentHeader.Get(PaymentHeaderCode);
        PaymentHeader.CalcFields("Amount (LCY)");
        PaymentHeader.TestField("Amount (LCY)", -1 * SalesInvoiceHeader."Amount Including VAT");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestCustomerPaymentRequestPageHandler(var SuggestCustomerPayments: TestRequestPage "Suggest Customer Payments")
    var
        CustomerNo: Variant;
        DueDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        LibraryVariableStorage.Dequeue(DueDate);
        SuggestCustomerPayments.LastPaymentDate.SetValue(DueDate);
        SuggestCustomerPayments.Customer.SetFilter("No.", CustomerNo);
        SuggestCustomerPayments.OK().Invoke();
    end;

    local procedure VerifyExportPaymentClassLine(StreamReader: DotNet StreamReader; SEPATransferType: Text)
    var
        DotNetString: DotNet String;
        LinePart: Text[1024];
    begin
        DotNetString := StreamReader.ReadLine();
        Assert.AreEqual(7, StrLen(DelChr(DotNetString, '=', DelChr(DotNetString, '=', ','))), '');
        LinePart := DotNetString.Substring(DotNetString.LastIndexOf(',') + 1);
        Assert.AreEqual(StrSubstNo(TransferTypeTok, SEPATransferType), LinePart, TransferTypeExportedErr);
    end;

    local procedure VerifyPaymentLine(PaymentHeaderNo: Code[20]; ExpectedStatusNo: Integer; ExpectedPaymentInProgress: Boolean)
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.SetRange("No.", PaymentHeaderNo);
        PaymentLine.FindFirst();
        Assert.AreEqual(ExpectedStatusNo, PaymentLine."Status No.", PaymentLine.FieldCaption("Status No."));
        Assert.AreEqual(ExpectedPaymentInProgress, PaymentLine."Payment in Progress", PaymentLine.FieldCaption("Payment in Progress"));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PaymentStepConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

