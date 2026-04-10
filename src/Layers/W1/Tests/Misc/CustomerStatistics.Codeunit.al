codeunit 134961 "Customer Statistics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure TestDistinctItemsSoldQuery()
    var
        Customer: Record Customer;
        DateFilterCalc: Codeunit "DateFilter-Calc";
        CurrentDate: Date;
        CustDateFilter: array[4] of Text[30];
        CustDateName: array[4] of Text[30];
        i: Integer;
    begin
        // init
        Initialize();

        // setup
        CurrentDate := WorkDate();
        DateFilterCalc.CreateAccountingPeriodFilter(CustDateFilter[1], CustDateName[1], CurrentDate, 0);
        DateFilterCalc.CreateFiscalYearFilter(CustDateFilter[2], CustDateName[2], CurrentDate, 0);
        DateFilterCalc.CreateFiscalYearFilter(CustDateFilter[3], CustDateName[3], CurrentDate, -1);

        // execute
        // verify
        Customer.FindSet();
        repeat
            for i := 1 to 4 do
                LibraryAssert.AreEqual(CalcNumberOfDistinctItemsSoldCode(Customer."No.", CustDateFilter[i]), CalcNumberOfDistinctItemsSoldQuery(Customer."No.", CustDateFilter[i]), 'Incorrect number of distinct items sold for customer ' + Customer."No.");
        until Customer.Next() = 0;
    end;

    local procedure CalcNumberOfDistinctItemsSoldQuery(CustomerNo: Code[20]; DateFilter: Text) Count: Integer
    var
        DistinctItemsSoldQuery: Query "Distinct Items Sold";
    begin
        DistinctItemsSoldQuery.SetFilter(PostingDateFilter, DateFilter);
        DistinctItemsSoldQuery.SetRange(CustomerNoFilter, CustomerNo);

        if DistinctItemsSoldQuery.Open() then
            while DistinctItemsSoldQuery.Read() do
                Count += 1;
    end;

    local procedure CalcNumberOfDistinctItemsSoldCode(CustomerNo: Code[20]; DateFilter: Text): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Items: Dictionary of [Code[20], Integer];
    begin
        ItemLedgerEntry.SetLoadFields("Item No.");
        ItemLedgerEntry.SetFilter("Posting Date", DateFilter);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Source Type", ItemLedgerEntry."Source Type"::Customer);
        ItemLedgerEntry.SetRange("Source No.", CustomerNo);
        if ItemLedgerEntry.FindSet() then
            repeat
                if not Items.ContainsKey(ItemLedgerEntry."Item No.") then
                    Items.Add(ItemLedgerEntry."Item No.", 1);
            until ItemLedgerEntry.Next() = 0;
        exit(Items.Count());
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;
}