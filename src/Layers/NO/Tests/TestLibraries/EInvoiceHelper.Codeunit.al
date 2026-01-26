codeunit 143003 "E-Invoice Helper"
{

    trigger OnRun()
    begin
    end;

    var
        TempPredefinedCustomer: Record Customer temporary;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        TestValueTxt: Label 'Test Value';
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure ClearCustomer()
    begin
        TempPredefinedCustomer.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.GLN := TestValueTxt;
        Customer."Account Code" := TestValueTxt;

        if not TempPredefinedCustomer.IsEmpty() then begin
            Customer.Address := TempPredefinedCustomer.Address;
            Customer."Address 2" := TempPredefinedCustomer."Address 2";
            Customer.Validate("Country/Region Code", TempPredefinedCustomer."Country/Region Code");
            Customer.City := TempPredefinedCustomer.City;
            Customer."Post Code" := TempPredefinedCustomer."Post Code";
            Customer.Name := TempPredefinedCustomer.Name;
            Customer."Phone No." := TempPredefinedCustomer."Phone No.";
            Customer."Fax No." := TempPredefinedCustomer."Fax No.";
            Customer."E-Mail" := TempPredefinedCustomer."E-Mail";
            TempPredefinedCustomer."No." := Customer."No.";
            Customer."Currency Code" := TempPredefinedCustomer."Currency Code";
            Customer."VAT Registration No." := TempPredefinedCustomer."VAT Registration No.";
            Customer.Validate("E-Invoice", TempPredefinedCustomer."E-Invoice");
        end else begin
            Customer.Address := TestValueTxt;
            Customer."Address 2" := TestValueTxt;
            Customer.Validate("Country/Region Code", 'NO');
            Customer.City := TestValueTxt;
            Customer."Post Code" := TestValueTxt;
            Customer."VAT Registration No." := '123456785';
            Customer.Validate("E-Invoice", true);
        end;

        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeRate(StartingDate: Date): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.Validate(Code, CopyStr(LibraryUtility.GenerateGUID(), 8, 3)); // Currency code must be exactly 3 characters long.
        Currency.Insert(true);
        LibraryERM.CreateExchangeRate(Currency.Code, StartingDate, LibraryRandom.RandInt(1000), LibraryRandom.RandInt(1000));
        exit(Currency.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateItem(VATProdPostGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);

        Item.Description := TestValueTxt;
        Item.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);

        UnitOfMeasure.Get(Item."Sales Unit of Measure");
        UnitOfMeasure."International Standard Code" := DefaultUNECERec20Code();
        UnitOfMeasure.Modify(true);

        ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasure.Code);
        ItemUnitOfMeasure."Qty. per Unit of Measure" := LibraryRandom.RandInt(10);
        ItemUnitOfMeasure.Modify();

        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure DefaultUNECERec20Code(): Text[3]
    begin
        exit('NMP');
    end;

    [Scope('OnPrem')]
    procedure GetTempPath(): Text[250]
    begin
        exit(TemporaryPath);
    end;

    [Scope('OnPrem')]
    procedure InitExpectedCustomerInfo(var TempExpectedCustomerInfo: Record Customer temporary)
    begin
        TempExpectedCustomerInfo.Init();
        TempExpectedCustomerInfo.Address := 'Kanalvej 1';
        TempExpectedCustomerInfo."Address 2" := 'Kanalvej 42';
        TempExpectedCustomerInfo.City := 'Kongens Lyngby';
        TempExpectedCustomerInfo."Post Code" := 'DK-2800';
        TempExpectedCustomerInfo."Country/Region Code" := 'DK';
        TempExpectedCustomerInfo.Name := 'New Domicile';
        TempExpectedCustomerInfo."Phone No." := '45870000';
        TempExpectedCustomerInfo."Fax No." := '45870001';
        TempExpectedCustomerInfo."E-Mail" := 'mdcc@mdcc.dk';
        TempExpectedCustomerInfo."VAT Registration No." := '987654321';
        TempExpectedCustomerInfo."E-Invoice" := true;
    end;

    [Scope('OnPrem')]
    procedure SetCustomer(TempNewCustomer: Record Customer temporary)
    begin
        TempPredefinedCustomer.Init();
        TempPredefinedCustomer.TransferFields(TempNewCustomer);
        TempPredefinedCustomer.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure SetupEInvoiceForSales(Path: Text[250])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("E-Invoice Sales Invoice Path", Path);
        SalesReceivablesSetup.Validate("E-Invoice Sales Cr. Memo Path", Path);
        SalesReceivablesSetup.Validate("E-Invoice Reminder Path", Path);
        SalesReceivablesSetup.Validate("E-Invoice Fin. Charge Path", Path);
        SalesReceivablesSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure KIDSetup(NewKIDSetup: Option; DocNoLength: Integer; CustNoLength: Integer)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("KID Setup", NewKIDSetup);
        SalesReceivablesSetup."Document No. length" := DocNoLength;
        SalesReceivablesSetup."Customer No. length" := CustNoLength;
        SalesReceivablesSetup.Modify(true);
    end;
}

