codeunit 134565 "Recurring Sales Line Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAutomaticRecurringSalesLines()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        TaxAreaCode: Code[20];
        StandardSalesCode: Code[10];
    begin
        // [SCENARIO] When automatic sales recurring lines are enabled no error is thrown when running the OnInsert trigger in the table "Sales Header"
        // bug 360031

        // [WHEN] all the tables are configured for automatic sales recurring lines
        TaxAreaCode := 'TestTaxArea';
        StandardSalesCode := 'TestCode';

        LibrarySales.CreateCustomer(Customer);
        InitializeStandardCustomerSalesCode(Customer, StandardSalesCode);
        InitializeStandardSalesCode(StandardSalesCode);
        InitializeStandardSalesLine(StandardSalesCode);
        InitializeTaxArea(TaxAreaCode);

        // [WHEN] The OnInsert trigger in the table "Sales Header" is executed
        InsertRowInSalesHeaderWithTriggerOnInsertEnabled(Customer, TaxAreaCode);

        // [THEN] No error is thrown
    end;

    local procedure InitializeStandardCustomerSalesCode(Customer: Record Customer; StandardSalesCode: Code[10])
    var
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
    begin
        StandardCustomerSalesCode.DeleteAll();
        StandardCustomerSalesCode."Customer No." := Customer."No.";
        StandardCustomerSalesCode.Code := StandardSalesCode;
        StandardCustomerSalesCode."Currency Code" := '';
        StandardCustomerSalesCode."Insert Rec. Lines On Quotes" := StandardCustomerSalesCode."Insert Rec. Lines On Quotes"::Automatic;
        StandardCustomerSalesCode.Insert();
    end;

    local procedure InitializeStandardSalesCode(StandardSalesCode: Code[10])
    var
        StdSalesCode: Record "Standard Sales Code";
    begin
        StdSalesCode.DeleteAll();
        StdSalesCode.Code := StandardSalesCode;
        StdSalesCode.Insert();
    end;

    local procedure InitializeStandardSalesLine(StandardSalesCode: Code[10])
    var
        StdSalesLine: Record "Standard Sales Line";
        LibraryInventory: Codeunit "Library - Inventory";
        ItemNo: Code[20];
    begin
        ItemNo := LibraryInventory.CreateItemNo();
        StdSalesLine.DeleteAll();
        StdSalesLine."Standard Sales Code" := StandardSalesCode;
        StdSalesLine."Line No." := 1;
        StdSalesLine.Type := StdSalesLine.Type::Item;
        StdSalesLine.Quantity := 1;
        StdSalesLine."No." := ItemNo;
        StdSalesLine.Insert();
    end;

    local procedure InitializeTaxArea(TaxAreaCode: Code[20])
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.DeleteAll();
        TaxArea.Code := TaxAreaCode;
        TaxArea."Use External Tax Engine" := false;
        TaxArea.Insert();
    end;

    local procedure InsertRowInSalesHeaderWithTriggerOnInsertEnabled(Customer: Record Customer; TaxAreaCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader."No." := 'TestOrder1';
        SalesHeader."Sell-to Customer No." := Customer."No.";
        SalesHeader."Salesperson Code" := Customer."Salesperson Code";
        SalesHeader."Currency Code" := '';
        SalesHeader."Bill-to Customer No." := Customer."No.";
        SalesHeader."Tax Liable" := true;
        SalesHeader."Tax Area Code" := TaxAreaCode;

        SalesHeader.Insert(true);
    end;
}