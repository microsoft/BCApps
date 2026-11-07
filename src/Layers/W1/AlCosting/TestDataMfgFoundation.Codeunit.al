codeunit 103203 "Test Data - Mfg Foundation"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        SetPreconditions();
        CreateCustomers();
        CreateVendors();
        CreateLocations();
        CreateItems();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        INVTUtil: Codeunit INVTUtil;

    local procedure SetPreconditions()
    var
        NoSeries: Record "No. Series";
    begin
        // CODEUNIT.RUN(CODEUNIT::"Set Global Preconditions");
        SalesSetup.Get();
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup."Stockout Warning" := false;
        SalesSetup.Modify();

        PurchSetup.Get();
        PurchSetup."Ext. Doc. No. Mandatory" := false;
        PurchSetup.Modify();

        NoSeries.ModifyAll("Manual Nos.", true);
    end;

    [Scope('OnPrem')]
    procedure CreateItems()
    var
        Item: Record Item;
    begin
        CreateItem(Item, '1', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '2', 'BOX', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '3', 'PACK', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '4', 'KG', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '5', 'L', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '6', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '7', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '8', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '9', 'PCS', Item."Replenishment System"::Purchase, 'V-1');
        CreateItem(Item, '10', 'PCS', Item."Replenishment System"::Purchase, 'V-2');
        CreateItem(Item, '11', 'PCS', Item."Replenishment System"::Purchase, 'V-2');
        CreateItem(Item, '12', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '13', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '14', 'PCS', Item."Replenishment System"::Purchase, 'V-1');
        CreateItem(Item, '15', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '16', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '18', 'PCS', Item."Replenishment System"::Purchase, '');
        CreateItem(Item, '19', 'PCS', Item."Replenishment System"::Purchase, '');
        CreateItem(Item, '20', 'PCS', Item."Replenishment System"::Purchase, '');
        CreateItem(Item, '21', 'PCS', Item."Replenishment System"::"Prod. Order", 'V-1');
        CreateItem(Item, '22', 'PCS', Item."Replenishment System"::"Prod. Order", 'V-2');
        CreateItem(Item, '24', 'PCS', Item."Replenishment System"::Purchase, 'V-1');
        CreateItem(Item, '25', 'PCS', Item."Replenishment System"::Purchase, 'V-2');
        CreateItem(Item, '27', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '29', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '30', 'PCS', Item."Replenishment System"::Purchase, 'V-3');
        CreateItem(Item, '31', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '33', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '34', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, '36', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Modify(true);
        CreateItem(Item, '37', 'PCS', Item."Replenishment System"::Purchase, 'V-1');
        Item.Validate(Reserve, Item.Reserve::Optional);
        Item.Modify(true);
        CreateItem(Item, '38', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        CreateItem(Item, '47', 'PCS', Item."Replenishment System"::Purchase, 'V-3');
        CreateItem(Item, '48', 'PCS', Item."Replenishment System"::Purchase, 'V-3');
        CreateItem(Item, '53', 'PCS', Item."Replenishment System"::Purchase, 'V-1');
        CreateItem(Item, '54', 'PCS', Item."Replenishment System"::Purchase, 'V-1');
        CreateItem(Item, '55', 'PCS', Item."Replenishment System"::Purchase, 'V-3');
        CreateItem(Item, '56', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, 'B-1', 'PCS', Item."Replenishment System"::"Prod. Order", 'V-1');
        CreateItem(Item, 'B-2', 'PCS', Item."Replenishment System"::"Prod. Order", 'V-2');
        CreateItem(Item, 'B-3', 'PCS', Item."Replenishment System"::"Prod. Order", 'V-3');
        CreateItem(Item, 'B-4', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, 'B-5', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, 'B-44', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        CreateItem(Item, 'B-46', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Modify(true);
        CreateItem(Item, 'B-47', 'PCS', Item."Replenishment System"::Purchase, '');
        Item.Validate(Reserve, Item.Reserve::Optional);
        Item.Modify(true);
        CreateItem(Item, 'B-48', 'PCS', Item."Replenishment System"::"Prod. Order", '');
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        CreateItem(Item, '64', 'PCS', Item."Replenishment System"::Purchase, '');
    end;

    [Scope('OnPrem')]
    procedure CreateCustomers()
    var
        Cust: Record Customer;
    begin
        Cust.Validate("No.", 'C-1');
        Cust.Validate("Gen. Bus. Posting Group", 'NATIONAL');
        Cust.Validate("VAT Bus. Posting Group", 'NATIONAL');
        Cust.Validate("Customer Posting Group", 'DOMESTIC');
        Cust.Validate("Shipping Advice", Cust."Shipping Advice"::Partial);
        Cust.Validate("Shipment Method Code", 'EXW');
        Cust.Insert();
        Cust.Validate("No.", 'C-2');
        Cust.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateVendors()
    var
        Vend: Record Vendor;
    begin
        Vend.Validate("No.", 'V-1');
        Vend.Validate("Gen. Bus. Posting Group", 'NATIONAL');
        Vend.Validate("VAT Bus. Posting Group", 'NATIONAL');
        Vend.Validate("Vendor Posting Group", 'DOMESTIC');
        Vend.Insert();
        Vend.Validate("No.", 'V-2');
        Vend.Insert();
        Vend.Validate("No.", 'V-3');
        Vend.Insert();
        Vend.Validate("No.", 'V-4');
        Vend.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateItem(var Item: Record Item; ItemNo: Code[20]; BaseUOM: Code[20]; ReplenishmentSystem: Enum "Replenishment System"; VendorNo: Code[20])
    begin
        INVTUtil.InsertItem(Item, ItemNo);

        INVTUtil.InsertItemUOM(Item."No.", BaseUOM, 1);
        Item.Validate("Base Unit of Measure", BaseUOM);

        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("VAT Prod. Posting Group", 'VAT25');
        Item.Validate("Inventory Posting Group", 'FINISHED');

        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateLocations()
    var
        Loc: Record Location;
    begin
        Loc.Validate(Code, 'ORANGE');
        Loc.Insert(true);

        Loc.Validate(Code, 'GOLD');
        Loc.Insert(true);

        Loc.Validate(Code, 'TRANS');
        Loc.Validate("Use As In-Transit", true);
        Loc.Insert(true);
    end;
}

