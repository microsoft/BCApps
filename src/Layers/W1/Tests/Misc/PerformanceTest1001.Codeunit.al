codeunit 132498 PerformanceTest1001
{

    trigger OnRun()
    begin
    end;

    var
        PriceAlreadyCalculatedErr: Label 'The price is already calculated for %1.', Comment = '.';

    [Scope('OnPrem')]
    procedure RunReport1001()
    var
        InventoryValuation: Report "Inventory Valuation";
        parsedDate: Date;
    begin
        parsedDate := DMY2Date(1, 1, 2001);
        InventoryValuation.SetStartDate(parsedDate);
        parsedDate := DMY2Date(2, 2, 2001);
        InventoryValuation.SetEndDate(parsedDate);
        InventoryValuation.Run();
    end;

    [Scope('OnPrem')]
    procedure RunReport120()
    var
        customerRecord: Record Customer;
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
        parsedDate: Date;
        periodLength: DateFormula;
    begin
        parsedDate := DMY2Date(1, 7, 2005);
        Evaluate(periodLength, '<1M>');
        customerRecord.SetFilter("No.", '01445544..01905893');
        AgedAccountsReceivable.InitializeRequest(parsedDate, 0, periodLength, false, false, 0, false);
        AgedAccountsReceivable.SetTableView(customerRecord);
        AgedAccountsReceivable.Run();
    end;

    [Scope('OnPrem')]
    procedure RunReport116()
    var
        Statement: Report Statement;
        parsedDate: Date;
    begin
        parsedDate := DMY2Date(12, 12, 2012);
        Statement.InitializeRequest(false, false, true, false, false, false, '<1M+CM>', 0, true, parsedDate, parsedDate);
        Statement.Run();
    end;

    [Scope('OnPrem')]
    procedure RunReport121()
    var
        customerRecord: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
        parsedDate: Date;
    begin
        parsedDate := DMY2Date(22, 7, 2005);
        customerRecord.SetFilter("No.", '01121212');
        CustomerBalanceToDate.InitializeRequest(false, false, false, parsedDate);
        CustomerBalanceToDate.SetTableView(customerRecord);
        CustomerBalanceToDate.Run();
    end;

    [Scope('OnPrem')]
    procedure RunReport20()
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
        CalcAndPostVATSettlement.Run();
    end;

    [Scope('OnPrem')]
    procedure ValidateCostAdjustPriceAbility()
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.SetFilter("Item No.", '1000|80100|70000');
        AvgCostAdjmtEntryPoint.Find('-');
        repeat
            if AvgCostAdjmtEntryPoint."Cost Is Adjusted" then
                Error(PriceAlreadyCalculatedErr, AvgCostAdjmtEntryPoint."Item No.");
        until AvgCostAdjmtEntryPoint.Next() = 0;
    end;
}

