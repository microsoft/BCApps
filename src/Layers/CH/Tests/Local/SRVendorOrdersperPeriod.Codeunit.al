codeunit 144037 "SR Vendor Orders per Period"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        NumberOfPurchaseOrders: Integer;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        NumberOfPurchaseOrders := 5;
    end;

    [Test]
    [HandlerFunctions('VendOrdersPerPeriodReportReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendOrdersPerPeriodReportStartDatePeriod()
    begin
        VendOrdersPerPeriodReportTest(false);
    end;

    [Test]
    [HandlerFunctions('VendOrdersPerPeriodReportReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendOrdersPerPeriodReportStartDatePeriodShowLCY()
    begin
        VendOrdersPerPeriodReportTest(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendOrdersPerPeriodReportReqPageHandler(var ReqPage: TestRequestPage "SR Vendor Orders per Period")
    var
        PeriodLength: Variant;
        ShowLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(ShowLCY);
        ReqPage."Period Length".SetValue(PeriodLength);
        ReqPage.ShowAmtInLCY.SetValue(ShowLCY);
        ReqPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VendOrdersPerPeriodReportTest(ShowAmtInLCY: Boolean)
    var
        Vendor: Record Vendor;
        ExpectedPurchAmtInOrderLCY: array[5] of Decimal;
        PeriodLength: DateFormula;
        PeriodLengthText: Text;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PeriodLengthText := '<1M>';
        CreatePurchaseOrders(Vendor, PeriodLengthText, ExpectedPurchAmtInOrderLCY);

        // Exercise.
        Evaluate(PeriodLength, PeriodLengthText);
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(ShowAmtInLCY);
        WorkDate := CalcDate(PeriodLength, WorkDate());
        Commit();
        Vendor.SetRange("No.", Vendor."No.");
        REPORT.Run(REPORT::"SR Vendor Orders per Period", true, false, Vendor);

        // Verify.
        VerifyReportData(Vendor, ShowAmtInLCY, ExpectedPurchAmtInOrderLCY);
    end;

    local procedure CreatePurchaseOrder(Vendor: Record Vendor; ReceiptDate: Date; var Amount: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");
        PurchHeader."Expected Receipt Date" := ReceiptDate;
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 10);
        Amount := PurchLine."Line Amount";
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchaseOrders(Vendor: Record Vendor; PeriodLength: Text; var ExpectedPurchAmtInOrderLCY: array[5] of Decimal)
    var
        ReceiptDate: Date;
        PeriodLengthDateFormula: DateFormula;
        Index: Integer;
    begin
        Evaluate(PeriodLengthDateFormula, PeriodLength);
        ReceiptDate := WorkDate();
        for Index := 1 to NumberOfPurchaseOrders do begin
            CreatePurchaseOrder(Vendor, ReceiptDate, ExpectedPurchAmtInOrderLCY[Index]);
            ReceiptDate := CalcDate(PeriodLengthDateFormula, ReceiptDate);
        end;
    end;

    local procedure VerifyReportData(Vendor: Record Vendor; ShowAmtInLCY: Boolean; ExpectedPurchAmtInOrderLCY: array[5] of Decimal)
    var
        Index: Integer;
        PurchAmtInOrderLCY: array[5] of Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(NumberOfPurchaseOrders, LibraryReportDataset.RowCount(), 'Wrong number of customer lines in the report.');

        for Index := 1 to NumberOfPurchaseOrders do begin
            LibraryReportDataset.GetNextRow();

            Clear(PurchAmtInOrderLCY);
            PurchAmtInOrderLCY[Index] := ExpectedPurchAmtInOrderLCY[Index];

            LibraryReportDataset.AssertCurrentRowValueEquals('PurchAmtInOrderLCY1', PurchAmtInOrderLCY[1]);
            LibraryReportDataset.AssertCurrentRowValueEquals('PurchAmtInOrderLCY2', PurchAmtInOrderLCY[2]);
            LibraryReportDataset.AssertCurrentRowValueEquals('PurchAmtInOrderLCY3', PurchAmtInOrderLCY[3]);
            LibraryReportDataset.AssertCurrentRowValueEquals('PurchAmtInOrderLCY4', PurchAmtInOrderLCY[4]);
            LibraryReportDataset.AssertCurrentRowValueEquals('PurchAmtInOrderLCY5', PurchAmtInOrderLCY[5]);
            LibraryReportDataset.AssertCurrentRowValueEquals('PurchOrderAmtLCY', PurchAmtInOrderLCY[Index]);
            LibraryReportDataset.AssertCurrentRowValueEquals('No_Vend', Vendor."No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('ShowAmtInLCY', ShowAmtInLCY);
        end;
    end;
}

