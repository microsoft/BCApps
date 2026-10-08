codeunit 103023 SRUtil
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


    [Scope('OnPrem')]
    procedure InsertCustDiscGrp(GrpCode: Code[10])
    var
        CustDiscGrp: Record "Customer Discount Group";
    begin
        CustDiscGrp.Init();
        CustDiscGrp.Validate(Code, GrpCode);
        if CustDiscGrp.Insert(true) then;
    end;

    [Scope('OnPrem')]
    procedure InsertCustPriceGrp(GrpCode: Code[10]; PriceInclVAT: Boolean; VATBusPostGrp: Code[20]; AllowLineDisc: Boolean; AllowInvDisc: Boolean)
    var
        CustPriceGrp: Record "Customer Price Group";
    begin
        CustPriceGrp.Init();
        CustPriceGrp.Validate(Code, GrpCode);
        CustPriceGrp.Insert(true);
        CustPriceGrp.Validate("Price Includes VAT", PriceInclVAT);
        CustPriceGrp.Validate("VAT Bus. Posting Gr. (Price)", VATBusPostGrp);
        CustPriceGrp.Validate("Allow Line Disc.", AllowLineDisc);
        CustPriceGrp.Validate("Allow Invoice Disc.", AllowInvDisc);
        CustPriceGrp.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type")
    begin
        Clear(SalesHeader);
        Clear(SalesLine);
        SalesHeader.Init();
        SalesHeader."Document Type" := DocType;
        SalesHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        GLUtil.IncrLineNo(SalesLine."Line No.");
        SalesLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLineDisc(SalesType: Option; SalesCode: Code[20]; Type: Enum "Sales Line Discount Type"; "Code": Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; LineDiscPct: Decimal)
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.Init();
        PriceListLine.Validate("Asset Type", Type.AsInteger());
        PriceListLine.Validate("Asset No.", Code);
        PriceListLine.Validate("Source Type", SalesType);
        PriceListLine.Validate("Source No.", SalesCode);
        PriceListLine.Validate("Starting Date", StartDate);
        PriceListLine.Validate("Minimum Quantity", MinQty);
        PriceListLine.Validate("Currency Code", CurrencyCode);
        if PriceListLine."Asset Type" = PriceListLine."Asset Type"::Item then begin
            PriceListLine.Validate("Variant Code", VarCode);
            PriceListLine.Validate("Unit of Measure Code", UOMCode);
        end;
        PriceListLine.Validate("Ending Date", EndDate);
        PriceListLine.Validate("Line Discount %", LineDiscPct);
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesPrice(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; UnitPrice: Decimal)
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.Init();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", ItemNo);
        PriceListLine.Validate("Variant Code", VarCode);
        PriceListLine.Validate("Source Type", SalesType.AsInteger());
        PriceListLine.Validate("Source No.", SalesCode);
        PriceListLine.Validate("Starting Date", StartDate);
        PriceListLine.Validate("Ending Date", EndDate);
        PriceListLine.Validate("Currency Code", CurrencyCode);
        PriceListLine.Validate("Unit of Measure Code", UOMCode);
        PriceListLine.Validate("Minimum Quantity", MinQty);
        PriceListLine.Validate("Unit Price", UnitPrice);
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        PriceListLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure PostSales(SalesHeader: Record "Sales Header"; QtyPost: Boolean; ValuePost: Boolean)
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Find();
        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice] then
            SalesHeader.Ship := QtyPost
        else
            SalesHeader.Receive := QtyPost;
        SalesHeader.Invoice := ValuePost;
        SalesPost.Run(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure InsertItemChargeAssgntSale(SalesLineItemCharge: Record "Sales Line"; var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; IsFirstLine: Boolean; ApplToDocType: Enum "Sales Applies-to Document Type"; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer)
    var
        SalesLineItem: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        if IsFirstLine then
            Clear(ItemChargeAssgntSales);

        ItemChargeAssgntSales.Init();
        ItemChargeAssgntSales."Document Type" := SalesLineItemCharge."Document Type";
        ItemChargeAssgntSales."Document No." := SalesLineItemCharge."Document No.";
        ItemChargeAssgntSales."Document Line No." := SalesLineItemCharge."Line No.";
        GLUtil.IncrLineNo(ItemChargeAssgntSales."Line No.");
        ItemChargeAssgntSales."Item Charge No." := SalesLineItemCharge."No.";
        ItemChargeAssgntSales."Applies-to Doc. Type" := ApplToDocType;
        ItemChargeAssgntSales."Applies-to Doc. No." := ApplToDocNo;
        ItemChargeAssgntSales."Applies-to Doc. Line No." := ApplToDocLineNo;
        ItemChargeAssgntSales."Unit Cost" := SalesLineItemCharge."Unit Price";

        case ItemChargeAssgntSales."Applies-to Doc. Type" of
            ItemChargeAssgntSales."Applies-to Doc. Type"::Quote:
                begin
                    SalesLineItem.Get(
                      SalesLineItem."Document Type"::Quote, ItemChargeAssgntSales."Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                    ItemChargeAssgntSales."Item No." := SalesLineItem."No.";
                end;
            ItemChargeAssgntSales."Applies-to Doc. Type"::Order:
                begin
                    SalesLineItem.Get(
                      SalesLineItem."Document Type"::Order, ItemChargeAssgntSales."Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                    ItemChargeAssgntSales."Item No." := SalesLineItem."No.";
                end;
            ItemChargeAssgntSales."Applies-to Doc. Type"::Invoice:
                begin
                    SalesLineItem.Get(
                      SalesLineItem."Document Type"::Invoice, ItemChargeAssgntSales."Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                    ItemChargeAssgntSales."Item No." := SalesLineItem."No.";
                end;
            ItemChargeAssgntSales."Applies-to Doc. Type"::"Credit Memo":
                begin
                    SalesLineItem.Get(
                      SalesLineItem."Document Type"::"Credit Memo", ItemChargeAssgntSales."Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                    ItemChargeAssgntSales."Item No." := SalesLineItem."No.";
                end;
            ItemChargeAssgntSales."Applies-to Doc. Type"::"Blanket Order":
                begin
                    SalesLineItem.Get(
                      SalesLineItem."Document Type"::"Blanket Order", ItemChargeAssgntSales."Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                    ItemChargeAssgntSales."Item No." := SalesLineItem."No.";
                end;
            ItemChargeAssgntSales."Applies-to Doc. Type"::"Return Order":
                begin
                    SalesLineItem.Get(
                      SalesLineItem."Document Type"::"Return Order", ItemChargeAssgntSales."Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                    ItemChargeAssgntSales."Item No." := SalesLineItem."No.";
                end;
            ItemChargeAssgntSales."Applies-to Doc. Type"::Shipment:
                begin
                    SalesShptLine.Get(ItemChargeAssgntSales."Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                    ItemChargeAssgntSales."Item No." := SalesShptLine."No.";
                end;
            ItemChargeAssgntSales."Applies-to Doc. Type"::"Return Receipt":
                begin
                    ReturnRcptLine.Get(ItemChargeAssgntSales."Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                    ItemChargeAssgntSales."Item No." := ReturnRcptLine."No.";
                end;
        end;

        ItemChargeAssgntSales.Insert();
    end;

    [Scope('OnPrem')]
    procedure ReserveSalesLnAgainstPurchLn(SalesLine: Record "Sales Line"; PurchLine: Record "Purchase Line"; QtyToReserve: Decimal; QtyBaseToReserve: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        DummyReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        ReservMgt.SetReservSource(PurchLine);
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        SalesLineReserve.CreateReservationSetFrom(TrackingSpecification);
        SalesLineReserve.CreateReservation(
            SalesLine, '', PurchLine."Expected Receipt Date", QtyToReserve, QtyBaseToReserve, DummyReservEntry);
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesLineDisc(var PriceListLine: Record "Price List Line"; SalesType: Option; SalesCode: Code[20]; ItemType: Option; ItemCode: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; LineDiscPct: Decimal)
    begin
        if ItemType <> PriceListLine."Asset Type".AsInteger() then
            PriceListLine.Validate("Asset Type", ItemType);
        if ItemCode <> PriceListLine."Asset No." then
            PriceListLine.Validate("Asset No.", ItemCode);
        if SalesType <> PriceListLine."Source Type".AsInteger() then
            PriceListLine.Validate("Source Type", SalesType);
        if SalesCode <> PriceListLine."Source No." then
            PriceListLine.Validate("Source No.", SalesCode);
        if StartDate <> PriceListLine."Starting Date" then
            PriceListLine.Validate("Starting Date", StartDate);
        if CurrencyCode <> PriceListLine."Currency Code" then
            PriceListLine.Validate("Currency Code", CurrencyCode);
        if VarCode <> PriceListLine."Variant Code" then
            PriceListLine.Validate("Variant Code", VarCode);
        if UOMCode <> PriceListLine."Unit of Measure Code" then
            PriceListLine.Validate("Unit of Measure Code", UOMCode);
        if MinQty <> PriceListLine."Minimum Quantity" then
            PriceListLine.Validate("Minimum Quantity", MinQty);
        if EndDate <> PriceListLine."Ending Date" then
            PriceListLine.Validate("Ending Date", EndDate);
        if LineDiscPct <> PriceListLine."Line Discount %" then
            PriceListLine.Validate("Line Discount %", LineDiscPct);
        PriceListLine.Modify(true)
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesPrice(var PriceListLine: Record "Price List Line"; SalesType: Option; SalesCode: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; UnitPrice: Decimal)
    begin
        if SalesType <> PriceListLine."Source Type".AsInteger() then
            PriceListLine.Validate("Source Type", SalesType);
        if SalesCode <> PriceListLine."Source No." then
            PriceListLine.Validate("Source No.", SalesCode);
        if ItemNo <> PriceListLine."Asset No." then
            PriceListLine.Validate("Asset No.", ItemNo);
        if StartDate <> PriceListLine."Starting Date" then
            PriceListLine.Validate("Starting Date", StartDate);
        if CurrencyCode <> PriceListLine."Currency Code" then
            PriceListLine.Validate("Currency Code", CurrencyCode);
        if VarCode <> PriceListLine."Variant Code" then
            PriceListLine.Validate("Variant Code", VarCode);
        if UOMCode <> PriceListLine."Unit of Measure Code" then
            PriceListLine.Validate("Unit of Measure Code", UOMCode);
        if MinQty <> PriceListLine."Minimum Quantity" then
            PriceListLine.Validate("Minimum Quantity", MinQty);
        if EndDate <> PriceListLine."Ending Date" then
            PriceListLine.Validate("Ending Date", EndDate);
        if UnitPrice <> PriceListLine."Unit Price" then
            PriceListLine.Validate("Unit Price", UnitPrice);
        PriceListLine.Modify(true)
    end;

}
