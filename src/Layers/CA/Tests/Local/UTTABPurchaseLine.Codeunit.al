codeunit 144051 "UT TAB Purchase Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Purchase] [Purchase Line]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateLocationCodeVendtaxAreaCodePurchLine()
    var
        PurchaseLine: Record "Purchase Line";
        TaxArea: Record "Tax Area";
        Vendor: Record Vendor;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Purpose of the test is to validate Trigger OnValidate of Location Code for Table 39 - Purchase Line.

        // Setup.
        UpdatePurchasePayablesSetup();
        CreateVendor(Vendor, CreateTaxArea(TaxArea."Country/Region"::CA, false));
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", '', Vendor."Tax Area Code");
        RecRef.GetTable(PurchaseLine);
        FieldRef := RecRef.Field(PurchaseLine.FieldNo(PurchaseLine."Location Code"));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(PurchaseLine);
        PurchaseLine.TestField("Tax Area Code", Vendor."Tax Area Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateLocCodeWithoutLocAndBusiPresPurchLine()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Location Code without location and Business Presence on Vendor Location is False and without location for Table 39 - Purchase Line.
        OnValidateLocCodeVendorLocPurchLine('', CreateTaxArea(TaxArea."Country/Region"::CA, false), CreateTaxArea(TaxArea."Country/Region"::CA, false));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateLocCodeWithLocAndWithoutBusiPresPurchLine()
    var
        Location: Record Location;
        TaxArea: Record "Tax Area";
        TaxAreaCode: Code[20];
    begin
        // Purpose of the test is to validate Trigger OnValidate of Location Code with location and Business Presence on Vendor Location is false for Table 39 - Purchase Line.
        TaxAreaCode := CreateTaxArea(TaxArea."Country/Region"::CA, false);
        OnValidateLocCodeVendorLocPurchLine(CreateLocation(Location, CreateTaxArea(TaxArea."Country/Region"::CA, false)), TaxAreaCode, TaxAreaCode);
    end;

    local procedure OnValidateLocCodeVendorLocPurchLine(LocationCode: Code[10]; HeaderTaxAreaCode: Code[20]; VendorLocTaxAreaCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup.
        CreateVendor(Vendor, '');
        CreateVendorLocation(Vendor."No.", false, VendorLocTaxAreaCode);
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", LocationCode, HeaderTaxAreaCode);
        RecRef.GetTable(PurchaseLine);
        FieldRef := RecRef.Field(PurchaseLine.FieldNo(PurchaseLine."Location Code"));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(PurchaseLine);
        PurchaseLine.TestField("Tax Area Code", VendorLocTaxAreaCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateLocCodeWithoutLocAndWithBusiPresPurchLine()
    var
        TaxArea: Record "Tax Area";
        TaxAreaCode: Code[20];
    begin
        // Purpose of the test is to validate Trigger OnValidate of Location Code without location and Business Presence on Vendor Location is True for Table 39 - Purchase Line.
        TaxAreaCode := CreateTaxArea(TaxArea."Country/Region"::CA, false);
        OnValidateLocCodeBusPreTruePurchLine('', TaxAreaCode, TaxAreaCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateLocCodeWithLocAndWithBusiPresPurchLine()
    var
        Location: Record Location;
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Location Code with location and Business Presence on Vendor Location is True for Table 39 - Purchase Line.
        CreateLocation(Location, CreateTaxArea(TaxArea."Country/Region"::CA, false));
        OnValidateLocCodeBusPreTruePurchLine(Location.Code, Location."Tax Area Code", Location."Tax Area Code");
    end;

    local procedure OnValidateLocCodeBusPreTruePurchLine(LocationCode: Code[10]; HeaderTaxAreaCode: Code[20]; LineTaxAreaCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        TaxArea: Record "Tax Area";
        Vendor: Record Vendor;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup.
        CreateVendor(Vendor, '');
        CreateVendorLocation(Vendor."No.", true, CreateTaxArea(TaxArea."Country/Region"::CA, false));
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", LocationCode, HeaderTaxAreaCode);
        RecRef.GetTable(PurchaseLine);
        FieldRef := RecRef.Field(PurchaseLine.FieldNo(PurchaseLine."Location Code"));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(PurchaseLine);
        PurchaseLine.TestField("Tax Area Code", LineTaxAreaCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateTaxAreaCodeTaxAreaCountryPurchaseLine()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Tax Area Code with Tax Area Country for Table 39 - Purchase Line.
        OnValidateTaxAreaCodePurchaseLine(CreateTaxArea(TaxArea."Country/Region"::CA, false), CreateTaxArea(TaxArea."Country/Region"::US, false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateTaxAreaCodeUseExternalTaxEnginePurchaseLine()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Tax Area Code with Use External Tax Engine as true for Table 39 - Purchase Line.
        OnValidateTaxAreaCodePurchaseLine(CreateTaxArea(TaxArea."Country/Region"::CA, true), CreateTaxArea(TaxArea."Country/Region"::CA, false));
    end;

    local procedure OnValidateTaxAreaCodePurchaseLine(HeaderTaxAreaCode: Code[20]; LineTaxAreaCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup.
        CreateVendor(Vendor, '');
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", '', HeaderTaxAreaCode);
        PurchaseLine."Tax Area Code" := LineTaxAreaCode;
        RecRef.GetTable(PurchaseLine);
        FieldRef := RecRef.Field(PurchaseLine.FieldNo(PurchaseLine."Tax Area Code"));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        asserterror FieldRef.Validate();

        // Verify.
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; LocationCode: Code[10]; TaxAreaCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := VendorNo;
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader."Pay-to Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        PurchaseHeader."Location Code" := LocationCode;
        PurchaseHeader.Insert();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Buy-from Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        PurchaseLine."Pay-to Vendor No." := PurchaseHeader."Pay-to Vendor No.";
        PurchaseLine."Line No." := LibraryRandom.RandInt(10);
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := CreateItem();
        PurchaseLine.Insert();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateLocation(var Location: Record Location; TaxAreaCode: Code[20]): Code[10]
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location."Tax Area Code" := TaxAreaCode;
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure CreateTaxArea(Country: Option; UseExternalTaxEngine: Boolean): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea."Country/Region" := Country;
        TaxArea."Use External Tax Engine" := UseExternalTaxEngine;
        TaxArea.Insert();
        exit(TaxArea.Code);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; TaxAreaCode: Code[20])
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Pay-to Vendor No." := Vendor."No.";
        Vendor."Tax Area Code" := TaxAreaCode;
        Vendor.Insert();
    end;

    local procedure CreateVendorLocation(VendorNo: Code[20]; BusinessPresence: Boolean; AltTaxAreaCode: Code[20]): Code[20]
    var
        VendorLocation: Record "Vendor Location";
    begin
        VendorLocation."Vendor No." := VendorNo;
        VendorLocation."Location Code" := '';
        VendorLocation."Business Presence" := BusinessPresence;
        VendorLocation."Alt. Tax Area Code" := AltTaxAreaCode;
        VendorLocation.Insert();
        exit(VendorLocation."Alt. Tax Area Code");
    end;

    local procedure UpdatePurchasePayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup."Use Vendor's Tax Area Code" := true;
        PurchasesPayablesSetup.Modify();
    end;
}

