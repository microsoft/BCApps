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
#if not CLEAN25
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
#endif

#if not CLEAN25
    [Scope('OnPrem')]
    procedure GetSalesLineDisc(var SalesLineDisc: Record "Sales Line Discount"; SalesType: Option "All Customers",Customer,"Customer Disc. Group"; SalesCode: Code[20]; ItemType: Option Item,"Item Disc. Group"; ItemCode: Code[20]; StartDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]): Boolean
    begin
        SalesLineDisc.SetRange("Sales Code", SalesCode);
        SalesLineDisc.SetRange("Sales Type", SalesType);
        SalesLineDisc.SetRange(Type, ItemType);
        SalesLineDisc.SetRange(Code, ItemCode);
        SalesLineDisc.SetRange("Starting Date", StartDate);
        SalesLineDisc.SetRange("Currency Code", CurrencyCode);
        SalesLineDisc.SetRange("Variant Code", VarCode);
        SalesLineDisc.SetRange("Unit of Measure Code", UOMCode);
        SalesLineDisc.SetRange("Minimum Quantity", MinQty);
        exit(SalesLineDisc.Find('-'));
    end;

    [Scope('OnPrem')]
    procedure GetSalesPrice(var SalesPrice: Record "Sales Price"; SalesType: Option "All Customers",Customer,"Customer Disc. Group"; SalesCode: Code[20]; ItemNo: Code[20]; StartDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]): Boolean
    begin
        SalesPrice.SetRange("Sales Code", SalesCode);
        SalesPrice.SetRange("Sales Type", SalesType);
        SalesPrice.SetRange("Item No.", ItemNo);
        SalesPrice.SetRange("Starting Date", StartDate);
        SalesPrice.SetRange("Currency Code", CurrencyCode);
        SalesPrice.SetRange("Variant Code", VarCode);
        SalesPrice.SetRange("Unit of Measure Code", UOMCode);
        SalesPrice.SetRange("Minimum Quantity", MinQty);
        exit(SalesPrice.Find('-'));
    end;
#endif

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
#if not CLEAN25
        SalesLineDisc: Record "Sales Line Discount";
#endif
        PriceListLine: Record "Price List Line";
    begin
#if not CLEAN25
        SalesLineDisc.Init();
        SalesLineDisc.Validate("Sales Type", SalesType);
        SalesLineDisc.Validate("Sales Code", SalesCode);
        SalesLineDisc.Validate(Type, Type);
        SalesLineDisc.Validate(Code, Code);
        SalesLineDisc.Validate("Starting Date", StartDate);
        SalesLineDisc.Validate("Minimum Quantity", MinQty);
        SalesLineDisc.Validate("Currency Code", CurrencyCode);
        if SalesLineDisc.Type = SalesLineDisc.Type::Item then begin
            SalesLineDisc.Validate("Unit of Measure Code", UOMCode);
            SalesLineDisc.Validate("Variant Code", VarCode);
        end;
        SalesLineDisc.Validate("Ending Date", EndDate);
        SalesLineDisc.Validate("Line Discount %", LineDiscPct);
        SalesLineDisc.Insert(true);

        SalesLineDisc.SetRecFilter();
        CopyFromToPriceListLine.CopyFrom(SalesLineDisc, PriceListLine);
#else
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
#endif
    end;

    [Scope('OnPrem')]
    procedure InsertSalesPrice(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; UnitPrice: Decimal)
    var
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#endif
        PriceListLine: Record "Price List Line";
    begin
#if not CLEAN25
        SalesPrice.Init();
        SalesPrice.Validate("Sales Type", SalesType);
        SalesPrice.Validate("Sales Code", SalesCode);
        SalesPrice.Validate("Item No.", ItemNo);
        SalesPrice.Validate("Starting Date", StartDate);
        SalesPrice.Validate("Ending Date", EndDate);
        SalesPrice.Validate("Minimum Quantity", MinQty);
        SalesPrice.Validate("Currency Code", CurrencyCode);
        SalesPrice.Validate("Unit of Measure Code", UOMCode);
        SalesPrice.Validate("Variant Code", VarCode);
        SalesPrice.Validate("Unit Price", UnitPrice);
        SalesPrice.Insert(true);

        SalesPrice.SetRecFilter();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
#else
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
#endif
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

#if not CLEAN25
    [Scope('OnPrem')]
    procedure UpdateSalesLineDisc(var SalesLineDisc: Record "Sales Line Discount"; SalesType: Option "All Customers",Customer,"Customer Disc. Group"; SalesCode: Code[20]; ItemType: Enum "Sales Line Discount Type"; ItemCode: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; LineDiscPct: Decimal)
    begin
        if ItemType <> SalesLineDisc.Type then
            SalesLineDisc.Validate(Type, ItemType);
        if ItemCode <> SalesLineDisc.Code then
            SalesLineDisc.Validate(Code, ItemCode);
        if SalesType <> SalesLineDisc."Sales Type" then
            SalesLineDisc.Validate("Sales Type", SalesType);
        if SalesCode <> SalesLineDisc."Sales Code" then
            SalesLineDisc.Validate("Sales Code", SalesCode);
        if StartDate <> SalesLineDisc."Starting Date" then
            SalesLineDisc.Validate("Starting Date", StartDate);
        if CurrencyCode <> SalesLineDisc."Currency Code" then
            SalesLineDisc.Validate("Currency Code", CurrencyCode);
        if VarCode <> SalesLineDisc."Variant Code" then
            SalesLineDisc.Validate("Variant Code", VarCode);
        if UOMCode <> SalesLineDisc."Unit of Measure Code" then
            SalesLineDisc.Validate("Unit of Measure Code", UOMCode);
        if MinQty <> SalesLineDisc."Minimum Quantity" then
            SalesLineDisc.Validate("Minimum Quantity", MinQty);
        if EndDate <> SalesLineDisc."Ending Date" then
            SalesLineDisc.Validate("Ending Date", EndDate);
        if LineDiscPct <> SalesLineDisc."Line Discount %" then
            SalesLineDisc.Validate("Line Discount %", LineDiscPct);
        SalesLineDisc.Modify(true)
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesPrice(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; UnitPrice: Decimal)
    begin
        if SalesType <> SalesPrice."Sales Type" then
            SalesPrice.Validate("Sales Type", SalesType);
        if SalesCode <> SalesPrice."Sales Code" then
            SalesPrice.Validate("Sales Code", SalesCode);
        if ItemNo <> SalesPrice."Item No." then
            SalesPrice.Validate("Item No.", ItemNo);
        if StartDate <> SalesPrice."Starting Date" then
            SalesPrice.Validate("Starting Date", StartDate);
        if CurrencyCode <> SalesPrice."Currency Code" then
            SalesPrice.Validate("Currency Code", CurrencyCode);
        if VarCode <> SalesPrice."Variant Code" then
            SalesPrice.Validate("Variant Code", VarCode);
        if UOMCode <> SalesPrice."Unit of Measure Code" then
            SalesPrice.Validate("Unit of Measure Code", UOMCode);
        if MinQty <> SalesPrice."Minimum Quantity" then
            SalesPrice.Validate("Minimum Quantity", MinQty);
        if EndDate <> SalesPrice."Ending Date" then
            SalesPrice.Validate("Ending Date", EndDate);
        if UnitPrice <> SalesPrice."Unit Price" then
            SalesPrice.Validate("Unit Price", UnitPrice);
        SalesPrice.Modify(true)
    end;
#endif
}

