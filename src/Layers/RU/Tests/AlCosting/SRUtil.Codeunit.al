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
        GLUtil: Codeunit Codeunit103020;

    [Scope('OnPrem')]
    procedure GetSalesLineDisc(var SalesLineDisc: Record "Sales Line Discount";SalesType: Option "All Customers",Customer,"Customer Disc. Group";SalesCode: Code[20];ItemType: Option Item,"Item Disc. Group";ItemCode: Code[20];StartDate: Date;MinQty: Decimal;CurrencyCode: Code[10];UOMCode: Code[20];VarCode: Code[20]): Boolean
    begin
        WITH SalesLineDisc DO BEGIN
          SETRANGE("Sales Code",SalesCode);
          SETRANGE("Sales Type",SalesType);
          SETRANGE(Type,ItemType);
          SETRANGE(Code,ItemCode);
          SETRANGE("Starting Date",StartDate);
          SETRANGE("Currency Code",CurrencyCode);
          SETRANGE("Variant Code",VarCode);
          SETRANGE("Unit of Measure Code",UOMCode);
          SETRANGE("Minimum Quantity",MinQty);
          EXIT(FIND('-'));
        END;
    end;

    [Scope('OnPrem')]
    procedure GetSalesPrice(var SalesPrice: Record "Sales Price";SalesType: Option "All Customers",Customer,"Customer Disc. Group";SalesCode: Code[20];ItemNo: Code[20];StartDate: Date;MinQty: Decimal;CurrencyCode: Code[10];UOMCode: Code[20];VarCode: Code[20]): Boolean
    begin
        WITH SalesPrice DO BEGIN
          SETRANGE("Sales Code",SalesCode);
          SETRANGE("Sales Type",SalesType);
          SETRANGE("Item No.",ItemNo);
          SETRANGE("Starting Date",StartDate);
          SETRANGE("Currency Code",CurrencyCode);
          SETRANGE("Variant Code",VarCode);
          SETRANGE("Unit of Measure Code",UOMCode);
          SETRANGE("Minimum Quantity",MinQty);
          EXIT(FIND('-'));
        END;
    end;

    [Scope('OnPrem')]
    procedure InsertCustDiscGrp(GrpCode: Code[10])
    var
        CustDiscGrp: Record "Customer Discount Group";
    begin
        CustDiscGrp.Init();
        CustDiscGrp.VALIDATE(Code,GrpCode);
        CustDiscGrp.INSERT(TRUE);
    end;

    [Scope('OnPrem')]
    procedure InsertCustPriceGrp(GrpCode: Code[10];PriceInclVAT: Boolean;VATBusPostGrp: Code[20];AllowLineDisc: Boolean;AllowInvDisc: Boolean)
    var
        CustPriceGrp: Record "Customer Price Group";
    begin
        CustPriceGrp.Init();
        CustPriceGrp.VALIDATE(Code,GrpCode);
        CustPriceGrp.INSERT(TRUE);
        CustPriceGrp.VALIDATE("Price Includes VAT",PriceInclVAT);
        CustPriceGrp.VALIDATE("VAT Bus. Posting Gr. (Price)",VATBusPostGrp);
        CustPriceGrp.VALIDATE("Allow Line Disc.",AllowLineDisc);
        CustPriceGrp.VALIDATE("Allow Invoice Disc.",AllowInvDisc);
        CustPriceGrp.MODIFY(TRUE);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesHeader(var SalesHeader: Record "Sales Header";var SalesLine: Record "Sales Line";DocType: Option)
    begin
        CLEAR(SalesHeader);
        CLEAR(SalesLine);
        SalesHeader.Init();
        SalesHeader."Document Type" := DocType;
        SalesHeader.INSERT(TRUE);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLine(SalesHeader: Record "Sales Header";var SalesLine: Record "Sales Line")
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        GLUtil.IncrLineNo(SalesLine."Line No.");
        SalesLine.INSERT(TRUE);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLineDisc(SalesType: Option;SalesCode: Code[20];Type: Option;"Code": Code[20];StartDate: Date;EndDate: Date;MinQty: Decimal;CurrencyCode: Code[10];UOMCode: Code[20];VarCode: Code[20];LineDiscPct: Decimal)
    var
        SalesLineDisc: Record "Sales Line Discount";
    begin
        SalesLineDisc.Init();
        SalesLineDisc.VALIDATE("Sales Type",SalesType);
        SalesLineDisc.VALIDATE("Sales Code",SalesCode);
        SalesLineDisc.VALIDATE(Type,Type);
        SalesLineDisc.VALIDATE(Code,Code);
        SalesLineDisc.VALIDATE("Starting Date",StartDate);
        SalesLineDisc.VALIDATE("Minimum Quantity",MinQty);
        SalesLineDisc.VALIDATE("Currency Code",CurrencyCode);
        IF SalesLineDisc.Type = SalesLineDisc.Type::Item THEN BEGIN
          SalesLineDisc.VALIDATE("Unit of Measure Code",UOMCode);
          SalesLineDisc.VALIDATE("Variant Code",VarCode);
        END;
        SalesLineDisc.VALIDATE("Ending Date",EndDate);
        SalesLineDisc.VALIDATE("Line Discount %",LineDiscPct);
        SalesLineDisc.INSERT(TRUE);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesPrice(SalesType: Option;SalesCode: Code[20];ItemNo: Code[20];StartDate: Date;EndDate: Date;MinQty: Decimal;CurrencyCode: Code[10];UOMCode: Code[20];VarCode: Code[20];UnitPrice: Decimal)
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.Init();
        SalesPrice.VALIDATE("Sales Type",SalesType);
        SalesPrice.VALIDATE("Sales Code",SalesCode);
        SalesPrice.VALIDATE("Item No.",ItemNo);
        SalesPrice.VALIDATE("Starting Date",StartDate);
        SalesPrice.VALIDATE("Ending Date",EndDate);
        SalesPrice.VALIDATE("Minimum Quantity",MinQty);
        SalesPrice.VALIDATE("Currency Code",CurrencyCode);
        SalesPrice.VALIDATE("Unit of Measure Code",UOMCode);
        SalesPrice.VALIDATE("Variant Code",VarCode);
        SalesPrice.VALIDATE("Unit Price",UnitPrice);
        SalesPrice.INSERT(TRUE);
    end;

    [Scope('OnPrem')]
    procedure PostSales(SalesHeader: Record "Sales Header";QtyPost: Boolean;ValuePost: Boolean)
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Find();
        IF SalesHeader."Document Type" IN [SalesHeader."Document Type"::Order,SalesHeader."Document Type"::Invoice] THEN
          SalesHeader.Ship := QtyPost
        else
          SalesHeader.Receive := QtyPost;
        SalesHeader.Invoice := ValuePost;
        SalesPost.RUN(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure InsertItemChargeAssgntSale(SalesLineItemCharge: Record "Sales Line";var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";IsFirstLine: Boolean;ApplToDocType: Option;ApplToDocNo: Code[20];ApplToDocLineNo: Integer)
    var
        SalesLineItem: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        IF IsFirstLine THEN
          CLEAR(ItemChargeAssgntSales);

        WITH ItemChargeAssgntSales DO BEGIN
          Init();
          "Document Type" := SalesLineItemCharge."Document Type";
          "Document No." := SalesLineItemCharge."Document No.";
          "Document Line No." := SalesLineItemCharge."Line No.";
          GLUtil.IncrLineNo("Line No.");
          "Item Charge No." := SalesLineItemCharge."No.";
          "Applies-to Doc. Type" := ApplToDocType;
          "Applies-to Doc. No." := ApplToDocNo;
          "Applies-to Doc. Line No." := ApplToDocLineNo;
          "Unit Cost" := SalesLineItemCharge."Unit Price";

          CASE "Applies-to Doc. Type" OF
            "Applies-to Doc. Type"::Quote:
              BEGIN
                SalesLineItem.GET(
                  SalesLineItem."Document Type"::Quote,"Applies-to Doc. No.","Applies-to Doc. Line No.");
                "Item No." := SalesLineItem."No.";
              END;
            "Applies-to Doc. Type"::Order:
              BEGIN
                SalesLineItem.GET(
                  SalesLineItem."Document Type"::Order,"Applies-to Doc. No.","Applies-to Doc. Line No.");
                "Item No." := SalesLineItem."No.";
              END;
            "Applies-to Doc. Type"::Invoice:
              BEGIN
                SalesLineItem.GET(
                  SalesLineItem."Document Type"::Invoice,"Applies-to Doc. No.","Applies-to Doc. Line No.");
                "Item No." := SalesLineItem."No.";
              END;
            "Applies-to Doc. Type"::"Credit Memo":
              BEGIN
                SalesLineItem.GET(
                  SalesLineItem."Document Type"::"Credit Memo","Applies-to Doc. No.","Applies-to Doc. Line No.");
                "Item No." := SalesLineItem."No.";
              END;
            "Applies-to Doc. Type"::"Blanket Order":
              BEGIN
                SalesLineItem.GET(
                  SalesLineItem."Document Type"::"Blanket Order","Applies-to Doc. No.","Applies-to Doc. Line No.");
                "Item No." := SalesLineItem."No.";
              END;
            "Applies-to Doc. Type"::"Return Order":
              BEGIN
                SalesLineItem.GET(
                  SalesLineItem."Document Type"::"Return Order","Applies-to Doc. No.","Applies-to Doc. Line No.");
                "Item No." := SalesLineItem."No.";
              END;
            "Applies-to Doc. Type"::Shipment:
              BEGIN
                SalesShptLine.GET("Applies-to Doc. No.","Applies-to Doc. Line No.");
                "Item No." := SalesShptLine."No.";
              END;
            "Applies-to Doc. Type"::"Return Receipt":
              BEGIN
                ReturnRcptLine.GET("Applies-to Doc. No.","Applies-to Doc. Line No.");
                "Item No." := ReturnRcptLine."No.";
              END;
          END;

          Insert();
        END;
    end;

    [Scope('OnPrem')]
    procedure ReserveSalesLnAgainstPurchLn(SalesLine: Record "Sales Line";PurchLine: Record "Purchase Line";QtyToReserve: Decimal;QtyBaseToReserve: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservMgt: Codeunit "Reservation Management";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
    begin
        ReservMgt.SetPurchLine(PurchLine);
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line",
          PurchLine."Document Type",
          PurchLine."Document No.",
          '',
          0,PurchLine."Line No.",
          PurchLine."Variant Code",
          PurchLine."Location Code",
          '','','',
          PurchLine."Qty. per Unit of Measure");
        SalesLineReserve.CreateReservationSetFrom(TrackingSpecification);
        SalesLineReserve.CreateReservation(SalesLine,'',PurchLine."Expected Receipt Date",QtyToReserve,QtyBaseToReserve,'','','');
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesLineDisc(var SalesLineDisc: Record "Sales Line Discount";SalesType: Option "All Customers",Customer,"Customer Disc. Group";SalesCode: Code[20];ItemType: Option Item,"Item Disc. Group";ItemCode: Code[20];StartDate: Date;EndDate: Date;MinQty: Decimal;CurrencyCode: Code[10];UOMCode: Code[20];VarCode: Code[20];LineDiscPct: Decimal)
    begin
        WITH SalesLineDisc DO BEGIN
          IF ItemType <> Type THEN
            VALIDATE(Type,ItemType);
          IF ItemCode <> Code THEN
            VALIDATE(Code,ItemCode);
          IF SalesType <> "Sales Type" THEN
            VALIDATE("Sales Type",SalesType);
          IF SalesCode <> "Sales Code" THEN
            VALIDATE("Sales Code",SalesCode);
          IF StartDate <> "Starting Date" THEN
            VALIDATE("Starting Date",StartDate);
          IF CurrencyCode <> "Currency Code" THEN
            VALIDATE("Currency Code",CurrencyCode);
          IF VarCode <> "Variant Code" THEN
            VALIDATE("Variant Code",VarCode);
          IF UOMCode <> "Unit of Measure Code" THEN
            VALIDATE("Unit of Measure Code",UOMCode);
          IF MinQty <> "Minimum Quantity" THEN
            VALIDATE("Minimum Quantity",MinQty);
          IF EndDate <> "Ending Date" THEN
            VALIDATE("Ending Date",EndDate);
          IF LineDiscPct <> "Line Discount %" THEN
            VALIDATE("Line Discount %",LineDiscPct);
          MODIFY(TRUE)
        END;
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesPrice(var SalesPrice: Record "Sales Price";SalesType: Option "All Customers",Customer,"Customer Disc. Group";SalesCode: Code[20];ItemNo: Code[20];StartDate: Date;EndDate: Date;MinQty: Decimal;CurrencyCode: Code[10];UOMCode: Code[20];VarCode: Code[20];UnitPrice: Decimal)
    begin
        WITH SalesPrice DO BEGIN
          IF SalesType <> "Sales Type" THEN
            VALIDATE("Sales Type",SalesType);
          IF SalesCode <> "Sales Code" THEN
            VALIDATE("Sales Code",SalesCode);
          IF ItemNo <> "Item No." THEN
            VALIDATE("Item No.",ItemNo);
          IF StartDate <> "Starting Date" THEN
            VALIDATE("Starting Date",StartDate);
          IF CurrencyCode <> "Currency Code" THEN
            VALIDATE("Currency Code",CurrencyCode);
          IF VarCode <> "Variant Code" THEN
            VALIDATE("Variant Code",VarCode);
          IF UOMCode <> "Unit of Measure Code" THEN
            VALIDATE("Unit of Measure Code",UOMCode);
          IF MinQty <> "Minimum Quantity" THEN
            VALIDATE("Minimum Quantity",MinQty);
          IF EndDate <> "Ending Date" THEN
            VALIDATE("Ending Date",EndDate);
          IF UnitPrice <> "Unit Price" THEN
            VALIDATE("Unit Price",UnitPrice);
          MODIFY(TRUE)
        END;
    end;
}

