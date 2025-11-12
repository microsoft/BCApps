codeunit 132499 RunPerformanceTestPDF
{

    trigger OnRun()
    begin
    end;

    var
        fileName: Text[255];

    [Scope('OnPrem')]
    procedure DeleteFile(fileName: Text[255])
    begin
        if Erase(fileName) then;
    end;

    [Scope('OnPrem')]
    procedure GeneratePDFTestT02(): Text[255]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader.SetFilter("No.", '101005');
        SetPdfFileName();
        REPORT.SaveAsPdf(REPORT::"Standard Sales - Order Conf.", fileName, SalesHeader);
        exit(fileName);
    end;

    [Scope('OnPrem')]
    procedure GeneratePDFTestT03(): Text[255]
    begin
        SetPdfFileName();
        REPORT.SaveAsPdf(REPORT::"Trial Balance", fileName);
        exit(fileName);
    end;

    [Scope('OnPrem')]
    procedure GeneratePDFTestT04(): Text[255]
    var
        Statement: Report Statement;
        startDate: Date;
        endDate: Date;
    begin
        startDate := DMY2Date(12, 12, Date2DMY(Today, 3));
        endDate := DMY2Date(12, 12, Date2DMY(Today, 3) + 2);
        SetPdfFileName();
        Statement.InitializeRequest(false, false, true, false, false, false, '<1M+CM>', 0, true, startDate, endDate);
        Statement.SaveAsPdf(fileName);
        exit(fileName);
    end;

    [Scope('OnPrem')]
    procedure GeneratePDFTestT05(): Text[255]
    var
        InventoryValuation: Report "Inventory Valuation";
        parsedDate: Date;
    begin
        parsedDate := DMY2Date(1, 1, 2001);
        InventoryValuation.SetStartDate(parsedDate);
        parsedDate := DMY2Date(2, 2, 2001);
        InventoryValuation.SetEndDate(parsedDate);
        SetPdfFileName();
        InventoryValuation.SaveAsPdf(fileName);
        exit(fileName);
    end;

    [Scope('OnPrem')]
    procedure GeneratePDFTestT06(): Text[255]
    var
        customerRecord: Record Customer;
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
        periodLength: DateFormula;
        parsedDate: Date;
    begin
        parsedDate := DMY2Date(1, 7, 2005);
        Evaluate(periodLength, '<1M>');
        customerRecord.SetFilter("No.", '01445544..01905893');
        AgedAccountsReceivable.InitializeRequest(parsedDate, 0, periodLength, false, false, 0, false);
        AgedAccountsReceivable.SetTableView(customerRecord);
        SetPdfFileName();
        AgedAccountsReceivable.SaveAsPdf(fileName);
        exit(fileName);
    end;

    [Scope('OnPrem')]
    procedure GeneratePDFTestT07(): Text[255]
    var
        customerRecord: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
        parsedDate: Date;
    begin
        parsedDate := DMY2Date(22, 7, 2005);
        customerRecord.SetFilter("No.", '01121212');
        SetPdfFileName();
        CustomerBalanceToDate.InitializeRequest(false, false, false, parsedDate);
        CustomerBalanceToDate.SetTableView(customerRecord);
        CustomerBalanceToDate.SaveAsPdf(fileName);
        exit(fileName);
    end;

    [Scope('OnPrem')]
    procedure GeneratePDFTestT08(): Text[255]
    var
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        startDate: Date;
        endDate: Date;
        postingDate: Date;
    begin
        startDate := DMY2Date(1, 1, 2005);
        endDate := DMY2Date(31, 12, 2005);
        postingDate := DMY2Date(22, 7, 2005);
        CalcAndPostVATSettlement.InitializeRequest(startDate, endDate, postingDate, 'S-IN000000001', '2320', true, false);
        SetPdfFileName();
        CalcAndPostVATSettlement.SaveAsPdf(fileName);
        exit(fileName);
    end;

    [Scope('OnPrem')]
    procedure SetPdfFileName()
    begin
        fileName := TemporaryPath;
        fileName += '\';
        fileName += DelChr(Format(CreateGuid()), '=', '{-}');
        fileName += '.pdf';
    end;
}

