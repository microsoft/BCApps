codeunit 144062 "Cust. Due Amt. w diff. Curr."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        TotalAmountErr: Label 'Total LCY amount is incorrect';

    [Test]
    [HandlerFunctions('ReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustDueAmountWithDiffLedgEntriesAndCurrTest()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        Currency1: Code[10];
        Currency2: Code[10];
        ItemNo: Code[20];
        Quantity: array[5] of Integer;
        UnitPrice: array[5] of Decimal;
        ColumnDate: array[5] of Date;
        "Count": Integer;
    begin
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        // Create Customer
        LibrarySales.CreateCustomer(Customer);

        // Create different Posting Dates for the 5 different columns in the Report
        ColumnDate[1] := CalcDate('<-4M>', WorkDate());
        ColumnDate[2] := CalcDate('<-2M>', WorkDate());
        ColumnDate[3] := CalcDate('<-1M>', WorkDate());
        ColumnDate[4] := WorkDate();
        ColumnDate[5] := CalcDate('<+2M>', WorkDate());

        // Create Currencies with Exchange Rates
        Currency1 := CreateCurrency(ColumnDate[1]);
        Currency2 := CreateCurrency(ColumnDate[1]);

        // Create Item
        ItemNo := LibraryInventory.CreateItem(Item);

        // Create Entries for each column in the Report
        for Count := 1 to 5 do begin
            UnitPrice[Count] := LibraryRandom.RandDec(10000, 2);
            Quantity[Count] := LibraryRandom.RandInt(10);

            // Create + Post 3 Sales Invoices
            CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, Customer."No.",
              ColumnDate[Count], ItemNo, '', Quantity[Count], UnitPrice[Count]);
            CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, Customer."No.",
              ColumnDate[Count], ItemNo, Currency1, Quantity[Count], UnitPrice[Count]);
            CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, Customer."No.",
              ColumnDate[Count], ItemNo, Currency2, Quantity[Count], UnitPrice[Count]);

            // Create + Post2 Credit Memos
            CreateAndPostSalesDocument(SalesHeader."Document Type"::"Credit Memo", Customer."No.",
              ColumnDate[Count], ItemNo, Currency1, Quantity[Count], UnitPrice[Count] / 2);
            CreateAndPostSalesDocument(SalesHeader."Document Type"::"Credit Memo", Customer."No.",
              ColumnDate[Count], ItemNo, Currency2, Quantity[Count], UnitPrice[Count] / 2);
        end;

        // Run Report 11537
        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"SR Cust. Due Amount per Period", true, false, Customer);

        // Verify Report
        VerifySalesDocumentReportData(Customer."No.", ColumnDate);
    end;

    local procedure CreateCurrency(StartingDate: Date): Code[10]
    var
        ExchangeRate: Decimal;
        CurrencyCode: Code[10];
    begin
        ExchangeRate := LibraryRandom.RandDec(9, 4);
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        LibraryERM.CreateExchangeRate(CurrencyCode, StartingDate, ExchangeRate, ExchangeRate);
        exit(CurrencyCode);
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PostingDate: Date; ItemNo: Code[20]; CurrencyCode: Code[10]; Quantity: Integer; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify();

        CreateSalesLine(SalesHeader, ItemNo, Quantity, UnitPrice);

        LibrarySales.PostSalesDocument(SalesHeader, false, false);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportRequestPageHandler(var SRCustDueAmountperPeriod: TestRequestPage "SR Cust. Due Amount per Period")
    begin
        SRCustDueAmountperPeriod.KeyDate.SetValue(WorkDate());
        SRCustDueAmountperPeriod.PeriodLength.SetValue('<1M>');
        SRCustDueAmountperPeriod.Layout.SetValue(0);
        SRCustDueAmountperPeriod.ShowAmtInLCY.SetValue(false);

        SRCustDueAmountperPeriod.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VerifySalesDocumentReportData(CustomerNo: Code[20]; PostingDate: array[5] of Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TotalAmountLCY: array[5] of Decimal;
        AllTotalAmountLCY: Decimal;
        "Count": Integer;
    begin
        // Verify the XML
        LibraryReportDataset.LoadDataSetFile();

        AllTotalAmountLCY := 0;
        for Count := 1 to 5 do begin
            Clear(DetailedCustLedgEntry);
            DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
            DetailedCustLedgEntry.SetRange("Posting Date", PostingDate[Count]);

            TotalAmountLCY[Count] := 0;
            if DetailedCustLedgEntry.FindSet() then
                repeat
                    TotalAmountLCY[Count] += DetailedCustLedgEntry."Amount (LCY)";
                until DetailedCustLedgEntry.Next() = 0;

            // Verify Total for each column
            Assert.AreEqual(LibraryReportDataset.Sum('CustBalanceDueLCY' + Format(Count)), TotalAmountLCY[Count], TotalAmountErr);

            AllTotalAmountLCY += TotalAmountLCY[Count];
        end;

        // Verify Total for all Balances
        Assert.AreEqual(LibraryReportDataset.Sum('TotalCustBalanceLCY_Integer'), AllTotalAmountLCY, TotalAmountErr);
    end;
}

