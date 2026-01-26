codeunit 144560 "UT Split VAT"
{
    // // [FEATURE] [Split VAT] [UT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        IncorrectLineNoTxt: Label 'Incorrect implementation of IncrementLineNo.';
        LibraryInventory: Codeunit "Library - Inventory";
        MessageContainsErr: Label 'AssertMessageContains failed. Message: %1. Substring: %2.', Comment = '%1=Message,%2=Substring';
        MessageDoesntContainFailedErr: Label 'AssertMessageDoesNotContain failed. Message: %1. Substring: %2.', Comment = '%1=Message,%2=Substring';
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySplitVAT: Codeunit "Library - Split VAT";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderComposeUserMessage()
    var
        SalesHeader: Record "Sales Header";
    begin
        AssertMessageContains('Automatically generated split VAT lines will be removed.', SalesHeader.ComposeUserMessage(true, 'Type'));
        AssertMessageDoesNotContain(
          'Automatically generated split VAT lines will be removed.', SalesHeader.ComposeUserMessage(false, 'Type'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderIncrementLineNo()
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.AreEqual(10000, SalesHeader.IncrementLineNo(0), IncorrectLineNoTxt);
        Assert.AreEqual(100000, SalesHeader.IncrementLineNo(90000), IncorrectLineNoTxt);
        Assert.AreEqual(10001, SalesHeader.IncrementLineNo(1), IncorrectLineNoTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderGetHighestLineNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        MockSalesHeader(SalesHeader);
        MockSalesLine(SalesLine, SalesHeader, 555);
        MockSalesLine(SalesLine, SalesHeader, 1);

        // Execute and verify
        Assert.AreEqual(555, SalesHeader.GetHighestLineNo(SalesLine), 'Incorrect line number');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderGetVATPostingSetup()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SplitVATPostingSetup: Record "VAT Posting Setup";
        ResultVATPostingSetup: Record "VAT Posting Setup";
    begin
        // Setup
        LibrarySplitVAT.CreateVATPostingSetupForSplitVAT(VATPostingSetup, SplitVATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";

        // Execute
        SalesHeader.GetVATPostingSetup(ResultVATPostingSetup, SalesLine);

        // Verify
        Assert.AreEqual(
          SplitVATPostingSetup."VAT Bus. Posting Group", ResultVATPostingSetup."VAT Bus. Posting Group", 'Error in GetVATPostingSetup');
        Assert.AreEqual(
          SplitVATPostingSetup."VAT Prod. Posting Group", ResultVATPostingSetup."VAT Prod. Posting Group", 'Error in GetVATPostingSetup');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderInitLine()
    var
        SplitVATSalesHeader: Record "Sales Header";
        SplitVATSalesLine: Record "Sales Line";
        TotalingSalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LineNo: Integer;
    begin
        // Setup
        CreateSalesInvoice(SplitVATSalesHeader);
        LibrarySplitVAT.FindSalesLine(SplitVATSalesLine, SplitVATSalesHeader, false);
        LineNo := 1050;
        SplitVATSalesHeader.GetVATPostingSetup(VATPostingSetup, SplitVATSalesLine);

        // Execute
        SplitVATSalesHeader.InitializeTotalingSalesLine(SplitVATSalesLine, TotalingSalesLine, LineNo);
        // Verify
        Assert.IsTrue(TotalingSalesLine."Automatically Generated", TotalingSalesLine.FieldCaption("Automatically Generated"));
        Assert.AreEqual(SplitVATSalesLine.Type::"G/L Account", TotalingSalesLine.Type, TotalingSalesLine.FieldCaption(Type));
        Assert.AreEqual(SplitVATSalesLine."Document Type", TotalingSalesLine."Document Type", TotalingSalesLine.FieldCaption("Document Type"));
        Assert.AreEqual(SplitVATSalesLine."Document No.", TotalingSalesLine."Document No.", TotalingSalesLine.FieldCaption("Document No."));
        Assert.AreEqual(
          SplitVATSalesLine."Sell-to Customer No.", TotalingSalesLine."Sell-to Customer No.", TotalingSalesLine.FieldCaption("Sell-to Customer No."));
        Assert.AreEqual(-1, TotalingSalesLine.Quantity, TotalingSalesLine.FieldCaption(Quantity));
        Assert.AreEqual(LineNo, TotalingSalesLine."Line No.", TotalingSalesLine.FieldCaption("Line No."));
        Assert.AreEqual(VATPostingSetup."Sales VAT Account", TotalingSalesLine."No.", TotalingSalesLine.FieldCaption("No."));
        Assert.AreEqual(
          VATPostingSetup."VAT Prod. Posting Group", TotalingSalesLine."VAT Prod. Posting Group", TotalingSalesLine.FieldCaption("VAT Prod. Posting Group"));
        Assert.AreEqual(
          VATPostingSetup."VAT Bus. Posting Group", TotalingSalesLine."VAT Bus. Posting Group", TotalingSalesLine.FieldCaption("VAT Bus. Posting Group"));
        Assert.AreEqual(VATPostingSetup."VAT Calculation Type", TotalingSalesLine."VAT Calculation Type", TotalingSalesLine.FieldCaption("VAT Calculation Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderUpdateLine()
    var
        SalesLine: Record "Sales Line";
        TotalingSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        LibrarySales.CreateSalesLine(
          TotalingSalesLine, SalesHeader, TotalingSalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        SalesLine."Amount Including VAT" := 1100;
        SalesLine.Amount := 1000;

        SalesHeader.UpdateTotalingSalesLine(SalesLine, TotalingSalesLine);
        Assert.AreEqual(100, TotalingSalesLine."Unit Price", 'Incorrect Unit Price');

        SalesHeader.UpdateTotalingSalesLine(SalesLine, TotalingSalesLine);
        Assert.AreEqual(200, TotalingSalesLine."Unit Price", 'Incorrect Unit Price');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderComposeUserMessage()
    var
        ServiceHeader: Record "Service Header";
    begin
        AssertMessageContains('Automatically generated split VAT lines will be removed.', ServiceHeader.ComposeUserMessage(true, 'Type'));
        AssertMessageDoesNotContain(
          'Automatically generated split VAT lines will be removed.', ServiceHeader.ComposeUserMessage(false, 'Type'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderIncrementLineNo()
    var
        ServiceHeader: Record "Service Header";
    begin
        Assert.AreEqual(10000, ServiceHeader.IncrementLineNo(0), IncorrectLineNoTxt);
        Assert.AreEqual(100000, ServiceHeader.IncrementLineNo(90000), IncorrectLineNoTxt);
        Assert.AreEqual(10001, ServiceHeader.IncrementLineNo(1), IncorrectLineNoTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderLinesExist()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::Invoice);

        // Execute and verify
        Assert.IsTrue(ServiceHeader.ServiceLinesExist(), 'Incorrect implementation of ServiceHeader.ServiceLinesExist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderLinesDoNotExist()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup
        MockServiceHeader(ServiceHeader);

        // Execute and verify
        Assert.IsFalse(ServiceHeader.ServiceLinesExist(), 'Incorrect implementation of ServiceHeader.ServiceLinesExist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderGetHighestLineNoSequence()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        MockServiceHeader(ServiceHeader);
        MockServiceLine(ServiceLine, ServiceHeader, 1);
        MockServiceLine(ServiceLine, ServiceHeader, 3);
        MockServiceLine(ServiceLine, ServiceHeader, 5);

        // Execute and verify
        Assert.AreEqual(5, ServiceHeader.GetHighestLineNo(ServiceLine), 'Incorrect line number');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderGetHighestLineNoMisc()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        MockServiceHeader(ServiceHeader);
        MockServiceLine(ServiceLine, ServiceHeader, 100000);
        MockServiceLine(ServiceLine, ServiceHeader, 30000);
        MockServiceLine(ServiceLine, ServiceHeader, 50000);

        // Execute and verify
        Assert.AreEqual(100000, ServiceHeader.GetHighestLineNo(ServiceLine), 'Incorrect line number');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderGetHighestLineNoZeroLines()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Init();
        Assert.AreEqual(0, ServiceHeader.GetHighestLineNo(ServiceLine), 'Incorrect line number');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderGetVATPostingSetup()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SplitVATPostingSetup: Record "VAT Posting Setup";
        ResultVATPostingSetup: Record "VAT Posting Setup";
    begin
        // Setup
        LibrarySplitVAT.CreateVATPostingSetupForSplitVAT(VATPostingSetup, SplitVATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        ServiceLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        ServiceLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";

        // Execute
        ServiceHeader.GetVATPostingSetup(ResultVATPostingSetup, ServiceLine);

        // Verify
        Assert.AreEqual(
          SplitVATPostingSetup."VAT Bus. Posting Group", ResultVATPostingSetup."VAT Bus. Posting Group", 'Error in GetVATPostingSetup');
        Assert.AreEqual(
          SplitVATPostingSetup."VAT Prod. Posting Group", ResultVATPostingSetup."VAT Prod. Posting Group", 'Error in GetVATPostingSetup');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceInvoiceHeaderInitLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TotalingServiceLine: Record "Service Line";
        SplitVATPostingSetup: Record "VAT Posting Setup";
        LineNo: Integer;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 376310] Split VAT Service Line is correctly initialized after run TAB5900 "Service Header".InitializeTotalingServiceLine() for Service Invoice Header

        // [GIVEN] Service Invoice with Split VAT setup
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibrarySplitVAT.FindServiceLine(ServiceLine, ServiceHeader, false);
        LineNo := 1050;
        ServiceHeader.GetVATPostingSetup(SplitVATPostingSetup, ServiceLine);

        // [WHEN] Run TAB5900 "Service Header".InitializeTotalingServiceLine()
        ServiceHeader.InitializeTotalingServiceLine(ServiceLine, TotalingServiceLine, LineNo);

        // [THEN] Split VAT Service Line is correctly initialized
        VerifyTotalingServiceLine(TotalingServiceLine, ServiceLine, SplitVATPostingSetup, LineNo, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceCreditMemoHeaderInitLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TotalingServiceLine: Record "Service Line";
        SplitVATPostingSetup: Record "VAT Posting Setup";
        LineNo: Integer;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 376310] Split VAT Service Line is correctly initialized after run TAB5900 "Service Header".InitializeTotalingServiceLine() for Service Credit Memo Header

        // [GIVEN] Service Credit Memo with Split VAT setup
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        LibrarySplitVAT.FindServiceLine(ServiceLine, ServiceHeader, false);
        LineNo := 1050;

        // [WHEN] Run TAB5900 "Service Header".InitializeTotalingServiceLine()
        ServiceHeader.GetVATPostingSetup(SplitVATPostingSetup, ServiceLine);

        // Execute
        ServiceHeader.InitializeTotalingServiceLine(ServiceLine, TotalingServiceLine, LineNo);

        // [THEN] Split VAT Service Line is correctly initialized
        VerifyTotalingServiceLine(TotalingServiceLine, ServiceLine, SplitVATPostingSetup, LineNo, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderUpdateLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TotalingServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        LibraryService.CreateServiceLine(TotalingServiceLine, ServiceHeader, TotalingServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        ServiceLine."Amount Including VAT" := 1200;
        ServiceLine.Amount := 1000;

        ServiceHeader.UpdateTotalingServiceLine(ServiceLine, TotalingServiceLine);
        Assert.AreEqual(200, TotalingServiceLine."Unit Price", 'Incorrect Unit Price');

        ServiceHeader.UpdateTotalingServiceLine(ServiceLine, TotalingServiceLine);
        Assert.AreEqual(400, TotalingServiceLine."Unit Price", 'Incorrect Unit Price');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddSplitVATLineWithFullVATWithEmptySalesLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 376113] Split VAT line should not be created for Service Line when type is empty

        // [GIVEN] Service Invoice with Service Line in Split VAT Posting Setup
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::Invoice);

        // [GIVEN] new Service Line with Type = empty
        ServiceLine.Init();
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine.Insert(true);

        // [WHEN] Split Service line
        ServiceHeader.AddSplitVATLines();

        // [THEN] Total count of Service Lines is equal to 3 (2 initial lines and one split line)
        ServiceLine.Reset();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        Assert.RecordCount(ServiceLine, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SalesInvoiceGenerateSplitVATLinesVATCalculationShouldRoundCorrectly()
    var
        SplitVATSalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        TotalVATAmount: Decimal;
    begin
        // [SCENARIO 561618] VAT calculation rounding error on a sales invoice involving split VAT lines in Italian Localization
        // [GIVEN] Sales Invoice with multiple G/L lines
        TotalVATAmount := CreateSalesInvoiceWithMultipleGLLines(SplitVATSalesHeader, LibraryRandom.RandDecInDecimalRange(28.85, 28.85, 0), LibraryRandom.RandIntInRange(20, 20));

        // [WHEN] Invoice Generate Split VAT Lines action
        SalesInvoice.OpenEdit();
        SalesInvoice.GoToRecord(SplitVATSalesHeader);
        SalesInvoice.GenerateSplitVATLines.Invoke();

        // [THEN] Total VAT amount is equal to the Unit Price of the last Sales Line
        SalesInvoice.SalesLines.Last();
        SalesInvoice.SalesLines."Unit Price".AssertEquals(TotalVATAmount);
        SalesInvoice.Close();
    end;

    local procedure AssertMessageContains(ExpectedSubstring: Text; ActualMessage: Text)
    begin
        if StrPos(ActualMessage, ExpectedSubstring) = 0 then
            Error(MessageContainsErr, ActualMessage, ExpectedSubstring);
    end;

    local procedure AssertMessageDoesNotContain(ExpectedSubstring: Text; ActualMessage: Text)
    begin
        if StrPos(ActualMessage, ExpectedSubstring) <> 0 then
            Error(MessageDoesntContainFailedErr, ActualMessage, ExpectedSubstring);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SplitVATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySplitVAT.CreateVATPostingSetupForSplitVAT(VATPostingSetup, SplitVATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        LibrarySplitVAT.CreateSalesDoc(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::Invoice);
    end;

    local procedure CreateServiceDoc(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SplitVATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySplitVAT.CreateVATPostingSetupForSplitVAT(VATPostingSetup, SplitVATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        LibrarySplitVAT.CreateServiceDoc(ServiceHeader, VATPostingSetup, DocumentType);
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineNo: Integer)
    begin
        // Create Service Line.
        Clear(SalesLine);
        SalesLine.Reset();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");

        // Use the function GetLastLineNo to get the value of the Line No. field.
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);
    end;

    local procedure MockServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; LineNo: Integer)
    begin
        // Create Service Line.
        Clear(ServiceLine);
        ServiceLine.Reset();
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");

        // Use the function GetLastLineNo to get the value of the Line No. field.
        ServiceLine."Line No." := LineNo;
        ServiceLine.Insert(true);
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Insert(true);
    end;

    local procedure MockServiceHeader(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.Insert(true);
    end;

    local procedure VerifyTotalingServiceLine(TotalingServiceLine: Record "Service Line"; SplitVATServiceLine: Record "Service Line"; SplitVATPostingSetup: Record "VAT Posting Setup"; ExpectedLineNo: Integer; ExpectedQtyToShip: Decimal)
    begin
        Assert.IsTrue(TotalingServiceLine."Automatically Generated", TotalingServiceLine.FieldCaption("Automatically Generated"));
        Assert.AreEqual(SplitVATServiceLine.Type::"G/L Account", TotalingServiceLine.Type, TotalingServiceLine.FieldCaption(Type));
        Assert.AreEqual(SplitVATServiceLine."Document Type", TotalingServiceLine."Document Type", TotalingServiceLine.FieldCaption("Document Type"));
        Assert.AreEqual(SplitVATServiceLine."Document No.", TotalingServiceLine."Document No.", TotalingServiceLine.FieldCaption("Document No."));
        Assert.AreEqual(SplitVATServiceLine."Customer No.", TotalingServiceLine."Customer No.", TotalingServiceLine.FieldCaption("Customer No."));
        Assert.AreEqual(-1, TotalingServiceLine.Quantity, TotalingServiceLine.FieldCaption(Quantity));
        Assert.AreEqual(ExpectedQtyToShip, TotalingServiceLine."Qty. to Ship", TotalingServiceLine.FieldCaption("Qty. to Ship"));
        Assert.AreEqual(ExpectedLineNo, TotalingServiceLine."Line No.", TotalingServiceLine.FieldCaption("Line No."));
        Assert.AreEqual(SplitVATPostingSetup."Sales VAT Account", TotalingServiceLine."No.", TotalingServiceLine.FieldCaption("No."));
        Assert.AreEqual(
          SplitVATPostingSetup."VAT Prod. Posting Group", TotalingServiceLine."VAT Prod. Posting Group", TotalingServiceLine.FieldCaption("VAT Prod. Posting Group"));
        Assert.AreEqual(
          SplitVATPostingSetup."VAT Bus. Posting Group", TotalingServiceLine."VAT Bus. Posting Group", TotalingServiceLine.FieldCaption("VAT Bus. Posting Group"));
        Assert.AreEqual(SplitVATPostingSetup."VAT Calculation Type", TotalingServiceLine."VAT Calculation Type", TotalingServiceLine.FieldCaption("VAT Calculation Type"))
    end;

    local procedure CreateSalesInvoiceWithMultipleGLLines(var SalesHeader: Record "Sales Header"; UnitPrice: Decimal; NoOfSalesLine: Integer) TotalVATAmount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SplitVATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        i: Integer;
    begin
        LibrarySplitVAT.CreateVATPostingSetupForSplitVAT(VATPostingSetup, SplitVATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        LibrarySplitVAT.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, VATPostingSetup."VAT Bus. Posting Group");

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        for i := 1 to NoOfSalesLine do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandIntInRange(1, 1));
            SalesLine.Validate("Unit Price", UnitPrice);
            SalesLine.Modify(true);
            TotalVATAmount += SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

