codeunit 103025 PPUtil
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    var
        GLUtil: Codeunit GLUtil;
#if not CLEAN25
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
#endif

    [Scope('OnPrem')]
    procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type")
    begin
        Clear(PurchHeader);
        Clear(PurchLine);
        PurchHeader.Init();
        PurchHeader."Document Type" := DocType;
        PurchHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    begin
        PurchLine.Init();
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        GLUtil.IncrLineNo(PurchLine."Line No.");
        PurchLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertItemChargeAssgntPurch(PurchLineItemCharge: Record "Purchase Line"; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; IsFirstLine: Boolean; ApplToDocType: Enum "Purchase Applies-to Document Type"; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer)
    var
        PurchLineItem: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesShptLine: Record "Sales Shipment Line";
        TransRcptLine: Record "Transfer Receipt Line";
        ReturnShptLine: Record "Return Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        if IsFirstLine then
            Clear(ItemChargeAssgntPurch);

        ItemChargeAssgntPurch.Init();
        ItemChargeAssgntPurch."Document Type" := PurchLineItemCharge."Document Type";
        ItemChargeAssgntPurch."Document No." := PurchLineItemCharge."Document No.";
        ItemChargeAssgntPurch."Document Line No." := PurchLineItemCharge."Line No.";
        GLUtil.IncrLineNo(ItemChargeAssgntPurch."Line No.");
        ItemChargeAssgntPurch."Item Charge No." := PurchLineItemCharge."No.";
        ItemChargeAssgntPurch."Applies-to Doc. Type" := ApplToDocType;
        ItemChargeAssgntPurch."Applies-to Doc. No." := ApplToDocNo;
        ItemChargeAssgntPurch."Applies-to Doc. Line No." := ApplToDocLineNo;
        ItemChargeAssgntPurch."Unit Cost" := PurchLineItemCharge."Direct Unit Cost";

        case ItemChargeAssgntPurch."Applies-to Doc. Type" of
            ItemChargeAssgntPurch."Applies-to Doc. Type"::Quote:
                begin
                    PurchLineItem.Get(
                      PurchLineItem."Document Type"::Quote, ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := PurchLineItem."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::Order:
                begin
                    PurchLineItem.Get(
                      PurchLineItem."Document Type"::Order, ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := PurchLineItem."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::Invoice:
                begin
                    PurchLineItem.Get(
                      PurchLineItem."Document Type"::Invoice, ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := PurchLineItem."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::"Credit Memo":
                begin
                    PurchLineItem.Get(
                      PurchLineItem."Document Type"::"Credit Memo", ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := PurchLineItem."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::"Blanket Order":
                begin
                    PurchLineItem.Get(
                      PurchLineItem."Document Type"::"Blanket Order", ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := PurchLineItem."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Order":
                begin
                    PurchLineItem.Get(
                      PurchLineItem."Document Type"::"Return Order", ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := PurchLineItem."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt:
                begin
                    PurchRcptLine.Get(ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := PurchRcptLine."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt":
                begin
                    TransRcptLine.Get(ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := TransRcptLine."Item No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment":
                begin
                    ReturnShptLine.Get(ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := ReturnShptLine."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment":
                begin
                    SalesShptLine.Get(ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := SalesShptLine."No.";
                end;
            ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt":
                begin
                    ReturnRcptLine.Get(ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    ItemChargeAssgntPurch."Item No." := ReturnRcptLine."No.";
                end;
        end;

        ItemChargeAssgntPurch.Insert();
    end;

#if CLEAN25
    procedure AllowEditingActivePrice(Allow: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Editing Active Price" := Allow;
        PurchasesPayablesSetup.Modify();
    end;
#endif

    [Scope('OnPrem')]
    procedure InsertPurchLineDisc(VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; LineDiscPct: Decimal)
    var
#if not CLEAN25
        PurchLineDisc: Record "Purchase Line Discount";
#endif
        PriceListLine: Record "Price List Line";
    begin
#if not CLEAN25
        PurchLineDisc.Init();
        PurchLineDisc.Validate("Vendor No.", VendorNo);
        PurchLineDisc.Validate("Item No.", ItemNo);
        PurchLineDisc.Validate("Starting Date", StartDate);
        PurchLineDisc.Validate("Currency Code", CurrencyCode);
        if VarCode <> '' then
            PurchLineDisc.Validate("Variant Code", VarCode);
        if UOMCode <> '' then
            PurchLineDisc.Validate("Unit of Measure Code", UOMCode);
        PurchLineDisc.Validate("Minimum Quantity", MinQty);
        PurchLineDisc.Insert(true);
        PurchLineDisc.Validate("Ending Date", EndDate);
        PurchLineDisc.Validate("Line Discount %", LineDiscPct);
        PurchLineDisc.Modify(true);

        PurchLineDisc.SetRecFilter();
        CopyFromToPriceListLine.CopyFrom(PurchLineDisc, PriceListLine);
#else
        PriceListLine.Init();
        PriceListLine.Validate("Source Type", "Price Source Type"::Vendor);
        PriceListLine.Validate("Source No.", VendorNo);
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", ItemNo);
        PriceListLine.Validate("Starting Date", StartDate);
        PriceListLine.Validate("Currency Code", CurrencyCode);
        if VarCode <> '' then
            PriceListLine.Validate("Variant Code", VarCode);
        PriceListLine.Validate("Unit of Measure Code", UOMCode);
        PriceListLine.Validate("Minimum Quantity", MinQty);
        PriceListLine.Validate("Ending Date", EndDate);
        PriceListLine.Validate("Line Discount %", LineDiscPct);
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Insert(true);
#endif
    end;

    [Scope('OnPrem')]
    procedure PostPurchase(PurchHeader: Record "Purchase Header"; QtyPost: Boolean; ValuePost: Boolean)
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchHeader.Find();
        if PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice] then
            PurchHeader.Receive := QtyPost
        else
            PurchHeader.Ship := QtyPost;
        PurchHeader.Invoice := ValuePost;
        PurchPost.Run(PurchHeader);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchPrice(VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; DirectUnitCost: Decimal)
    var
#if not CLEAN25
        PurchPrice: Record "Purchase Price";
#endif
        PriceListLine: Record "Price List Line";
    begin
#if not CLEAN25
        PurchPrice.Init();
        PurchPrice.Validate("Vendor No.", VendorNo);
        PurchPrice.Validate("Item No.", ItemNo);
        PurchPrice.Validate("Starting Date", StartDate);
        PurchPrice.Validate("Ending Date", EndDate);
        PurchPrice.Validate("Minimum Quantity", MinQty);
        PurchPrice.Validate("Currency Code", CurrencyCode);
        PurchPrice.Validate("Unit of Measure Code", UOMCode);
        PurchPrice.Validate("Variant Code", VarCode);
        PurchPrice.Insert(true);
        PurchPrice.Validate("Direct Unit Cost", DirectUnitCost);
        PurchPrice.Modify(true);

        PurchPrice.SetRecFilter();
        CopyFromToPriceListLine.CopyFrom(PurchPrice, PriceListLine);
#else
        PriceListLine.Init();
        PriceListLine.Validate("Source Type", "Price Source Type"::Vendor);
        PriceListLine.Validate("Source No.", VendorNo);
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", ItemNo);
        PriceListLine.Validate("Variant Code", VarCode);
        PriceListLine.Validate("Starting Date", StartDate);
        PriceListLine.Validate("Ending Date", EndDate);
        PriceListLine.Validate("Minimum Quantity", MinQty);
        PriceListLine.Validate("Currency Code", CurrencyCode);
        PriceListLine.Validate("Unit of Measure Code", UOMCode);
        PriceListLine.Validate("Direct Unit Cost", DirectUnitCost);
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Insert(true);
#endif
    end;
}

