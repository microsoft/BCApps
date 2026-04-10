codeunit 134112 "Test Sales Header Work Descr."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Quote] [Work Description]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyText()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Init
        SalesHeader.Init();

        // Execute + Verify
        Assert.AreEqual('', SalesHeader.GetWorkDescription(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOneLineText()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Text: Text;
    begin
        // Init
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        Text := 'Hello World!';

        // Execute
        SalesHeader.SetWorkDescription(Text);
        SalesHeader.Modify();
        SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No.");

        // Verify
        Assert.AreEqual(Text, SalesHeader2.GetWorkDescription(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleLinesText()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        BlobInStream: InStream;
        Text: Text;
        C: Text[1];
        i: Integer;
    begin
        // Init
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        C[1] := 10;
        Text := 'Hello World!';
        for i := 1 to 9 do
            Text += C + 'Hello World!';

        // Execute
        SalesHeader.SetWorkDescription(Text);
        SalesHeader.Modify();
        SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No.");
        TempBlob.FromRecord(SalesHeader2, SalesHeader2.FieldNo("Work Description"));
        // Verify
        TempBlob.CreateInStream(BlobInStream);
        for i := 1 to 10 do begin
            BlobInStream.ReadText(Text);
            Assert.AreEqual('Hello World!', Text, '');
        end;
        BlobInStream.ReadText(Text);
        Assert.AreEqual(Text, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEditInQuotePage()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        // Init
        LibrarySales.CreateCustomer(Customer);
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        Assert.AreEqual('', SalesQuote.WorkDescription.Value, '');

        // execute
        SalesQuote.WorkDescription.SetValue('Hello World!');
        SalesQuote.Close();
        Commit();
        SalesQuote.OpenView();
        SalesQuote.Last();

        // Verify
        Assert.AreEqual('Hello World!', SalesQuote.WorkDescription.Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEditInOrderPage()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        SalesOrderNo: Code[20];
        ExpectedResult: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 215434] Page Sales Order have to allow to edit field "Work Description" of Sales Order

        // [GIVEN] Page Sales Order with empty "Work Description"
        LibrarySales.CreateCustomer(Customer);
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
        SalesOrder.WorkDescription.AssertEquals('');

        // [WHEN] Set value of "Work Description" = 'Hello World!'
        ExpectedResult := LibraryUtility.GenerateGUID();
        SalesOrder.WorkDescription.SetValue(ExpectedResult);
        SalesOrderNo := SalesOrder."No.".Value();
        SalesOrder.Close();
        Commit();
        SalesOrder.OpenView();
        SalesOrder.GotoKey(SalesHeader."Document Type"::Order, SalesOrderNo);

        // [THEN] "Work Description" = 'Hello World!'
        SalesOrder.WorkDescription.AssertEquals(ExpectedResult);
    end;
}

