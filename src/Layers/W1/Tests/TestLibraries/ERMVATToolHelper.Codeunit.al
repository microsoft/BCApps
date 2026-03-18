codeunit 131334 "ERM VAT Tool - Helper"
{
    // Feature:  VAT Rate Change
    // Contains helper functions for codeunits in this area.


    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        ConversionErrorCount: Label 'Wrong number of records with expected posting groups: %1.';
        ConversionErrorCompare: Label 'Wrong data was converted.';
        ConversionErrorUpdate: Label 'Data in document lines was not properly updated.';
        ConversionErrorUnexpected: Label 'There should be no records with new posting groups: %1.';
        ItemChargeErrorCount: Label 'The number of Item Charge Assignments is incorrect.';
        ItemChargeErrorQty: Label 'Qty. to Assign is incorrect.';
        LinesWereNotSplitted: Label 'The lines were splitted incorrectly.';
        LogEntryErrorCount: Label 'Wrong number of records in Log Entry.';
        LogEntryErrorContent: Label 'The content of Log Entry is incorrect for field %1.';
        LogEntryErrorNoEntry: Label 'There is no correct Log Entry for %1.';
        NoTablesDefinedForConversion: Label 'Defined tables for conversion do not exist.';
        NotInitializedError: Label 'The tool was not initialized.';
        LogEntryContentErr: Label 'There is nothing to convert. The outstanding quantity is zero.';

    [Scope('OnPrem')]
    procedure AddReservationLinesForSales(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                LibrarySales.AutoReserveSalesLine(SalesLine);
            until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ApplyFilters(var RecRef: RecordRef; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20]): Boolean
    var
        VATProdGroupFieldNo: Integer;
        GenProdGroupFieldNo: Integer;
    begin
        RecRef.Reset();

        case RecRef.Number of
            DATABASE::"Finance Charge Memo Line",
            DATABASE::"Gen. Product Posting Group",
            DATABASE::"Reminder Line":
                begin
                    VATProdGroupFieldNo := GetVATProdPostingGroupFldId(RecRef.Number);
                    SetFilter(RecRef, VATProdGroupFieldNo, VATProdPostingGroup);
                end;
            DATABASE::"Job Journal Line",
            99000758, // DATABASE::"Machine Center"
            DATABASE::"Requisition Line",
            DATABASE::"Res. Journal Line",
            DATABASE::"Standard Item Journal Line",
            99000754, // DATABASE::"Work Center"
            5405, // DATABASE::"Production Order"
            DATABASE::"Serv. Price Adjustment Detail":
                begin
                    GenProdGroupFieldNo := GetGenProdPostingGroupFldId(RecRef.Number);
                    SetFilter(RecRef, GenProdGroupFieldNo, GenProdPostingGroup);
                end;
            DATABASE::"G/L Account",
            DATABASE::"Gen. Jnl. Allocation",
            DATABASE::"Gen. Journal Line",
            DATABASE::Item,
            DATABASE::"Item Charge",
            DATABASE::"Purchase Line",
            DATABASE::Resource,
            DATABASE::"Sales Line",
            DATABASE::"Service Line",
            DATABASE::"Standard General Journal Line":
                begin
                    VATProdGroupFieldNo := GetVATProdPostingGroupFldId(RecRef.Number);
                    GenProdGroupFieldNo := GetGenProdPostingGroupFldId(RecRef.Number);
                    SetFilters(RecRef, VATProdGroupFieldNo, VATProdPostingGroup, GenProdGroupFieldNo, GenProdPostingGroup);
                end;
        end;

        exit(RecRef.FindSet());
    end;

    local procedure BlockItems()
    var
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        BlockItemsWithPostingGroups(VATProdPostingGroup, GenProdPostingGroup);
        GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::Item);
        BlockItemsWithPostingGroups(VATProdPostingGroup, GenProdPostingGroup);
    end;

    local procedure BlockItemsWithPostingGroups(VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetFilter("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.SetFilter("Gen. Prod. Posting Group", GenProdPostingGroup);
        if Item.FindSet() then
            repeat
                Item.Validate(Blocked, true);
                Item.Modify(true);
            until Item.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CopyRecordRef(FromRecRef: RecordRef; ToRecRef: RecordRef)
    var
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        I: Integer;
    begin
        ToRecRef.Init();
        for I := 1 to FromRecRef.FieldCount do begin
            FromFieldRef := FromRecRef.FieldIndex(I);
            if FromFieldRef.Class = FieldClass::Normal then begin
                ToFieldRef := ToRecRef.FieldIndex(I);
                ToFieldRef.Value := FromFieldRef.Value();
            end;
        end;
        ToRecRef.Insert(false);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        FinChargeTerms: Record "Finance Charge Terms";
        ReminderTerms: Record "Reminder Terms";
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        FinChargeTerms.FindFirst();
        ReminderTerms.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GetGenBusPostingGroupFromSetup(GenProdPostingGroup));
        Customer.Validate("VAT Bus. Posting Group", GetVATBusPostingGroupFromSetup(VATProdPostingGroup));
        Customer.Validate("Fin. Charge Terms Code", FinChargeTerms.Code);
        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateNewLineRef(var TempRecRef: RecordRef; Qty: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        VATRateChangeConversion: Codeunit "VAT Rate Change Conversion";
        ServVATRateChangeConv: Codeunit "Serv. VAT Rate Change Conv.";
        FieldRef: FieldRef;
        LineNo: Integer;
        NextLineNo: Integer;
    begin
        case TempRecRef.Number of
            DATABASE::"Purchase Line":
                begin
                    TempRecRef.SetTable(PurchaseLine);
                    LineNo := PurchaseLine."Line No.";
                    TempRecRef := TempRecRef.Duplicate();
                    FieldRef := TempRecRef.Field(PurchaseLine.FieldNo("Line No."));
                    VATRateChangeConversion.GetNextPurchaseLineNo(PurchaseLine, NextLineNo);
                    FieldRef.Value(NextLineNo);
                    TempRecRef.Insert(false);
                    FieldRef := TempRecRef.Field(PurchaseLine.FieldNo(Quantity));
                    FieldRef.Validate(Qty);
                    FieldRef := TempRecRef.Field(PurchaseLine.FieldNo("Description 2"));
                    FieldRef.Validate(Format(NextLineNo)); // Value is used later.
                    TempRecRef.Modify(true);
                    if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Blanket Order" then
                        UpdateLineRefWithBlOrdLineNo(TempRecRef, LineNo, NextLineNo);
                end;
            DATABASE::"Sales Line":
                begin
                    TempRecRef.SetTable(SalesLine);
                    LineNo := SalesLine."Line No.";
                    TempRecRef := TempRecRef.Duplicate();
                    FieldRef := TempRecRef.Field(SalesLine.FieldNo("Line No."));
                    VATRateChangeConversion.GetNextSalesLineNo(SalesLine, NextLineNo);
                    FieldRef.Value(NextLineNo);
                    TempRecRef.Insert(false);
                    FieldRef := TempRecRef.Field(SalesLine.FieldNo(Quantity));
                    FieldRef.Validate(Qty);
                    FieldRef := TempRecRef.Field(SalesLine.FieldNo("Description 2"));
                    FieldRef.Validate(Format(NextLineNo)); // Value is used later.
                    TempRecRef.Modify(true);
                    if SalesLine."Document Type" = SalesLine."Document Type"::"Blanket Order" then
                        UpdateLineRefWithBlOrdLineNo(TempRecRef, LineNo, NextLineNo);
                end;
            DATABASE::"Service Line":
                begin
                    TempRecRef.SetTable(ServiceLine);
                    TempRecRef := TempRecRef.Duplicate();
                    FieldRef := TempRecRef.Field(ServiceLine.FieldNo("Line No."));
                    ServVATRateChangeConv.GetNextServiceLineNo(ServiceLine, NextLineNo);
                    FieldRef.Value(NextLineNo);
                    TempRecRef.Insert(false);
                    FieldRef := TempRecRef.Field(ServiceLine.FieldNo(Quantity));
                    FieldRef.Validate(Qty);
                    FieldRef := TempRecRef.Field(ServiceLine.FieldNo("Description 2"));
                    FieldRef.Validate(Format(NextLineNo)); // Value is used later.
                    TempRecRef.Modify(true);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateGenPostingSetup(GenProdPostingGroup: Record "Gen. Product Posting Group"; GenBusPostingGroup: Record "Gen. Business Posting Group")
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        InitGenPostingSetup(GenPostingSetup, GenProdPostingGroup, GenBusPostingGroup);
        GenPostingSetup.Validate("Sales Prepayments Account", LibraryERM.CreateGLAccountWithSalesSetup());
        GenPostingSetup.Validate("Purch. Prepayments Account", LibraryERM.CreateGLAccountWithPurchSetup());
        GenPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateGenPostingSetupPrepmtVAT(GenProdPostingGroup: Record "Gen. Product Posting Group"; GenBusPostingGroup: Record "Gen. Business Posting Group"; VATProdPostingGroup: Record "VAT Product Posting Group")
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        InitGenPostingSetup(GenPostingSetup, GenProdPostingGroup, GenBusPostingGroup);
        GenPostingSetup.Validate("Sales Prepayments Account", LibraryERM.CreateGLAccountWithSalesSetup());
        UpdateGLAccWithVATProdPostingGroup(GenPostingSetup."Sales Prepayments Account", VATProdPostingGroup.Code);
        GenPostingSetup.Validate("Purch. Prepayments Account", LibraryERM.CreateGLAccountWithPurchSetup());
        UpdateGLAccWithVATProdPostingGroup(GenPostingSetup."Purch. Prepayments Account", VATProdPostingGroup.Code);
        GenPostingSetup.Modify(true);
    end;

    local procedure InitGenPostingSetup(var GenPostingSetup: Record "General Posting Setup"; GenProdPostingGroup: Record "Gen. Product Posting Group"; GenBusPostingGroup: Record "Gen. Business Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        GenPostingSetup.Init();
        GenPostingSetup.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        GenPostingSetup.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
        GenPostingSetup.Insert(true);

#pragma warning disable AA0210
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.SetRange(Blocked, false);
        GLAccount.SetRange(Totaling, '');
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetFilter("Gen. Prod. Posting Group", '<>''''');
        GLAccount.SetFilter("VAT Prod. Posting Group", '<>''''');
        GLAccount.FindFirst();
#pragma warning restore AA0210

        GenPostingSetup.Validate("Sales Account", GLAccount."No.");
        GenPostingSetup.Validate("Sales Credit Memo Account", GLAccount."No.");
        GenPostingSetup.Validate("Sales Line Disc. Account", GLAccount."No.");
        GenPostingSetup.Validate("Purch. Account", GLAccount."No.");
        GenPostingSetup.Validate("COGS Account", GLAccount."No.");
        GenPostingSetup.Validate("Inventory Adjmt. Account", GLAccount."No.");
        GenPostingSetup.Validate("COGS Account (Interim)", GLAccount."No.");
        GenPostingSetup.Validate("Direct Cost Applied Account", GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateGenProdPostingGroup(var GenProdPostingGroup: Record "Gen. Product Posting Group"; AutoInsertDefault: Boolean)
    begin
        GenProdPostingGroup.Init();
        GenProdPostingGroup.Validate(Code, LibraryUtility.GenerateRandomCode
          (GenProdPostingGroup.FieldNo(Code), DATABASE::"Gen. Product Posting Group"));
        GenProdPostingGroup.Validate("Auto Insert Default", AutoInsertDefault);
        GenProdPostingGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItem(var Item: Record Item)
    var
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItemCharge(var ItemCharge: Record "Item Charge")
    var
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        ItemCharge.Init();
        ItemCharge.Validate("No.", LibraryUtility.GenerateRandomCode(ItemCharge.FieldNo("No."),
            DATABASE::"Item Charge"));
        ItemCharge.Validate(Description, ItemCharge."No.");
        ItemCharge.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithTracking(var Item: Record Item; SalesTracking: Boolean)
    begin
        CreateItem(Item);
        Item.Validate("Item Tracking Code", FindItemTrackingCode(SalesTracking));
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateInventorySetup(InvtPostingGroup: Code[20]; LocationCode: Code[10])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Location: Record Location;
    begin
        if not InventoryPostingSetup.Get(LocationCode, InvtPostingGroup) then begin
            Location.Get(LocationCode);
            LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, LocationCode, InvtPostingGroup);
            LibraryInventory.UpdateInventoryPostingSetup(Location);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateLinesRefPurchase(var TempRecRef: RecordRef; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetFilter("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            if PurchaseLine."No." = '' then
                PurchaseLine.Next();
            RecRef.GetTable(PurchaseLine);
            if TempRecRef.Get(RecRef.RecordId) then
                TempRecRef.Delete(false);
            CopyRecordRef(RecRef, TempRecRef);
            if IsSplitLinePurchase(PurchaseLine)
            then begin
                // Update Reference Lines.
                SplitLineRefPurchase(TempRecRef, PurchaseLine, PurchaseLine."Qty. to Receive");
                // Check if Source Blanket Order Line Exists and Split it
                if GetBlanketOrderLinePurchase(PurchaseLine3, PurchaseLine) then
                    SplitLineRefPurchase(TempRecRef, PurchaseLine3, PurchaseLine."Qty. to Receive");
            end;
        until PurchaseLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateLinesRefSales(var TempRecRef: RecordRef; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        RecRef: RecordRef;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            if SalesLine."No." = '' then
                SalesLine.Next();
            RecRef.GetTable(SalesLine);
            if TempRecRef.Get(RecRef.RecordId) then
                TempRecRef.Delete(false);
            CopyRecordRef(RecRef, TempRecRef);
            if IsSplitLineSales(SalesLine)
            then begin
                // Update Reference Lines.
                SplitLineRefSales(TempRecRef, SalesLine, SalesLine."Qty. to Ship");
                // Check if Source Blanket Order Line Exists and Split it
                if GetBlanketOrderLineSales(SalesLine3, SalesLine) then
                    SplitLineRefSales(TempRecRef, SalesLine3, SalesLine."Qty. to Ship");
            end;
        until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateLinesRefService(var TempRecRef: RecordRef; ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetFilter("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            if ServiceLine."No." = '' then
                ServiceLine.Next();
            RecRef.GetTable(ServiceLine);
            if TempRecRef.Get(RecRef.RecordId) then
                TempRecRef.Delete(false);
            CopyRecordRef(RecRef, TempRecRef);
            if IsSplitLineService(ServiceLine) then
                SplitLineRefService(TempRecRef, ServiceLine, ServiceLine."Qty. to Ship"); // Update Reference Lines.
        until ServiceLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Receive", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        exit(Location.Code);
    end;

    [Scope('OnPrem')]
    procedure CreatePostingGroups(AutoInsertDefault: Boolean)
    var
        FromVATProdPostingGroup: Record "VAT Product Posting Group";
        FromGenProdPostingGroup: Record "Gen. Product Posting Group";
        ToVATProdPostingGroup: Record "VAT Product Posting Group";
        ToGenProdPostingGroup: Record "Gen. Product Posting Group";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
    begin
        SetupVATPostingGroups(FromVATProdPostingGroup, ToVATProdPostingGroup);
        SetupGenPostingGroups(
          FromGenProdPostingGroup, ToGenProdPostingGroup, AutoInsertDefault);
        SetupToolConvGroups(
          VATRateChangeConv.Type::"VAT Prod. Posting Group", FromVATProdPostingGroup.Code, ToVATProdPostingGroup.Code);
        SetupToolConvGroups(
          VATRateChangeConv.Type::"Gen. Prod. Posting Group", FromGenProdPostingGroup.Code, ToGenProdPostingGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure CreatePostingGroupsPrepmtVAT(AutoInsertDefault: Boolean)
    var
        FromVATProdPostingGroup: Record "VAT Product Posting Group";
        FromGenProdPostingGroup: Record "Gen. Product Posting Group";
        ToVATProdPostingGroup: Record "VAT Product Posting Group";
        ToGenProdPostingGroup: Record "Gen. Product Posting Group";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
    begin
        SetupVATPostingGroups(FromVATProdPostingGroup, ToVATProdPostingGroup);
        SetupGenPostingGroupsPrepmtVAT(
          FromGenProdPostingGroup, ToGenProdPostingGroup, FromVATProdPostingGroup, ToVATProdPostingGroup, AutoInsertDefault);
        SetupToolConvGroups(
          VATRateChangeConv.Type::"VAT Prod. Posting Group", FromVATProdPostingGroup.Code, ToVATProdPostingGroup.Code);
        SetupToolConvGroups(
          VATRateChangeConv.Type::"Gen. Prod. Posting Group", FromGenProdPostingGroup.Code, ToGenProdPostingGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10]; LineCount: Integer)
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor());
        CreatePurchaseLines(PurchaseHeader, LocationCode, LineCount);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseDocumentWithRef(var PurchaseHeader: Record "Purchase Header"; var TempRecRef: RecordRef; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10]; LineCount: Integer)
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType, LocationCode, LineCount);
        TempRecRef.Open(DATABASE::"Purchase Line", true);
        CreateLinesRefPurchase(TempRecRef, PurchaseHeader);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Integer)
    begin
        // Create Purchase Line with Quantity > 1 to be able to partially receive it
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseLines(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; LineCount: Integer)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        CreateItem(Item);
        CreateInventorySetup(Item."Inventory Posting Group", LocationCode);

        for I := 1 to LineCount do
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, LocationCode, Item."No.", GetQuantity());
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]; LineCount: Integer)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        CreateSalesLines(SalesHeader, LocationCode, LineCount);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocumentWithRef(var SalesHeader: Record "Sales Header"; var TempRecRef: RecordRef; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]; LineCount: Integer)
    begin
        CreateSalesDocument(SalesHeader, DocumentType, LocationCode, LineCount);
        TempRecRef.Open(DATABASE::"Sales Line", true);
        CreateLinesRefSales(TempRecRef, SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Integer)
    begin
        // Create Sales Line with Quantity > 1 in order to partially ship it
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLines(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; LineCount: Integer)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        I: Integer;
        Qty: Integer;
    begin
        CreateItem(Item);
        CreateInventorySetup(Item."Inventory Posting Group", LocationCode);

        for I := 1 to LineCount do begin
            Qty := GetQuantity();
            PostItemPurchase(Item, LocationCode, Qty);
            CreateSalesLine(SalesLine, SalesHeader, LocationCode, Item."No.", Qty);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateVATPostingSetup(VATProdPostingGroup: Record "VAT Product Posting Group")
    var
        ExistingVATPostingSetup: Record "VAT Posting Setup";
    begin
        ExistingVATPostingSetup.SetFilter("Sales VAT Account", '<>''''');
        ExistingVATPostingSetup.SetFilter("Purchase VAT Account", '<>''''');
        LibraryERM.FindVATPostingSetup(ExistingVATPostingSetup, ExistingVATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateVATPostingSetupBasedOnExisting(ExistingVATPostingSetup, VATProdPostingGroup);
    end;

    local procedure CreateVATPostingSetupBasedOnExisting(ExistingVATPostingSetup: Record "VAT Posting Setup"; VATProdPostingGroup: Record "VAT Product Posting Group")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPercent: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateVATPostingSetupBasedOnExisting(VATPostingSetup, ExistingVATPostingSetup, VATProdPostingGroup, IsHandled);
        if IsHandled then
            exit;

        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Bus. Posting Group", ExistingVATPostingSetup."VAT Bus. Posting Group");
        VATPercent := LibraryRandom.RandInt(30);
        VATPostingSetup.Validate("VAT Identifier", 'VAT' + Format(VATPercent));
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("Sales VAT Account", ExistingVATPostingSetup."Sales VAT Account");
        VATPostingSetup.Validate("Purchase VAT Account", ExistingVATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATProdPostingGroup(var VATProdPostingGroup: Record "VAT Product Posting Group")
    begin
        VATProdPostingGroup.Init();
        VATProdPostingGroup.Validate(Code, LibraryUtility.GenerateRandomCode(VATProdPostingGroup.FieldNo(Code),
            DATABASE::"VAT Product Posting Group"));
        VATProdPostingGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GetGenBusPostingGroupFromSetup(GenProdPostingGroup));
        Vendor.Validate("VAT Bus. Posting Group", GetVATBusPostingGroupFromSetup(VATProdPostingGroup));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateWarehouseDocument(var TempRecRef: RecordRef; TableNo: Integer; LineCount: Integer; ShipReceive: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Location: Code[10];
    begin
        Location := CreateLocation();

        case TableNo of
            DATABASE::"Purchase Line":
                begin
                    CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, PurchaseHeader."Document Type"::Order, Location, LineCount);
                    LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
                    LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
                    if ShipReceive then
                        PostWarehouseReceipt(PurchaseHeader, true);
                end;
            DATABASE::"Sales Line":
                begin
                    CreateSalesDocumentWithRef(SalesHeader, TempRecRef, SalesHeader."Document Type"::Order, Location, LineCount);
                    LibrarySales.ReleaseSalesDocument(SalesHeader);
                    LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
                    if ShipReceive then
                        PostWarehouseShipment(SalesHeader, true);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteGroups()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GenPostingSetup: Record "General Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
    begin
        BlockItems(); // For test cases when Items can't be deleted: block Items with posting groups that will be deleted to prevent other test cases from using them.

        if VATRateChangeConv.FindSet() then
            repeat
                if VATRateChangeConv.Type = VATRateChangeConv.Type::"VAT Prod. Posting Group" then begin
                    VATPostingSetup.SetFilter("VAT Prod. Posting Group", '%1|%2', VATRateChangeConv."From Code", VATRateChangeConv."To Code");
                    VATPostingSetup.DeleteAll();
                    VATProdPostingGroup.SetFilter(Code, '%1|%2', VATRateChangeConv."From Code", VATRateChangeConv."To Code");
                    VATProdPostingGroup.DeleteAll();
                end else begin
                    GenPostingSetup.SetFilter("Gen. Prod. Posting Group", '%1|%2', VATRateChangeConv."From Code", VATRateChangeConv."To Code");
                    GenPostingSetup.DeleteAll();
                    GenProdPostingGroup.SetFilter(Code, '%1|%2', VATRateChangeConv."From Code", VATRateChangeConv."To Code");
                    GenProdPostingGroup.DeleteAll();
                end;
                VATRateChangeConv.Delete(true);
            until VATRateChangeConv.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure DeleteRecords(TableID: Integer)
    var
        RecordRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        RecordRef.Open(TableID);
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        ApplyFilters(RecordRef, VATProdPostingGroup, GenProdPostingGroup);
        RecordRef.DeleteAll(true);
        GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, TableID);
        ApplyFilters(RecordRef, VATProdPostingGroup, GenProdPostingGroup);
        RecordRef.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure FindItemTrackingCode(SalesTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Init();
        ItemTrackingCode.Validate(Code, LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), DATABASE::"Item Tracking Code"));
        ItemTrackingCode.Insert(true);
        ItemTrackingCode.Validate("SN Specific Tracking", false);
        ItemTrackingCode.Validate("SN Sales Inbound Tracking", SalesTracking);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", SalesTracking);
        ItemTrackingCode.Validate("SN Purchase Inbound Tracking", not SalesTracking);
        ItemTrackingCode.Validate("SN Purchase Outbound Tracking", not SalesTracking);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    [Scope('OnPrem')]
    procedure GetConversionErrorCompare(): Text[250]
    begin
        exit(ConversionErrorCompare);
    end;

    [Scope('OnPrem')]
    procedure GetConversionErrorCount(): Text[250]
    begin
        exit(ConversionErrorCount);
    end;

    [Scope('OnPrem')]
    procedure GetConversionErrorUpdate(): Text[250]
    begin
        exit(ConversionErrorUpdate);
    end;

    [Scope('OnPrem')]
    procedure GetConversionErrorNoTables(): Text[250]
    begin
        exit(NoTablesDefinedForConversion);
    end;

    [Scope('OnPrem')]
    procedure GetConversionErrorSplitLines(): Text[250]
    begin
        exit(LinesWereNotSplitted);
    end;

    [Scope('OnPrem')]
    procedure GetBlanketOrderLinePurchase(var PurchaseLine: Record "Purchase Line"; PurchaseLine3: Record "Purchase Line"): Boolean
    begin
        exit(PurchaseLine.Get(PurchaseLine3."Document Type"::"Blanket Order", PurchaseLine3."Blanket Order No.",
            PurchaseLine3."Blanket Order Line No."));
    end;

    [Scope('OnPrem')]
    procedure GetBlanketOrderLineSales(var SalesLine: Record "Sales Line"; SalesLine3: Record "Sales Line"): Boolean
    begin
        exit(SalesLine.Get(SalesLine3."Document Type"::"Blanket Order", SalesLine3."Blanket Order No.",
            SalesLine3."Blanket Order Line No."));
    end;

    [Scope('OnPrem')]
    procedure GetGenBusPostingGroupFromSetup(GenProdPostingGroup: Code[20]): Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.SetFilter("Gen. Prod. Posting Group", GenProdPostingGroup);
        GenPostingSetup.FindLast();
        exit(GenPostingSetup."Gen. Bus. Posting Group");
    end;

    [Scope('OnPrem')]
    procedure GetGenProdPostingGroupFldId(TableId: Integer): Integer
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        JobJournalLine: Record "Job Journal Line";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        ResJournalLine: Record "Res. Journal Line";
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
        StdGenJournalLine: Record "Standard General Journal Line";
        StdItemJournalLine: Record "Standard Item Journal Line";
    begin
        case TableId of
            DATABASE::"Gen. Jnl. Allocation":
                exit(GenJnlAllocation.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Gen. Journal Line":
                exit(GenJournalLine.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"G/L Account":
                exit(GLAccount.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::Item:
                exit(Item.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Item Charge":
                exit(ItemCharge.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Job Journal Line":
                exit(JobJournalLine.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Purchase Line":
                exit(PurchaseLine.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Requisition Line":
                exit(RequisitionLine.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Res. Journal Line":
                exit(ResJournalLine.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::Resource:
                exit(Resource.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Sales Line":
                exit(SalesLine.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Service Line":
                exit(ServiceLine.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Serv. Price Adjustment Detail":
                exit(ServPriceAdjustmentDetail.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Standard General Journal Line":
                exit(StdGenJournalLine.FieldNo("Gen. Prod. Posting Group"));
            DATABASE::"Standard Item Journal Line":
                exit(StdItemJournalLine.FieldNo("Gen. Prod. Posting Group"));
            99000758: // DATABASE::"Machine Center"
                exit(82); // MachineCenter.FieldNo("Gen. Prod. Posting Group"
            5405: // DATABASE::"Production Order"
                exit(16); // ProductionOrder.FieldNo("Gen. Prod. Posting Group")
            99000754: // DATABASE::"Work Center"
                exit(82); // WorkCenter.FieldNo("Gen. Prod. Posting Group"
        end;
        exit(-1);
    end;

    [Scope('OnPrem')]
    procedure GetGroupsAfter(var VATProdPostingGroup: Code[20]; var GenProdPostingGroup: Code[20]; TableNo: Integer)
    var
        VATRateChangeConvVAT: Record "VAT Rate Change Conversion";
        VATRateChangeConvGen: Record "VAT Rate Change Conversion";
        FieldOption: Option "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
    begin
        FieldOption := GetVATChangeSetupUpdateValue(TableNo);

        VATRateChangeConvVAT.SetRange(Type, VATRateChangeConvVAT.Type::"VAT Prod. Posting Group");
        VATRateChangeConvVAT.FindLast();
        VATRateChangeConvGen.SetRange(Type, VATRateChangeConvGen.Type::"Gen. Prod. Posting Group");
        VATRateChangeConvGen.FindLast();

        case FieldOption of
            FieldOption::No:
                begin
                    VATProdPostingGroup := VATRateChangeConvVAT."From Code";
                    GenProdPostingGroup := VATRateChangeConvGen."From Code";
                end;
            FieldOption::"VAT Prod. Posting Group":
                begin
                    VATProdPostingGroup := VATRateChangeConvVAT."To Code";
                    GenProdPostingGroup := VATRateChangeConvGen."From Code";
                end;
            FieldOption::"Gen. Prod. Posting Group":
                begin
                    VATProdPostingGroup := VATRateChangeConvVAT."From Code";
                    GenProdPostingGroup := VATRateChangeConvGen."To Code";
                end;
            FieldOption::Both:
                begin
                    VATProdPostingGroup := VATRateChangeConvVAT."To Code";
                    GenProdPostingGroup := VATRateChangeConvGen."To Code";
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetGroupsBefore(var VATProdPostingGroup: Code[20]; var GenProdPostingGroup: Code[20])
    var
        VATRateChangeConvVAT: Record "VAT Rate Change Conversion";
        VATRateChangeConvGen: Record "VAT Rate Change Conversion";
    begin
        VATRateChangeConvVAT.SetFilter(Type, '%1', VATRateChangeConvVAT.Type::"VAT Prod. Posting Group");
        VATRateChangeConvVAT.FindLast();
        VATRateChangeConvGen.SetFilter(Type, '%1', VATRateChangeConvGen.Type::"Gen. Prod. Posting Group");
        VATRateChangeConvGen.FindLast();
        VATProdPostingGroup := VATRateChangeConvVAT."From Code";
        GenProdPostingGroup := VATRateChangeConvGen."From Code";
    end;

    [Scope('OnPrem')]
    procedure GetItemChargeErrorCount(): Text[250]
    begin
        exit(ItemChargeErrorCount);
    end;

    [Scope('OnPrem')]
    procedure GetItemChargeErrorQty(): Text[250]
    begin
        exit(ItemChargeErrorQty);
    end;

    [Scope('OnPrem')]
    procedure GetReservationEntry(var ReservationEntry: Record "Reservation Entry"; SourceType: Integer; DocumentNo: Code[20]; DocumentType: Option; LineNo: Integer): Boolean
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Source ID", DocumentNo);
        ReservationEntry.SetRange("Source Ref. No.", LineNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", DocumentType);
        exit(ReservationEntry.FindSet());
    end;

    [Scope('OnPrem')]
    procedure GetReservationEntrySales(var ReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line")
    begin
        GetReservationEntry(ReservationEntry, DATABASE::"Sales Line", SalesLine."Document No.", SalesLine."Document Type".AsInteger(), SalesLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure GetReservationEntryPurchase(var ReservationEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line")
    begin
        GetReservationEntry(ReservationEntry, DATABASE::"Purchase Line", PurchaseLine."Document No.", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure GetReservationEntryService(var ReservationEntry: Record "Reservation Entry"; ServiceLine: Record "Service Line")
    begin
        GetReservationEntry(ReservationEntry, DATABASE::"Service Line", ServiceLine."Document No.", ServiceLine."Document Type".AsInteger(), ServiceLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure GetVATBusPostingGroupFromSetup(VATProdPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", VATProdPostingGroup);
        VATPostingSetup.FindLast();
        exit(VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Scope('OnPrem')]
    procedure GetVATChangeSetupUpdateField(TableId: Integer): Integer
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        case TableId of
            DATABASE::"Finance Charge Memo Line":
                exit(VATRateChangeSetup.FieldNo("Update Finance Charge Memos"));
            DATABASE::"Gen. Jnl. Allocation":
                exit(VATRateChangeSetup.FieldNo("Update Gen. Journal Allocation"));
            DATABASE::"Gen. Journal Line":
                exit(VATRateChangeSetup.FieldNo("Update Gen. Journal Lines"));
            DATABASE::"Gen. Product Posting Group":
                exit(VATRateChangeSetup.FieldNo("Update Gen. Prod. Post. Groups"));
            DATABASE::"G/L Account":
                exit(VATRateChangeSetup.FieldNo("Update G/L Accounts"));
            DATABASE::Item:
                exit(VATRateChangeSetup.FieldNo("Update Items"));
            DATABASE::"Item Charge":
                exit(VATRateChangeSetup.FieldNo("Update Item Charges"));
            DATABASE::"Job Journal Line":
                exit(VATRateChangeSetup.FieldNo("Update Job Journal Lines"));
            DATABASE::"Purchase Line":
                exit(VATRateChangeSetup.FieldNo("Update Purchase Documents"));
            DATABASE::"Reminder Line":
                exit(VATRateChangeSetup.FieldNo("Update Reminders"));
            DATABASE::"Requisition Line":
                exit(VATRateChangeSetup.FieldNo("Update Requisition Lines"));
            DATABASE::"Res. Journal Line":
                exit(VATRateChangeSetup.FieldNo("Update Res. Journal Lines"));
            DATABASE::Resource:
                exit(VATRateChangeSetup.FieldNo("Update Resources"));
            DATABASE::"Sales Line":
                exit(VATRateChangeSetup.FieldNo("Update Sales Documents"));
            DATABASE::"Service Line":
                exit(VATRateChangeSetup.FieldNo("Update Service Docs."));
            DATABASE::"Serv. Price Adjustment Detail":
                exit(VATRateChangeSetup.FieldNo("Update Serv. Price Adj. Detail"));
            DATABASE::"Standard General Journal Line":
                exit(VATRateChangeSetup.FieldNo("Update Std. Gen. Jnl. Lines"));
            DATABASE::"Standard Item Journal Line":
                exit(VATRateChangeSetup.FieldNo("Update Std. Item Jnl. Lines"));
            99000758: // DATABASE::"Machine Center"
                exit(VATRateChangeSetup.FieldNo("Update Machine Centers"));
            5405: // DATABASE::"Production Order"
                exit(VATRateChangeSetup.FieldNo("Update Production Orders"));
            99000754: // DATABASE::"Work Center"
                exit(VATRateChangeSetup.FieldNo("Update Work Centers"));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVATChangeSetupUpdateValue(TableId: Integer): Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        UpdateOption: Integer;
    begin
        RecRef.Open(DATABASE::"VAT Rate Change Setup");
        RecRef.Find();
        FieldRef := RecRef.Field(GetVATChangeSetupUpdateField(TableId));
        // VAT Prod. Posting Group = 1, Gen. Prod. Posting Group = 2, Both = 3, No = 4
        UpdateOption := FieldRef.Value();
        exit(UpdateOption);
    end;

    [Scope('OnPrem')]
    procedure GetVATProdPostingGroupFldId(TableId: Integer): Integer
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalLine: Record "Gen. Journal Line";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        ReminderLine: Record "Reminder Line";
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        StdGenJournalLine: Record "Standard General Journal Line";
    begin
        case TableId of
            DATABASE::"Finance Charge Memo Line":
                exit(FinanceChargeMemoLine.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Gen. Jnl. Allocation":
                exit(GenJnlAllocation.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Gen. Journal Line":
                exit(GenJournalLine.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Gen. Product Posting Group":
                exit(GenProdPostingGroup.FieldNo("Def. VAT Prod. Posting Group"));
            DATABASE::"G/L Account":
                exit(GLAccount.FieldNo("VAT Prod. Posting Group"));
            DATABASE::Item:
                exit(Item.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Item Charge":
                exit(ItemCharge.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Purchase Line":
                exit(PurchaseLine.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Reminder Line":
                exit(ReminderLine.FieldNo("VAT Prod. Posting Group"));
            DATABASE::Resource:
                exit(Resource.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Sales Line":
                exit(SalesLine.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Service Line":
                exit(ServiceLine.FieldNo("VAT Prod. Posting Group"));
            DATABASE::"Standard General Journal Line":
                exit(StdGenJournalLine.FieldNo("VAT Prod. Posting Group"));
        end;
        exit(-1);
    end;

    [Scope('OnPrem')]
    procedure GetQuantity() Qty: Integer
    begin
        Qty := LibraryRandom.RandInt(9) + 1
    end;

    [Scope('OnPrem')]
    procedure IsNewVATGroup(ToCode: Code[20]): Boolean
    var
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
    begin
        VATRateChangeConversion.SetRange(Type, VATRateChangeConversion.Type::"VAT Prod. Posting Group");
        VATRateChangeConversion.SetFilter("To Code", ToCode);
        exit(not VATRateChangeConversion.IsEmpty());
    end;

    [Scope('OnPrem')]
    procedure IsNewGenGroup(ToCode: Code[20]): Boolean
    var
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
    begin
        VATRateChangeConversion.SetRange(Type, VATRateChangeConversion.Type::"Gen. Prod. Posting Group");
        VATRateChangeConversion.SetFilter("To Code", ToCode);
        exit(not VATRateChangeConversion.IsEmpty());
    end;

    [Scope('OnPrem')]
    procedure IsSplitLinePurchase(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then // Lines Are Split for Orders Only
            exit(false);
        if IsNewVATGroup(PurchaseLine."VAT Prod. Posting Group") or
           IsNewGenGroup(PurchaseLine."Gen. Prod. Posting Group")
        then // New Groups
            exit(false);
        if PurchaseLine."Qty. to Receive" = 0 then // Warehouse Integration
            exit(false);
        if PurchaseLine.Type = PurchaseLine.Type::"Charge (Item)" then // Item Charge
            exit(false);
        if PurchaseLine.Quantity <> PurchaseLine."Qty. to Receive" then // Partial Shipment
            exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsSplitLineSales(SalesLine: Record "Sales Line"): Boolean
    begin
        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then // Lines Are Split for Orders Only
            exit(false);
        if IsNewVATGroup(SalesLine."VAT Prod. Posting Group") or IsNewGenGroup(SalesLine."Gen. Prod. Posting Group") then // New Groups
            exit(false);
        if SalesLine."Qty. to Ship" = 0 then // Warehouse Integration
            exit(false);
        if SalesLine.Type = SalesLine.Type::"Charge (Item)" then // Item Charge
            exit(false);
        if SalesLine.Quantity <> SalesLine."Qty. to Ship" then // Partial Shipment
            exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsSplitLineService(ServiceLine: Record "Service Line"): Boolean
    begin
        if ServiceLine."Document Type" <> ServiceLine."Document Type"::Order then // Lines Are Split for Orders Only
            exit(false);
        if IsNewVATGroup(ServiceLine."VAT Prod. Posting Group") or
           IsNewGenGroup(ServiceLine."Gen. Prod. Posting Group")
        then // New Groups
            exit(false);
        if ServiceLine."Qty. to Ship" = 0 then // Warehouse Integration
            exit(false);
        if ServiceLine.Quantity <> ServiceLine."Qty. to Ship" then // Partial Shipment
            exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure MakeOrderPurchase(var PurchaseHeader: Record "Purchase Header"; var PurchaseOrderHeader: Record "Purchase Header")
    var
        BlanketPurchOrderToOrder: Codeunit "Blanket Purch. Order to Order";
        PurchQuoteToOrder: Codeunit "Purch.-Quote to Order";
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::"Blanket Order":
                begin
                    BlanketPurchOrderToOrder.Run(PurchaseHeader);
                    BlanketPurchOrderToOrder.GetPurchOrderHeader(PurchaseOrderHeader);
                end;
            PurchaseHeader."Document Type"::Quote:
                begin
                    PurchQuoteToOrder.Run(PurchaseHeader);
                    PurchQuoteToOrder.GetPurchOrderHeader(PurchaseOrderHeader);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure MakeOrderSales(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    var
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::"Blanket Order":
                begin
                    BlanketSalesOrderToOrder.Run(SalesHeader);
                    BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
                end;
            SalesHeader."Document Type"::Quote:
                begin
                    SalesQuoteToOrder.Run(SalesHeader);
                    SalesQuoteToOrder.GetSalesOrderHeader(SalesOrderHeader);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PostItemPurchase(Item: Record Item; LocationCode: Code[10]; Quantity: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          Item."No.", Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Gen. Bus. Posting Group", GetGenBusPostingGroupFromSetup(Item."Gen. Prod. Posting Group"));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [Scope('OnPrem')]
    procedure PostPurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchasePostPrepayments.Invoice(PurchaseHeader);
    end;

    [Scope('OnPrem')]
    procedure PostWarehouseReceipt(PurchaseHeader: Record "Purchase Header"; Partially: Boolean)
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WhseReceiptLine.SetFilter("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.FindSet();

        WhseReceiptHeader.SetFilter("No.", WhseReceiptLine."No.");
        WhseReceiptHeader.FindFirst();
        repeat
            if Partially then
                WhseReceiptLine.Validate("Qty. to Receive", Round(WhseReceiptLine.Quantity / 2, 1))
            else
                WhseReceiptLine.Validate("Qty. to Receive", WhseReceiptLine.Quantity);
            WhseReceiptLine.Modify(true);
        until WhseReceiptLine.Next() = 0;
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);
    end;

    [Scope('OnPrem')]
    procedure PostWarehouseShipment(SalesHeader: Record "Sales Header"; Partially: Boolean)
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WhseShipmentLine.SetFilter("Source No.", SalesHeader."No.");
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.FindSet();

        WhseShipmentHeader.SetFilter("No.", WhseShipmentLine."No.");
        WhseShipmentHeader.FindFirst();
        repeat
            if Partially then
                WhseShipmentLine.Validate("Qty. to Ship", Round(WhseShipmentLine.Quantity / 2, 1))
            else
                WhseShipmentLine.Validate("Qty. to Ship", WhseShipmentLine.Quantity);
            WhseShipmentLine.Modify(true);
        until WhseShipmentLine.Next() = 0;
        LibraryWarehouse.PostWhseShipment(WhseShipmentHeader, false);
    end;

    [Scope('OnPrem')]
    procedure ResetToolSetup()
    var
        VATRateChangeConv: Record "VAT Rate Change Conversion";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
        ResetVATRateChangeSetup();
        VATRateChangeConv.DeleteAll();
        VATRateChangeLogEntry.DeleteAll();
        Commit();
    end;

    [Scope('OnPrem')]
    procedure ResetVATRateChangeSetup()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        VATRateChangeSetup.DeleteAll();
        VATRateChangeSetup.Init();
        VATRateChangeSetup.Insert();
        VATRateChangeSetup."Update Gen. Prod. Post. Groups" := VATRateChangeSetup."Update Gen. Prod. Post. Groups"::No;
        VATRateChangeSetup."Update G/L Accounts" := VATRateChangeSetup."Update G/L Accounts"::No;
        VATRateChangeSetup."Update Items" := VATRateChangeSetup."Update Items"::No;
        VATRateChangeSetup."Update Item Templates" := VATRateChangeSetup."Update Item Templates"::No;
        VATRateChangeSetup."Update Item Charges" := VATRateChangeSetup."Update Item Charges"::No;
        VATRateChangeSetup."Update Resources" := VATRateChangeSetup."Update Resources"::No;
        VATRateChangeSetup."Update Gen. Journal Lines" := VATRateChangeSetup."Update Gen. Journal Lines"::No;
        VATRateChangeSetup."Update Gen. Journal Allocation" := VATRateChangeSetup."Update Gen. Journal Allocation"::No;
        VATRateChangeSetup."Update Std. Gen. Jnl. Lines" := VATRateChangeSetup."Update Std. Gen. Jnl. Lines"::No;
        VATRateChangeSetup."Update Res. Journal Lines" := VATRateChangeSetup."Update Res. Journal Lines"::No;
        VATRateChangeSetup."Update Job Journal Lines" := VATRateChangeSetup."Update Job Journal Lines"::No;
        VATRateChangeSetup."Update Requisition Lines" := VATRateChangeSetup."Update Requisition Lines"::No;
        VATRateChangeSetup."Update Std. Item Jnl. Lines" := VATRateChangeSetup."Update Std. Item Jnl. Lines"::No;
        VATRateChangeSetup."Update Service Docs." := VATRateChangeSetup."Update Service Docs."::No;
        VATRateChangeSetup."Update Serv. Price Adj. Detail" := VATRateChangeSetup."Update Serv. Price Adj. Detail"::No;
        VATRateChangeSetup."Update Sales Documents" := VATRateChangeSetup."Update Sales Documents"::No;
        VATRateChangeSetup."Update Purchase Documents" := VATRateChangeSetup."Update Purchase Documents"::No;
        VATRateChangeSetup."Update Production Orders" := VATRateChangeSetup."Update Production Orders"::No;
        VATRateChangeSetup."Update Work Centers" := VATRateChangeSetup."Update Work Centers"::No;
        VATRateChangeSetup."Update Machine Centers" := VATRateChangeSetup."Update Machine Centers"::No;
        VATRateChangeSetup."Update Reminders" := VATRateChangeSetup."Update Reminders"::No;
        VATRateChangeSetup."Update Finance Charge Memos" := VATRateChangeSetup."Update Finance Charge Memos"::No;
        VATRateChangeSetup."Ignore Status on Sales Docs." := false;
        VATRateChangeSetup."Ignore Status on Purch. Docs." := false;
        VATRateChangeSetup."Update Unit Price For G/L Acc." := false;
        VATRateChangeSetup."Upd. Unit Price For Item Chrg." := false;
        VATRateChangeSetup."Upd. Unit Price For FA" := false;
        VATRateChangeSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure RunVATRateChangeTool()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        Assert.IsTrue(VATRateChangeSetup.Get(), NotInitializedError);
        CODEUNIT.Run(CODEUNIT::"VAT Rate Change Conversion");
    end;

    [Scope('OnPrem')]
    procedure SetFilter(var TableRecRef: RecordRef; FieldNo: Integer; FieldValue: Code[30]): Boolean
    var
        FieldRef: FieldRef;
    begin
        FieldRef := TableRecRef.Field(FieldNo);
        FieldRef.SetFilter(FieldValue);
        exit(TableRecRef.FindSet());
    end;

    [Scope('OnPrem')]
    procedure SetFilters(var TableRecRef: RecordRef; Field1No: Integer; Field1Value: Code[30]; Field2No: Integer; Field2Value: Code[30]): Boolean
    var
        FieldRef1: FieldRef;
        FieldRef2: FieldRef;
    begin
        FieldRef1 := TableRecRef.Field(Field1No);
        FieldRef2 := TableRecRef.Field(Field2No);
        FieldRef1.SetFilter(Field1Value);
        FieldRef2.SetFilter(Field2Value);
        exit(TableRecRef.FindSet());
    end;

    [Scope('OnPrem')]
    procedure SetupGenPostingGroups(var FromGenProdPostingGroup: Record "Gen. Product Posting Group"; var ToGenProdPostingGroup: Record "Gen. Product Posting Group"; AutoInsertDefault: Boolean)
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        CreateGenProdPostingGroup(FromGenProdPostingGroup, AutoInsertDefault);
        CreateGenProdPostingGroup(ToGenProdPostingGroup, AutoInsertDefault);
        LibraryERM.FindGenBusinessPostingGroup(GenBusPostingGroup);
        CreateGenPostingSetup(FromGenProdPostingGroup, GenBusPostingGroup);
        CreateGenPostingSetup(ToGenProdPostingGroup, GenBusPostingGroup);
    end;

    [Scope('OnPrem')]
    procedure SetupGenPostingGroupsPrepmtVAT(var FromGenProdPostingGroup: Record "Gen. Product Posting Group"; var ToGenProdPostingGroup: Record "Gen. Product Posting Group"; FromVATProdPostingGroup: Record "VAT Product Posting Group"; ToVATProdPostingGroup: Record "VAT Product Posting Group"; AutoInsertDefault: Boolean)
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        CreateGenProdPostingGroup(FromGenProdPostingGroup, AutoInsertDefault);
        CreateGenProdPostingGroup(ToGenProdPostingGroup, AutoInsertDefault);
        LibraryERM.FindGenBusinessPostingGroup(GenBusPostingGroup);
        CreateGenPostingSetupPrepmtVAT(FromGenProdPostingGroup, GenBusPostingGroup, FromVATProdPostingGroup);
        CreateGenPostingSetupPrepmtVAT(ToGenProdPostingGroup, GenBusPostingGroup, ToVATProdPostingGroup);
    end;

    [Scope('OnPrem')]
    procedure SetupItemNos()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // Modify Item No. Series in Inventory setup.
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupToolOption(FieldNo: Integer; FieldOption: Option)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"VAT Rate Change Setup");
        Assert.IsTrue(RecRef.FindFirst(), NotInitializedError);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldOption);
        RecRef.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupToolCheckbox(FieldNo: Integer; FieldValue: Boolean)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"VAT Rate Change Setup");
        Assert.IsTrue(RecRef.FindFirst(), NotInitializedError);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldValue);
        RecRef.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupToolString(FieldNo: Integer; FieldValue: Text[250])
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"VAT Rate Change Setup");
        Assert.IsTrue(RecRef.FindFirst(), NotInitializedError);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldValue);
        RecRef.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupToolConvGroups(GroupType: Option; FromGenProdPostingGroup: Code[20]; ToGenProdPostingGroup: Code[20])
    var
        VATRateChangeConv: Record "VAT Rate Change Conversion";
    begin
        VATRateChangeConv.Init();
        VATRateChangeConv.Validate(Type, GroupType);
        VATRateChangeConv.Validate("From Code", FromGenProdPostingGroup);
        VATRateChangeConv.Validate("To Code", ToGenProdPostingGroup);
        VATRateChangeConv.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure SetupVATPostingGroups(var FromVATProdPostingGroup: Record "VAT Product Posting Group"; var ToVATProdPostingGroup: Record "VAT Product Posting Group")
    begin
        CreateVATProdPostingGroup(FromVATProdPostingGroup);
        CreateVATProdPostingGroup(ToVATProdPostingGroup);
        CreateVATPostingSetup(FromVATProdPostingGroup);
        CreateVATPostingSetup(ToVATProdPostingGroup);
    end;

    [Scope('OnPrem')]
    procedure SplitLineRefPurchase(var TempRecRef: RecordRef; var PurchaseLine: Record "Purchase Line"; Qty: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PurchaseLine);
        TempRecRef.Get(RecRef.RecordId);
        UpdateOldLineRef(TempRecRef, Qty);
        CreateNewLineRef(TempRecRef, PurchaseLine.Quantity - Qty);
    end;

    [Scope('OnPrem')]
    procedure SplitLineRefSales(var TempRecRef: RecordRef; var SalesLine: Record "Sales Line"; Qty: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesLine);
        TempRecRef.Get(RecRef.RecordId);
        UpdateOldLineRef(TempRecRef, Qty);
        CreateNewLineRef(TempRecRef, SalesLine.Quantity - Qty);
    end;

    [Scope('OnPrem')]
    procedure SplitLineRefService(var TempRecRef: RecordRef; var ServiceLine: Record "Service Line"; Qty: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ServiceLine);
        TempRecRef.Get(RecRef.RecordId);
        UpdateOldLineRef(TempRecRef, Qty);
        CreateNewLineRef(TempRecRef, ServiceLine.Quantity - Qty);
    end;

    [Scope('OnPrem')]
    procedure UpdateOldLineRef(var TempRecRef: RecordRef; Qty: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        FieldRef: FieldRef;
    begin
        case TempRecRef.Number of
            DATABASE::"Purchase Line":
                begin
                    FieldRef := TempRecRef.Field(PurchaseLine.FieldNo(Quantity));
                    FieldRef.Value(Qty);
                    FieldRef := TempRecRef.Field(PurchaseLine.FieldNo("Qty. to Receive"));
                    FieldRef.Value(Qty);
                end;
            DATABASE::"Sales Line":
                begin
                    FieldRef := TempRecRef.Field(SalesLine.FieldNo(Quantity));
                    FieldRef.Value(Qty);
                    FieldRef := TempRecRef.Field(SalesLine.FieldNo("Qty. to Ship"));
                    FieldRef.Value(Qty);
                end;
            DATABASE::"Service Line":
                begin
                    FieldRef := TempRecRef.Field(ServiceLine.FieldNo(Quantity));
                    FieldRef.Value(Qty);
                    FieldRef := TempRecRef.Field(ServiceLine.FieldNo("Qty. to Ship"));
                    FieldRef.Value(Qty);
                end;
        end;
        TempRecRef.Modify(false);
    end;

    [Scope('OnPrem')]
    procedure UpdateLineRefWithBlOrdLineNo(var TempRecRef: RecordRef; LineNo: Integer; NextLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        FieldRef: FieldRef;
    begin
        case TempRecRef.Number of
            DATABASE::"Purchase Line":
                begin
                    TempRecRef.SetTable(PurchaseLine);
                    PurchaseLine2.SetRange("Document Type", PurchaseLine2."Document Type"::Order);
                    PurchaseLine2.SetFilter("Blanket Order No.", PurchaseLine."Document No.");
                    PurchaseLine2.SetRange("Blanket Order Line No.", LineNo);
                    PurchaseLine2.SetFilter("Description 2", '<>''''');
                    TempRecRef.SetView(PurchaseLine2.GetView());
                    TempRecRef.FindFirst();
                    FieldRef := TempRecRef.Field(PurchaseLine2.FieldNo("Blanket Order Line No."));
                    FieldRef.Value(NextLineNo);
                end;
            DATABASE::"Sales Line":
                begin
                    TempRecRef.SetTable(SalesLine);
                    SalesLine2.SetRange("Document Type", SalesLine2."Document Type"::Order);
                    SalesLine2.SetFilter("Blanket Order No.", SalesLine."Document No.");
                    SalesLine2.SetRange("Blanket Order Line No.", LineNo);
                    SalesLine2.SetFilter("Description 2", '<>''''');
                    TempRecRef.SetView(SalesLine2.GetView());
                    TempRecRef.FindFirst();
                    FieldRef := TempRecRef.Field(SalesLine2.FieldNo("Blanket Order Line No."));
                    FieldRef.Value(NextLineNo);
                end;
        end;
        TempRecRef.Modify(true);
        TempRecRef.SetView('');
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToAssignPurchase(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchLine: Record "Purchase Line")
    begin
        PurchLine.Find();
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", PurchLine."Qty. to Invoice");
        ItemChargeAssignmentPurch.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToAssignSales(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesLine: Record "Sales Line")
    begin
        SalesLine.Find();
        ItemChargeAssignmentSales.Validate("Qty. to Assign", SalesLine."Qty. to Invoice");
        ItemChargeAssignmentSales.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateLineQtyToConsumeInvoice(var ServiceLine: Record "Service Line"; Consume: Boolean; Invoice: Boolean)
    begin
        // Update Service Lines.
        if Consume then
            ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship")
        else
            if Invoice then
                ServiceLine.Validate("Qty. to Invoice", ServiceLine."Qty. to Ship");
        ServiceLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateLineQtyToReceive(var PurchaseLine: Record "Purchase Line")
    var
        Qty: Integer;
    begin
        // Update Purchase Lines.
        Qty := Round(PurchaseLine.Quantity / 3, 1);
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then
            PurchaseLine.Validate("Return Qty. to Ship", Qty)
        else
            PurchaseLine.Validate("Qty. to Receive", Qty);
        PurchaseLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateLineQtyToShip(var SalesLine: Record "Sales Line")
    var
        Qty: Integer;
    begin
        // Update Sales Lines.
        Qty := Round(SalesLine.Quantity / 3, 1);
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
            SalesLine.Validate("Return Qty. to Receive", Qty)
        else
            SalesLine.Validate("Qty. to Ship", Qty);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateLineQtyToShipService(var ServiceLine: Record "Service Line")
    begin
        // Update Service Lines.
        ServiceLine.Validate("Qty. to Ship", Round(ServiceLine."Qty. to Ship" / 2, 1));
        ServiceLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateLineQtyToHandle(SourceType: Integer; DocumentNo: Code[20]; DocumentType: Option; LineNo: Integer; Qty: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
        I: Integer;
    begin
        GetReservationEntry(ReservationEntry, SourceType, DocumentNo, DocumentType, LineNo);

        // Change Qty. to Handle to 0 for Item Tracking entries that are not going to be shipped/received
        for I := ReservationEntry.Count - 1 downto Qty do begin
            ReservationEntry.Validate("Qty. to Handle (Base)", 0);
            ReservationEntry.Modify(true);
            ReservationEntry.Next();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToConsumeInvoice(var ServiceHeader: Record "Service Header"; Consume: Boolean; Invoice: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetFilter("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();

        repeat
            UpdateLineQtyToConsumeInvoice(ServiceLine, Consume, Invoice);
        until ServiceLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToHandlePurchase(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        UpdateLineQtyToHandle(DATABASE::"Purchase Line", PurchaseLine."Document No.", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Line No.", PurchaseLine."Qty. to Receive");
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToHandleSales(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        UpdateLineQtyToHandle(DATABASE::"Sales Line", SalesLine."Document No.", SalesLine."Document Type".AsInteger(), SalesLine."Line No.", SalesLine."Qty. to Ship");
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToHandleService(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        UpdateLineQtyToHandle(DATABASE::"Service Line", ServiceLine."Document No.", ServiceLine."Document Type".AsInteger(), ServiceLine."Line No.", ServiceLine."Qty. to Ship");
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToReceive(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Update Purchase Lines.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetFilter("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();

        repeat
            UpdateLineQtyToReceive(PurchaseLine);
        until PurchaseLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToShip(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter("Document No.", SalesHeader."No.");
        SalesLine.FindSet();

        repeat
            UpdateLineQtyToShip(SalesLine);
        until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateQtyToShipService(var ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetFilter("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();

        repeat
            UpdateLineQtyToShipService(ServiceLine);
        until ServiceLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateVatRateChangeSetup(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
        // Create posting groups to update and save them in VAT Change Tool Conversion table.
        CreatePostingGroups(false);
        VATRateChangeSetup.Get();
        VATRateChangeSetup.Validate("Update G/L Accounts", VATRateChangeSetup."Update G/L Accounts"::"VAT Prod. Posting Group");
        VATRateChangeSetup.Validate("Update Items", VATRateChangeSetup."Update Items"::"VAT Prod. Posting Group");
        VATRateChangeSetup.Validate("Update Resources", VATRateChangeSetup."Update Resources"::"VAT Prod. Posting Group");
        VATRateChangeSetup.Validate("Update Item Templates", VATRateChangeSetup."Update Item Templates"::"VAT Prod. Posting Group");
        VATRateChangeSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateUnitPricesInclVATSetup(UpdateForGLAccount: Boolean; UpdateForItemCharge: Boolean; UpdateForFixedAsset: Boolean)
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        VATRateChangeSetup.Get();
        VATRateChangeSetup.Validate("Update Unit Price For G/L Acc.", UpdateForGLAccount);
        VATRateChangeSetup.Validate("Upd. Unit Price For Item Chrg.", UpdateForItemCharge);
        VATRateChangeSetup.Validate("Upd. Unit Price For FA", UpdateForFixedAsset);
        VATRateChangeSetup.Modify(true);
    end;

    local procedure UpdateGLAccWithVATProdPostingGroup(GLAccNo: Code[20]; VATProdPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        GLAccount.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyDataUpdate(DataToUpdateRecRef: RecordRef; DataAfterUpdateRecRef: RecordRef)
    begin
        Assert.AreEqual(DataToUpdateRecRef.Count, DataAfterUpdateRecRef.Count,
          StrSubstNo(ConversionErrorCount, DataAfterUpdateRecRef.GetFilters));
        repeat
            VerifyPrimaryKeysAreEqual(DataToUpdateRecRef, DataAfterUpdateRecRef);
            DataAfterUpdateRecRef.Next();
        until DataToUpdateRecRef.Next() = 0;
    end;

    local procedure VerifyGroupsInLogEntry(VATRateChangeLogEntry: Record "VAT Rate Change Log Entry"; TableID: Integer)
    var
        VATProdPostingGroup: Code[20];
        VATProdPostingGroup2: Code[20];
        GenProdPostingGroup: Code[20];
        GenProdPostingGroup2: Code[20];
    begin
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        GetGroupsAfter(VATProdPostingGroup2, GenProdPostingGroup2, TableID);

        if GetVATProdPostingGroupFldId(TableID) > 0 then begin
            Assert.AreEqual(VATProdPostingGroup, VATRateChangeLogEntry."Old VAT Prod. Posting Group",
              StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("Old VAT Prod. Posting Group")));
            Assert.AreEqual(VATProdPostingGroup2, VATRateChangeLogEntry."New VAT Prod. Posting Group",
              StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("New VAT Prod. Posting Group")));
        end else begin
            Assert.AreEqual('', VATRateChangeLogEntry."Old VAT Prod. Posting Group",
              StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("Old VAT Prod. Posting Group")));
            Assert.AreEqual('', VATRateChangeLogEntry."New VAT Prod. Posting Group",
              StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("New VAT Prod. Posting Group")));
        end;
        if GetGenProdPostingGroupFldId(TableID) > 0 then begin
            Assert.AreEqual(GenProdPostingGroup, VATRateChangeLogEntry."Old Gen. Prod. Posting Group",
              StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("Old Gen. Prod. Posting Group")));
            Assert.AreEqual(GenProdPostingGroup2, VATRateChangeLogEntry."New Gen. Prod. Posting Group",
              StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("New Gen. Prod. Posting Group")));
        end else begin
            Assert.AreEqual('', VATRateChangeLogEntry."Old Gen. Prod. Posting Group",
              StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("Old Gen. Prod. Posting Group")));
            Assert.AreEqual('', VATRateChangeLogEntry."New Gen. Prod. Posting Group",
              StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("New Gen. Prod. Posting Group")));
        end;
    end;

    local procedure VerifyGroupsInLogEntriesNotConverted(TempRecRef: RecordRef)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
        VATRateChangeLogEntry.FindSet();
        if TempRecRef.FindSet() then
            repeat
                VATRateChangeLogEntry.TestField(Converted, false);
                VATRateChangeLogEntry.TestField("Converted Date", 0D);
                if TempRecRef.Number = VATRateChangeLogEntry."Table ID" then begin
                    // For document lines groups should not be empty
                    VATRateChangeLogEntry.TestField("Old VAT Prod. Posting Group", VATRateChangeLogEntry."New VAT Prod. Posting Group");
                    VATRateChangeLogEntry.TestField("Old Gen. Prod. Posting Group", VATRateChangeLogEntry."New Gen. Prod. Posting Group");
                end else begin
                    // For document headers groups should be the same
                    VATRateChangeLogEntry.TestField("Old VAT Prod. Posting Group", '');
                    VATRateChangeLogEntry.TestField("New VAT Prod. Posting Group", '');
                    VATRateChangeLogEntry.TestField("Old Gen. Prod. Posting Group", '');
                    VATRateChangeLogEntry.TestField("New Gen. Prod. Posting Group", '');
                end;
                Assert.AreNotEqual('', VATRateChangeLogEntry.Description, StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName(Description)));
                VATRateChangeLogEntry.Next();
            until TempRecRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyDocumentSplitLogEntries(TempRecRef: RecordRef)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
        Assert.AreEqual(TempRecRef.Count, VATRateChangeLogEntry.Count, LogEntryErrorCount);

        if TempRecRef.FindSet() then
            repeat
                // Verify log for first line
                VATRateChangeLogEntry.SetRange("Table ID", TempRecRef.Number);
                VATRateChangeLogEntry.SetRange("Record ID", TempRecRef.RecordId);
                Assert.IsTrue(VATRateChangeLogEntry.FindFirst(), StrSubstNo(LogEntryErrorNoEntry, TempRecRef.RecordId));
                VATRateChangeLogEntry.TestField(Converted, true);
                VATRateChangeLogEntry.TestField("Converted Date", WorkDate());
                VATRateChangeLogEntry.TestField("Old VAT Prod. Posting Group", VATRateChangeLogEntry."New VAT Prod. Posting Group");
                VATRateChangeLogEntry.TestField("Old Gen. Prod. Posting Group", VATRateChangeLogEntry."New Gen. Prod. Posting Group");
                Assert.AreNotEqual('', VATRateChangeLogEntry.Description, StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName(Description)));
                // Verify log for split line
                TempRecRef.Next();
                VATRateChangeLogEntry.SetRange("Table ID", TempRecRef.Number);
                VATRateChangeLogEntry.SetRange("Record ID", TempRecRef.RecordId);
                Assert.IsTrue(VATRateChangeLogEntry.FindFirst(), StrSubstNo(LogEntryErrorNoEntry, TempRecRef.RecordId));
                Assert.IsTrue(VATRateChangeLogEntry.Converted, StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName(Converted)));
                Assert.AreEqual(WorkDate(), VATRateChangeLogEntry."Converted Date", StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName("Converted Date")));
                VerifyGroupsInLogEntry(VATRateChangeLogEntry, TempRecRef.Number);
                Assert.AreNotEqual('', VATRateChangeLogEntry.Description, StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName(Description)));
            until TempRecRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyErrorLogEntries(TempRecRef: RecordRef; EntriesExpected: Boolean)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
        if not EntriesExpected then begin
            Assert.AreEqual(0, VATRateChangeLogEntry.Count, LogEntryErrorCount);
            exit;
        end;

        Assert.AreEqual(TempRecRef.Count, VATRateChangeLogEntry.Count, LogEntryErrorCount);
        VerifyGroupsInLogEntriesNotConverted(TempRecRef);
    end;

    [Scope('OnPrem')]
    procedure VerifySpecialDocLogEntries(TempRecRef: RecordRef)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
        Assert.AreEqual(TempRecRef.Count * 2, VATRateChangeLogEntry.Count, LogEntryErrorCount);
        VerifyGroupsInLogEntriesNotConverted(TempRecRef);
    end;

    [Scope('OnPrem')]
    procedure VerifyLogEntries(TempRecRef: RecordRef)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
        VerifyRecordsHandled(TempRecRef);
        if TempRecRef.FindSet() then
            repeat
                VATRateChangeLogEntry.SetRange("Table ID", TempRecRef.Number);
                // Serv. Price Adjustment Detail has Gen. Prod. Posting Group as a part of primary key
                if TempRecRef.Number <> DATABASE::"Serv. Price Adjustment Detail" then
                    VATRateChangeLogEntry.SetRange("Record ID", TempRecRef.RecordId);
                Assert.IsTrue(VATRateChangeLogEntry.FindFirst(), StrSubstNo(LogEntryErrorNoEntry, TempRecRef.RecordId));
                VATRateChangeLogEntry.TestField(Converted, true);
                VATRateChangeLogEntry.TestField("Converted Date", WorkDate());
                VATRateChangeLogEntry.TestField(Description, '');
                VerifyGroupsInLogEntry(VATRateChangeLogEntry, TempRecRef.Number);
            until TempRecRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyRecordsHandled(TempRecRef: RecordRef)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup2: Code[20];
        GenProdPostingGroup2: Code[20];
    begin
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        GetGroupsAfter(VATProdPostingGroup2, GenProdPostingGroup2, TempRecRef.Number);

        if (VATProdPostingGroup = VATProdPostingGroup2) and (GenProdPostingGroup = GenProdPostingGroup2) then begin
            Assert.IsTrue(VATRateChangeLogEntry.IsEmpty, LogEntryErrorCount);
            exit;
        end;

        Assert.AreEqual(TempRecRef.Count, VATRateChangeLogEntry.Count, LogEntryErrorCount);
    end;

    [Scope('OnPrem')]
    procedure VerifyLogEntriesConvFalse(TableID: Integer; ShippedOrReceived: Boolean)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup2: Code[20];
        GenProdPostingGroup2: Code[20];
    begin
        GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        GetGroupsAfter(VATProdPostingGroup2, GenProdPostingGroup2, TableID);

        if (VATProdPostingGroup = VATProdPostingGroup2) and (GenProdPostingGroup = GenProdPostingGroup2) then begin
            Assert.IsTrue(VATRateChangeLogEntry.IsEmpty, LogEntryErrorCount);
            exit;
        end;

        VATRateChangeLogEntry.SetRange("Table ID", TableID);
        Assert.AreEqual(1, VATRateChangeLogEntry.Count, LogEntryErrorCount);

        Assert.IsTrue(VATRateChangeLogEntry.FindFirst(), StrSubstNo(LogEntryErrorNoEntry, TableID));
        VATRateChangeLogEntry.TestField(Converted, false);
        VATRateChangeLogEntry.TestField("Converted Date", 0D);
        Assert.AreNotEqual('', VATRateChangeLogEntry.Description, StrSubstNo(LogEntryErrorContent, VATRateChangeLogEntry.FieldName(Description)));
        if ShippedOrReceived then begin
            VATRateChangeLogEntry.TestField("Old VAT Prod. Posting Group", VATRateChangeLogEntry."New VAT Prod. Posting Group");
            VATRateChangeLogEntry.TestField("Old Gen. Prod. Posting Group", VATRateChangeLogEntry."New Gen. Prod. Posting Group");
        end else
            VerifyGroupsInLogEntry(VATRateChangeLogEntry, TableID);
    end;

    [Scope('OnPrem')]
    procedure VerifyUpdate(TempRecRef: RecordRef; UpdateExpected: Boolean)
    var
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        RecRef.Open(TempRecRef.Number);
        if UpdateExpected then
            GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, TempRecRef.Number)
        else
            GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);

        ApplyFilters(RecRef, VATProdPostingGroup, GenProdPostingGroup);

        // Prepare Temp Record
        TempRecRef.Reset();
        TempRecRef.FindSet();

        // Verify: Existing records updated as expected.
        if TempRecRef.Number <> DATABASE::"Serv. Price Adjustment Detail" then
            VerifyDataUpdate(TempRecRef, RecRef)
        else
            VerifyDataUpdateForServPriceAD(TempRecRef, RecRef);

        // Verify: No records with new posting groups exist.
        if not UpdateExpected then begin
            GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, TempRecRef.Number);
            ApplyFilters(RecRef, VATProdPostingGroup, GenProdPostingGroup);
            Assert.IsTrue(RecRef.IsEmpty, StrSubstNo(ConversionErrorUnexpected, RecRef.GetFilters));
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyUpdateConvFalse(TableID: Integer)
    var
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        RecRef.Open(TableID);
        GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, TableID);
        ApplyFilters(RecRef, VATProdPostingGroup, GenProdPostingGroup);
        Assert.AreEqual(0, RecRef.Count, StrSubstNo(ConversionErrorUnexpected, RecRef.GetFilters));
    end;

    [Scope('OnPrem')]
    procedure VerifyDataUpdateForServPriceAD(DataToUpdateRecRef: RecordRef; DataAfterUpdateRecRef: RecordRef)
    var
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
    begin
        // Serv. Price Adjustment Detail needs different data validation, because Gen. Prod. Posting Group is a part of the primary key
        Assert.AreEqual(DataToUpdateRecRef.Count, DataAfterUpdateRecRef.Count,
          StrSubstNo(ConversionErrorCount, DataAfterUpdateRecRef.GetFilters));
        repeat
            Assert.AreEqual(DataToUpdateRecRef.Field(ServPriceAdjustmentDetail.FieldNo("Serv. Price Adjmt. Gr. Code")).Value,
              DataAfterUpdateRecRef.Field(ServPriceAdjustmentDetail.FieldNo("Serv. Price Adjmt. Gr. Code")).Value,
              ConversionErrorCompare);
            DataAfterUpdateRecRef.Next();
        until DataToUpdateRecRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyPrimaryKeysAreEqual(RecRef1: RecordRef; RecRef2: RecordRef)
    begin
        Assert.AreEqual(RecRef1.GetPosition(false), RecRef2.GetPosition(false), ConversionErrorCompare);
    end;

    [Scope('OnPrem')]
    procedure VerifyValueOnZeroOutstandingQty(VATProdPostingGroup: Code[20]; TableId: Integer)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
#pragma warning disable AA0210
        VATRateChangeLogEntry.SetRange("Table ID", TableId);
        VATRateChangeLogEntry.SetRange("Old VAT Prod. Posting Group", VATProdPostingGroup);
#pragma warning restore AA0210
        VATRateChangeLogEntry.FindSet();
        repeat
            VATRateChangeLogEntry.TestField(Description, LogEntryContentErr);
        until VATRateChangeLogEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateVATPostingSetupBasedOnExisting(var VATPostingSetup: Record "VAT Posting Setup"; ExistingVATPostingSetup: Record "VAT Posting Setup"; VATProdPostingGroup: Record "VAT Product Posting Group"; var IsHandled: Boolean)
    begin
    end;
}

