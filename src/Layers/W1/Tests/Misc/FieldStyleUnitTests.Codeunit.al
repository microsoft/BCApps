codeunit 134062 "Field Style Unit Tests"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SetStyle] [UT]
    end;

    var
        Assert: Codeunit Assert;
        IncorrectStyle: Label 'Style is not correct.';
        Unfavorable: Label 'Unfavorable';
        Attention: Label 'Attention';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure DefaultStyleOnCustomerLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreateCustomerLedgerEntry(CustLedgerEntry, false, LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate())), '<-1D>');
        Assert.IsTrue('' = CustLedgerEntry.SetStyle(), IncorrectStyle);

        CustLedgerEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnfavorableStyleOnCustomerLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreateCustomerLedgerEntry(CustLedgerEntry, true, LibraryUtility.GenerateRandomDate(CalcDate('<-1Y>', WorkDate()), WorkDate()), '');
        Assert.IsTrue(Unfavorable = CustLedgerEntry.SetStyle(), IncorrectStyle);

        CustLedgerEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttentionStyleOnCustomerLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreateCustomerLedgerEntry(CustLedgerEntry, false, LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate())), '<1D>');
        Assert.IsTrue(Attention = CustLedgerEntry.SetStyle(), IncorrectStyle);

        CustLedgerEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultStyleOnVendorLEdgerEntry()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreateVendorLedgerEntry(VendorLedgerEntry, false, LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate())), '<-1D>');
        Assert.IsTrue('' = VendorLedgerEntry.SetStyle(), IncorrectStyle);

        VendorLedgerEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnfavorableStyleOnVendorLEdgerEntry()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreateVendorLedgerEntry(VendorLedgerEntry, true, LibraryUtility.GenerateRandomDate(CalcDate('<-1Y>', WorkDate()), WorkDate()), '');
        Assert.IsTrue(Unfavorable = VendorLedgerEntry.SetStyle(), IncorrectStyle);

        VendorLedgerEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttentionStyleOnVendorLEdgerEntry()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreateVendorLedgerEntry(VendorLedgerEntry, false, LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate())), '<1D>');
        Assert.IsTrue(Attention = VendorLedgerEntry.SetStyle(), IncorrectStyle);

        VendorLedgerEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultStyleOnCustomer()
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer, 0);
        Assert.IsTrue('' = Customer.SetStyle(), IncorrectStyle);

        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnfavorableStyleOnCustomer()
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer, -LibraryRandom.RandDec(10, 2));
        Assert.IsTrue(Unfavorable = Customer.SetStyle(), IncorrectStyle);

        Customer.Delete();
    end;

    local procedure CreateCustomer(var Customer: Record Customer; CreditLimitLCY: Decimal)
    begin
        Customer.Init();
        Customer."Credit Limit (LCY)" := CreditLimitLCY;
        Customer.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; Open: Boolean; DueDate: Date; ClosedAtDateDelta: Text)
    var
        DateFormula: DateFormula;
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry.Open := Open;
        CustLedgerEntry."Due Date" := DueDate;
        if not Open then begin
            Evaluate(DateFormula, ClosedAtDateDelta);
            CustLedgerEntry."Closed at Date" := CalcDate(DateFormula, CustLedgerEntry."Due Date");
        end;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Open: Boolean; DueDate: Date; ClosedAtDateDelta: Text)
    var
        DateFormula: DateFormula;
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry.Open := Open;
        VendorLedgerEntry."Due Date" := DueDate;
        if not Open then begin
            Evaluate(DateFormula, ClosedAtDateDelta);
            VendorLedgerEntry."Closed at Date" := CalcDate(DateFormula, VendorLedgerEntry."Due Date");
        end;
        VendorLedgerEntry.Insert();
    end;
}

