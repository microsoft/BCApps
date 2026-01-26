codeunit 142072 "UT COD Order Entry"
{
    Permissions = TableData "Sales Shipment Header" = rimd,
                  TableData "Sales Shipment Line" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [HandlerFunctions('BOMOptionDialogHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunSalesExplodeBOM()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose is to test Codeunit 63 Sales-Explode BOM On Run trigger.

        // Setup: Create SalesOrder
        Initialize();
        CreateSalesOrderForExplodeBom(SalesLine);

        // EXERCISE.
        CODEUNIT.Run(CODEUNIT::"Sales-Explode BOM", SalesLine);

        // Verify: Sales Line No. after Explode BOM.
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.FindFirst();
        SalesLine.TestField("No.", SalesLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunSalesQuoteToOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose is to test Codeunit 86 Sales-Quote to Order On Run trigger.
        LibraryLowerPermissions.SetOutsideO365Scope();
        // Setup: Create Sales Quote.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote, CreateParentItem());
        Commit();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // Verify. Package Tracking No. after editing Sales Shipment Line.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Quote No.", SalesHeader."No.");
        SalesHeader.FindFirst();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunShipmentLineEdit()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Purpose is to test Codeunit 10001 Shipment Line - Edit On Run trigger.

        // Setup: Create Sales Shipment Document.
        Initialize();
        CreateSalesShipmentDocument(SalesShipmentLine);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Shipment Line - Edit", SalesShipmentLine);

        // Verify. Package Tracking No. after editing Sales Shipment Line.
        SalesShipmentLine.TestField("Package Tracking No.", SalesShipmentLine."Package Tracking No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunSalesPostError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate On Hold field in On Run Trigger of Codeunit -80 Sales-Post.
        // Setup: Create Sales Order.
        Initialize();
        CreateSalesOrderWithOnHold(SalesHeader);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify: Verify Actual Error - On Hold must be equal to ''.
        Assert.ExpectedErrorCode('TestField');
    end;

    local procedure Initialize()
    begin
        CreateBlankVATPostingSetup();
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateBlankVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.DeleteAll();
        if not VATPostingSetup.Get('', '') then
            VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := '';
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Sales Tax";
        VATPostingSetup.Insert();
    end;

    local procedure CreateComponentItem(): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        GenProductPostingGroup.FindFirst();
        InventoryPostingGroup.FindFirst();
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;  // HardCode value required for Sales-Explode BOM Codeunit.
        Item."Inventory Posting Group" := InventoryPostingGroup.Code;  // HardCode value required for Sales-Explode BOM Codeunit.
        Item."Replenishment System" := Item."Replenishment System"::Purchase;
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateParentItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Assembly BOM" := true;
        Item."Replenishment System" := Item."Replenishment System"::Assembly;
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateSalesOrderForExplodeBom(var SalesLine: Record "Sales Line")
    var
        BomComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
    begin
        BomComponent."Parent Item No." := CreateParentItem();
        BomComponent."Line No." := LibraryRandom.RandInt(100);
        BomComponent.Type := BomComponent.Type::Item;
        BomComponent."No." := CreateComponentItem();
        BomComponent."Quantity per" := LibraryRandom.RandInt(5);
        BomComponent."Assembly BOM" := false;
        BomComponent."Resource Usage Type" := BomComponent."Resource Usage Type"::Direct;
        BomComponent.Insert();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, BomComponent."Parent Item No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure CreateSalesOrderWithOnHold(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesHeader."On Hold" := CopyStr(LibraryUTUtility.GetNewCode10(), 1, 2);  // Upto 3 characters mandatory in this field.
        SalesHeader.Insert();
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; No: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := CreateCustomer();
        SalesHeader."Bill-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader.Insert();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryRandom.RandInt(100);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := No;
        SalesLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesLine.Reserve := SalesLine.Reserve::Always;
        SalesLine.Insert();
    end;

    local procedure CreateSalesShipmentDocument(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
        SalesShipmentLine."Document No." := LibraryUTUtility.GetNewCode();
        SalesShipmentLine."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesShipmentLine."Package Tracking No." := LibraryUTUtility.GetNewCode();
        SalesShipmentLine.Insert();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure BOMOptionDialogHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the option of the string menu.
        Choice := 1;  // Choose option. Retrieve dimensions from components.
    end;
}

