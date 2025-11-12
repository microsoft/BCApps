codeunit 118801 "Create Catalog Item"
{

    trigger OnRun()
    begin
        if DemoDataSetup.Get() then;

        PurchasingCodes.DeleteAll();
        InsertPurchasingData(XCALLIN, Xthisordermustbecalledin, false, false);
        InsertPurchasingData(XDROPSHIP, Xcallinandsendtocustomer, true, false);
        InsertPurchasingData(XSPECORDER, Xcallinandsendtous, false, true);

        Manuf.DeleteAll();
        InsertManufData(Xlamna, XLamnaHealthcareCompany);
        InsertManufData(Xwingtiplc, "X​WingtipToys");
        InsertManufData(XNorthwindlc, XNorthwindTraders);
        InsertManufData(Xfirst, "X​FirstUpConsultants");
        InsertManufData(Xprosewarelc, XProsewareInc);
        InsertManufData(Xfabrik, XFabrikamResidences);

        NonStock.DeleteAll();
        InsertNonStockData('', '10000', '2100', XStraightbackchair, XPCS, 12, 10, 22, 5, 5, '1111X2222');
        InsertNonStockData('', '10000', '2200', XRockingchair, XPCS, 15, 13, 26, 6, 6, '3333Z4444');
        InsertNonStockData('', '30000', '3100', XComputerdesk, XPCS, 120, 105, 230, 50, 50, '31331T5444');
        InsertNonStockData('', '40000', '4100', XConferencetable, XPCS, 100, 90, 180, 35, 35, '999999T8888');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        PurchasingCodes: Record Purchasing;
        Manuf: Record Manufacturer;
        NonStock: Record "Nonstock Item";
        XCALLIN: Label 'CALL IN';
        Xthisordermustbecalledin: Label 'This order must be called in';
        XDROPSHIP: Label 'DROP SHIP';
        Xcallinandsendtocustomer: Label 'Call in and send to customer';
        XSPECORDER: Label 'SPEC ORDER';
        Xcallinandsendtous: Label 'Call in and send to us';
        Xlamna: Label 'Lamna';
        XLamnaHealthcareCompany: Label 'Lamna Healthcare Company';
        Xwingtiplc: Label 'wingtip';
        "X​WingtipToys": Label '​Wingtip Toys';
        XNorthwindlc: Label 'Northwind';
        XNorthwindTraders: Label 'Northwind Traders';
        Xfirst: Label 'first';
        "X​FirstUpConsultants": Label '​First Up Consultants';
        Xprosewarelc: Label 'proseware';
        XProsewareInc: Label 'Proseware, Inc.';
        Xfabrik: Label 'fabrik';
        XFabrikamResidences: Label 'Fabrikam Residences';
        XStraightbackchair: Label 'Straight back chair';
        XPCS: Label 'PCS';
        XRockingchair: Label 'Rocking chair';
        XComputerdesk: Label 'Computer desk';
        XConferencetable: Label 'Conference table';

    procedure InsertPurchasingData("Code": Code[10]; Description: Text[30]; "Drop Ship": Boolean; "Special Order": Boolean)
    begin
        PurchasingCodes.Init();
        PurchasingCodes.Validate(Code, Code);
        PurchasingCodes.Validate(Description, Description);
        PurchasingCodes.Validate("Drop Shipment", "Drop Ship");
        PurchasingCodes.Validate("Special Order", "Special Order");
        PurchasingCodes.Insert();
    end;

    procedure InsertManufData("Code": Code[10]; Name: Text[50])
    begin
        Manuf.Init();
        Manuf.Validate(Code, Code);
        Manuf.Validate(Name, Name);
        Manuf.Insert();
    end;

    procedure InsertNonStockData("Mfr. Code": Code[5]; "Vendor No.": Code[20]; "Vendor Item No.": Code[20]; Description: Text[30]; UOM: Text[10]; "Published Cost": Decimal; "Negotiated Cost": Decimal; "Unit Price": Decimal; "Gross Weight": Decimal; "Net Weight": Decimal; "Bar Code": Code[20])
    begin
        NonStock.Init();
        NonStock.Validate("Entry No.", '');
        NonStock.Validate("Manufacturer Code", "Mfr. Code");
        NonStock.Validate("Vendor No.", "Vendor No.");
        NonStock.Validate("Vendor Item No.", "Vendor Item No.");
        NonStock.Validate(Description, Description);
        NonStock.Validate("Unit of Measure", UOM);
        NonStock.Validate("Published Cost", "Published Cost");
        NonStock.Validate("Negotiated Cost", "Negotiated Cost");
        NonStock.Validate("Unit Price", "Unit Price");
        NonStock.Validate("Gross Weight", "Gross Weight");
        NonStock.Validate("Net Weight", "Net Weight");
        NonStock.Validate("Bar Code", "Bar Code");
        NonStock.Insert(true);
    end;
}

