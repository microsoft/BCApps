codeunit 142101 "Item Chrg. Upd. Doc. Ln. Gr."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        //[FEATURE] [Item Charge] [Sales] [Purchase]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesDocuments()
    var
        SalesHeader: array[2] of Record "Sales Header";
        ItemCharge: Record "Item Charge";
        DocNo: array[4] of Code[20];
    begin
        Initialize();

        // [GIVEN] Item charges "IC"
        CreateItemCharge(ItemCharge);
        // [GIVEN] Sales order "SO" with 2 lines: "SL1" - "Item", "SL2" - "Charge (Item)"
        // [GIVEN] Sales shipment "SS" ("SSL1", "SSL2") from "SO"
        SalesHeader[1]."Document Type" := SalesHeader[1]."Document Type"::Order;
        CreateSalesDocument(SalesHeader[1], ItemCharge);
        DocNo[1] := SalesHeader[1]."No.";
        DocNo[2] := LibrarySales.PostSalesDocument(SalesHeader[1], true, false);
        // [GIVEN] Sales return order "SRO" with 2 lines: "SRL1" - "Item", "SRL2" - "Charge (Item)"
        // [GIVEN] Return receipt "RR" ("RRL1", "RRL2") from "SRO"
        SalesHeader[2]."Document Type" := SalesHeader[2]."Document Type"::"Return Order";
        CreateSalesDocument(SalesHeader[2], ItemCharge);
        DocNo[3] := SalesHeader[2]."No.";
        DocNo[4] := LibrarySales.PostSalesDocument(SalesHeader[2], true, false);
        // [GIVEN] Mock empty "Gen. Prod. Posting Group" for "SO", "SRO", "SS", "RR"
        ClearSalesLineItemChargeGenProdPostingGroup(DocNo, ItemCharge);
        // [WHEN] Final invoice "SO" and "SRO"
        UpdateItemChargeGenProdPostingGroup(ItemCharge, SalesHeader[1]."Gen. Bus. Posting Group");
        LibrarySales.PostSalesDocument(SalesHeader[1], false, true);
        LibrarySales.PostSalesDocument(SalesHeader[2], false, true);
        // [THEN] "SO" and "SRO" posted successfully
        // [THEN] "SL2"."Gen. Prod. Posting Group" updated from "IC"
        // [THEN] "SSL2"."Gen. Prod. Posting Group" updated from "IC"        
        // [THEN] "SRL2"."Gen. Prod. Posting Group" updated from "IC"
        // [THEN] "RRL2"."Gen. Prod. Posting Group" updated from "IC"
        VerifySalesLines(DocNo[2], DocNo[4], ItemCharge."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePurchaseDocuments()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        ItemCharge: Record "Item Charge";
        DocNo: array[4] of Code[20];
    begin
        Initialize();

        // [GIVEN] Item charges "IC"
        CreateItemCharge(ItemCharge);
        // [GIVEN] Purchase order "PO" with 2 lines: "PL1" - "Item", "PL2" - "Charge (Item)"
        // [GIVEN] Purchase receipt "PR" ("PRL1", "PRL2") from "PO"
        PurchaseHeader[1]."Document Type" := PurchaseHeader[1]."Document Type"::Order;
        CreatePurchaseDocument(PurchaseHeader[1], ItemCharge);
        DocNo[1] := PurchaseHeader[1]."No.";
        DocNo[2] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);
        // [GIVEN] Purchase return order "PRO" with 2 lines: "PRL1" - "Item", "PRL2" - "Charge (Item)"
        // [GIVEN] Return shipment "RS" ("RSL1", "RSL2") from "PRO"
        PurchaseHeader[2]."Document Type" := PurchaseHeader[2]."Document Type"::"Return Order";
        CreatePurchaseDocument(PurchaseHeader[2], ItemCharge);
        DocNo[3] := PurchaseHeader[2]."No.";
        DocNo[4] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, false);
        // [GIVEN] Mock empty "Gen. Prod. Posting Group" for "PO", "PRO", "PR", "RS"
        ClearPurchaseLineItemChargeGenProdPostingGroup(DocNo, ItemCharge);
        // [WHEN] Final invoice "PO" and "PRO"
        UpdateItemChargeGenProdPostingGroup(ItemCharge, PurchaseHeader[1]."Gen. Bus. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], false, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], false, true);
        // [THEN] "PO" and "PRO" posted successfully
        // [THEN] "PL2"."Gen. Prod. Posting Group" updated from "IC"
        // [THEN] "PRL2"."Gen. Prod. Posting Group" updated from "IC"
        // [THEN] "PRL2"."Gen. Prod. Posting Group" updated from "IC"
        // [THEN] "RSL2"."Gen. Prod. Posting Group" updated from "IC"
        VerifyPurchaseLines(DocNo[2], DocNo[4], ItemCharge."Gen. Prod. Posting Group");
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateItemCharge(var ItemCharge: Record "Item Charge")
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; ItemCharge: Record "Item Charge")
    var
        SalesLine: array[2] of Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine[1].Validate("Unit Price", 1000);
        SalesLine[1].Modify();
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::"Charge (Item)", ItemCharge."No.", 1);
        SalesLine[2].Validate("Unit Price", 100);
        SalesLine[2].Modify();
        LibrarySales.CreateItemChargeAssignment(
            ItemChargeAssignmentSales, SalesLine[2], ItemCharge,
            SalesLine[1]."Document Type", SalesLine[1]."Document No.", SalesLine[1]."Line No.", SalesLine[1]."No.", 1, 100);
        ItemChargeAssignmentSales.Insert(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; ItemCharge: Record "Item Charge")
    var
        PurchaseLine: array[2] of Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine[1].Validate("Direct Unit Cost", 100);
        PurchaseLine[1].Modify();
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLine[2].Validate("Direct Unit Cost", 100);
        PurchaseLine[2].Modify();
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, PurchaseLine[2], ItemCharge,
            PurchaseLine[1]."Document Type", PurchaseLine[1]."Document No.", PurchaseLine[1]."Line No.", PurchaseLine[1]."No.", 1, 100);
        ItemChargeAssignmentPurch.Insert(true);
    end;

    local procedure ClearSalesLineItemChargeGenProdPostingGroup(DocNo: array[4] of code[20]; var ItemCharge: Record "Item Charge")
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ItemCharge."Gen. Prod. Posting Group" := '';
        ItemCharge.Modify();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocNo[1]);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.ModifyAll("Gen. Prod. Posting Group", '', false);

        SalesShipmentLine.SetRange("Document No.", DocNo[2]);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::"Charge (Item)");
        SalesShipmentLine.ModifyAll("Gen. Prod. Posting Group", '', false);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", DocNo[3]);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.ModifyAll("Gen. Prod. Posting Group", '', false);

        ReturnReceiptLine.SetRange("Document No.", DocNo[4]);
        ReturnReceiptLine.SetRange(Type, ReturnReceiptLine.Type::"Charge (Item)");
        ReturnReceiptLine.ModifyAll("Gen. Prod. Posting Group", '', false);
    end;

    local procedure ClearPurchaseLineItemChargeGenProdPostingGroup(DocNo: array[4] of code[20]; var ItemCharge: Record "Item Charge")
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ItemCharge."Gen. Prod. Posting Group" := '';
        ItemCharge.Modify();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocNo[1]);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.ModifyAll("Gen. Prod. Posting Group", '', false);

        PurchRcptLine.SetRange("Document No.", DocNo[2]);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::"Charge (Item)");
        PurchRcptLine.ModifyAll("Gen. Prod. Posting Group", '', false);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", DocNo[3]);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.ModifyAll("Gen. Prod. Posting Group", '', false);

        ReturnShipmentLine.SetRange("Document No.", DocNo[4]);
        ReturnShipmentLine.SetRange(Type, ReturnShipmentLine.Type::"Charge (Item)");
        ReturnShipmentLine.ModifyAll("Gen. Prod. Posting Group", '', false);
    end;

    local procedure UpdateItemChargeGenProdPostingGroup(var ItemCharge: Record "Item Charge"; GenBusPostingGroup: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProductPostingGroup.Code);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupInvtAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);

        ItemCharge.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        ItemCharge.Modify(false);
    end;

    local procedure VerifySalesLines(SalesShptDocNo: Code[20]; ReturnRcptDocNo: Code[20]; GenProdPostingGroupCode: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        SalesShipmentLine.SetRange("Document No.", SalesShptDocNo);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::"Charge (Item)");
        SalesShipmentLine.SetRange("Gen. Prod. Posting Group", '');
        Assert.RecordCount(SalesShipmentLine, 0);
        SalesShipmentLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Assert.RecordCount(SalesShipmentLine, 1);

        ReturnReceiptLine.SetRange("Document No.", ReturnRcptDocNo);
        ReturnReceiptLine.SetRange(Type, ReturnReceiptLine.Type::"Charge (Item)");
        ReturnReceiptLine.SetRange("Gen. Prod. Posting Group", '');
        Assert.RecordCount(ReturnReceiptLine, 0);
        ReturnReceiptLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Assert.RecordCount(ReturnReceiptLine, 1);
    end;

    local procedure VerifyPurchaseLines(PurchRcptDocNo: Code[20]; ReturnShptDocNo: Code[20]; GenProdPostingGroupCode: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        PurchRcptLine.SetRange("Document No.", PurchRcptDocNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::"Charge (Item)");
        PurchRcptLine.SetRange("Gen. Prod. Posting Group", '');
        Assert.RecordCount(PurchRcptLine, 0);
        PurchRcptLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Assert.RecordCount(PurchRcptLine, 1);

        ReturnShipmentLine.SetRange("Document No.", ReturnShptDocNo);
        ReturnShipmentLine.SetRange(Type, ReturnShipmentLine.Type::"Charge (Item)");
        ReturnShipmentLine.SetRange("Gen. Prod. Posting Group", '');
        Assert.RecordCount(ReturnShipmentLine, 0);
        ReturnShipmentLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Assert.RecordCount(ReturnShipmentLine, 1);
    end;
}