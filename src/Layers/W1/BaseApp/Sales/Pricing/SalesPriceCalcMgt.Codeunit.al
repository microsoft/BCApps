// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;

codeunit 7000 "Sales Price Calc. Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        ResPrice: Record "Resource Price";
        Res: Record Resource;
        Currency: Record Currency;
        TempSalesPrice: Record "Sales Price" temporary;
        TempSalesLineDisc: Record "Sales Line Discount" temporary;
        LineDiscPerCent: Decimal;
        Qty: Decimal;
        AllowLineDisc: Boolean;
        AllowInvDisc: Boolean;
        VATPerCent: Decimal;
        PricesInclVAT: Boolean;
        VATCalcType: Option "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        VATBusPostingGr: Code[20];
        QtyPerUOM: Decimal;
        PricesInCurrency: Boolean;
        CurrencyFactor: Decimal;
        ExchRateDate: Date;
        FoundSalesPrice: Boolean;
        HideResUnitPriceMessage: Boolean;
        DateCaption: Text[30];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 is less than %2 in the %3.';
        Text010: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        Text018: Label '%1 %2 is greater than %3 and was adjusted to %4.';
        Text001: Label 'The %1 in the %2 must be same as in the %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TempTableErr: Label 'The table passed as a parameter must be temporary.';

    procedure FindSalesLinePrice(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindSalesLinePrice(SalesLine, SalesHeader, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        SetCurrency(SalesHeader."Currency Code", SalesHeader."Currency Factor", SalesHeaderExchDate(SalesHeader));
        SetVAT(SalesHeader."Prices Including VAT", SalesLine.GetVATPct(), SalesLine."VAT Calculation Type".AsInteger(), SalesLine."VAT Bus. Posting Group");
        SetUoM(Abs(SalesLine.Quantity), SalesLine."Qty. per Unit of Measure");
        SetLineDisc(SalesLine."Line Discount %", SalesLine."Allow Line Disc.", SalesLine."Allow Invoice Disc.");
        OnFindSalesLinePriceOnAfterSetLineDisc(SalesLine);

        SalesLine.TestField("Qty. per Unit of Measure");
        if PricesInCurrency then
            SalesHeader.TestField("Currency Factor");

        case SalesLine.Type of
            SalesLine.Type::Item:
                begin
                    Item.Get(SalesLine."No.");
                    SalesLinePriceExists(SalesHeader, SalesLine, false);
                    OnFindSalesLinePriceOnCalcBestUnitPrice(SalesLine, TempSalesPrice);
                    CalcBestUnitPrice(TempSalesPrice);
                    OnAfterFindSalesLineItemPrice(SalesLine, TempSalesPrice, FoundSalesPrice, CalledByFieldNo);
                    if FoundSalesPrice or
                       not ((CalledByFieldNo = SalesLine.FieldNo(Quantity)) or
                            (CalledByFieldNo = SalesLine.FieldNo("Variant Code")))
                    then begin
                        SalesLine."Allow Line Disc." := TempSalesPrice."Allow Line Disc.";
                        SalesLine."Allow Invoice Disc." := TempSalesPrice."Allow Invoice Disc.";
                        SalesLine."Unit Price" := TempSalesPrice."Unit Price";
                        OnFindSalesLinePriceOnItemTypeOnAfterSetUnitPrice(SalesHeader, SalesLine, TempSalesPrice, CalledByFieldNo, FoundSalesPrice);
                    end;
                    if not SalesLine."Allow Line Disc." then
                        SalesLine."Line Discount %" := 0;
                end;
            SalesLine.Type::Resource:
                begin
                    SetResPrice(SalesLine."No.", SalesLine."Work Type Code", SalesLine."Currency Code");
                    OnFindSalesLinePriceOnAfterSetResPrice(SalesLine, ResPrice);
                    CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResPrice);
                    OnAfterFindSalesLineResPrice(SalesLine, ResPrice, CalledByFieldNo);
                    if not (CalledByFieldNo = SalesLine.FieldNo(Quantity)) then begin
                        ConvertPriceToVAT(false, '', '', ResPrice."Unit Price");
                        ConvertPriceLCYToFCY(ResPrice."Currency Code", ResPrice."Unit Price");
                        SalesLine."Unit Price" := ResPrice."Unit Price" * SalesLine."Qty. per Unit of Measure";
                    end;
                end;
        end;
        OnAfterFindSalesLinePrice(SalesLine, SalesHeader, TempSalesPrice, ResPrice, CalledByFieldNo, FoundSalesPrice);
    end;

    procedure FindItemJnlLinePrice(var ItemJnlLine: Record "Item Journal Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemJnlLinePrice(ItemJnlLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        SetCurrency('', 0, 0D);
        SetVAT(false, 0, 0, '');
        SetUoM(Abs(ItemJnlLine.Quantity), ItemJnlLine."Qty. per Unit of Measure");
        ItemJnlLine.TestField("Qty. per Unit of Measure");
        Item.Get(ItemJnlLine."Item No.");

        FindSalesPrice(
          TempSalesPrice, '', '', '', '', ItemJnlLine."Item No.", ItemJnlLine."Variant Code",
          ItemJnlLine."Unit of Measure Code", '', ItemJnlLine."Posting Date", false);
        CalcBestUnitPrice(TempSalesPrice);
        if FoundSalesPrice or
           not ((CalledByFieldNo = ItemJnlLine.FieldNo(Quantity)) or
                (CalledByFieldNo = ItemJnlLine.FieldNo("Variant Code")))
        then
            ItemJnlLine.Validate("Unit Amount", TempSalesPrice."Unit Price");
        OnAfterFindItemJnlLinePrice(ItemJnlLine, TempSalesPrice, CalledByFieldNo, FoundSalesPrice);
    end;

    procedure FindServLinePrice(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line"; CalledByFieldNo: Integer)
    var
        ServCost: Record Microsoft.Service.Pricing."Service Cost";
        Res: Record Resource;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindServLinePrice(ServLine, ServHeader, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        ServHeader.Get(ServLine."Document Type", ServLine."Document No.");
        if ServLine.Type <> ServLine.Type::" " then begin
            SetCurrency(
              ServHeader."Currency Code", ServHeader."Currency Factor", ServHeaderExchDate(ServHeader));
            SetVAT(ServHeader."Prices Including VAT", ServLine."VAT %", ServLine."VAT Calculation Type".AsInteger(), ServLine."VAT Bus. Posting Group");
            SetUoM(Abs(ServLine.Quantity), ServLine."Qty. per Unit of Measure");
            SetLineDisc(ServLine."Line Discount %", ServLine."Allow Line Disc.", false);

            ServLine.TestField("Qty. per Unit of Measure");
            if PricesInCurrency then
                ServHeader.TestField("Currency Factor");
        end;

        case ServLine.Type of
            ServLine.Type::Item:
                begin
                    ServLinePriceExists(ServHeader, ServLine, false);
                    CalcBestUnitPrice(TempSalesPrice);
                    if FoundSalesPrice or
                       not ((CalledByFieldNo = ServLine.FieldNo(Quantity)) or
                            (CalledByFieldNo = ServLine.FieldNo("Variant Code")))
                    then begin
                        if ServLine."Line Discount Type" = ServLine."Line Discount Type"::"Line Disc." then
                            ServLine."Allow Line Disc." := TempSalesPrice."Allow Line Disc.";
                        ServLine."Unit Price" := TempSalesPrice."Unit Price";
                    end;
                    if not ServLine."Allow Line Disc." and (ServLine."Line Discount Type" = ServLine."Line Discount Type"::"Line Disc.") then
                        ServLine."Line Discount %" := 0;
                end;
            ServLine.Type::Resource:
                begin
                    SetResPrice(ServLine."No.", ServLine."Work Type Code", ServLine."Currency Code");
                    CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResPrice);
                    IsHandled := false;
                    OnAfterFindServLineResPrice(ServLine, ResPrice, HideResUnitPriceMessage, CalledByFieldNo, IsHandled);
                    if IsHandled then
                        exit;
                    ConvertPriceToVAT(false, '', '', ResPrice."Unit Price");
                    ResPrice."Unit Price" := ResPrice."Unit Price" * ServLine."Qty. per Unit of Measure";
                    ConvertPriceLCYToFCY(ResPrice."Currency Code", ResPrice."Unit Price");
                    if (ResPrice."Unit Price" > ServHeader."Max. Labor Unit Price") and
                       (ServHeader."Max. Labor Unit Price" <> 0)
                    then begin
                        Res.Get(ServLine."No.");
                        ServLine."Unit Price" := ServHeader."Max. Labor Unit Price";
                        if (HideResUnitPriceMessage = false) and
                           (CalledByFieldNo <> ServLine.FieldNo(Quantity))
                        then
                            Message(
                              StrSubstNo(
                                Text018,
                                Res.TableCaption(), ServLine.FieldCaption("Unit Price"),
                                ServHeader.FieldCaption("Max. Labor Unit Price"),
                                ServHeader."Max. Labor Unit Price"));
                        HideResUnitPriceMessage := true;
                    end else
                        ServLine."Unit Price" := ResPrice."Unit Price";
                end;
            ServLine.Type::Cost:
                begin
                    ServCost.Get(ServLine."No.");

                    ConvertPriceToVAT(false, '', '', ServCost."Default Unit Price");
                    ConvertPriceLCYToFCY('', ServCost."Default Unit Price");
                    ServLine."Unit Price" := ServCost."Default Unit Price";
                end;
        end;
        OnAfterFindServLinePrice(ServLine, ServHeader, TempSalesPrice, ResPrice, ServCost, CalledByFieldNo);
    end;

    procedure FindSalesLineLineDisc(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindSalesLineLineDisc(SalesLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SetCurrency(SalesHeader."Currency Code", 0, 0D);
        SetUoM(Abs(SalesLine.Quantity), SalesLine."Qty. per Unit of Measure");

        SalesLine.TestField("Qty. per Unit of Measure");

        IsHandled := false;
        OnFindSalesLineLineDiscOnBeforeCalcLineDisc(SalesHeader, SalesLine, TempSalesLineDisc, Qty, QtyPerUOM, IsHandled);
        if not IsHandled then
            if SalesLine.Type = SalesLine.Type::Item then begin
                SalesLineLineDiscExists(SalesHeader, SalesLine, false);
                CalcBestLineDisc(TempSalesLineDisc);
                SalesLine."Line Discount %" := TempSalesLineDisc."Line Discount %";
            end;

        OnAfterFindSalesLineLineDisc(SalesLine, SalesHeader, TempSalesLineDisc);
    end;

    procedure FindServLineDisc(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindServLineDisc(ServHeader, ServLine, IsHandled);
        if IsHandled then
            exit;

        SetCurrency(ServHeader."Currency Code", 0, 0D);
        SetUoM(Abs(ServLine.Quantity), ServLine."Qty. per Unit of Measure");

        ServLine.TestField("Qty. per Unit of Measure");

        if ServLine.Type = ServLine.Type::Item then begin
            Item.Get(ServLine."No.");
            FindSalesLineDisc(
              TempSalesLineDisc, ServLine."Bill-to Customer No.", ServHeader."Contact No.",
              ServLine."Customer Disc. Group", '', ServLine."No.", Item."Item Disc. Group", ServLine."Variant Code",
              ServLine."Unit of Measure Code", ServHeader."Currency Code", ServHeader."Order Date", false);
            CalcBestLineDisc(TempSalesLineDisc);
            ServLine."Line Discount %" := TempSalesLineDisc."Line Discount %";
        end;
        if ServLine.Type in [ServLine.Type::Resource, ServLine.Type::Cost, ServLine.Type::"G/L Account"] then begin
            ServLine."Line Discount %" := 0;
            ServLine."Line Discount Amount" :=
              Round(
                Round(ServLine.CalcChargeableQty() * ServLine."Unit Price", Currency."Amount Rounding Precision") *
                ServLine."Line Discount %" / 100, Currency."Amount Rounding Precision");
            ServLine."Inv. Discount Amount" := 0;
            ServLine."Inv. Disc. Amount to Invoice" := 0;
        end;
        OnAfterFindServLineDisc(ServLine, ServHeader, TempSalesLineDisc);
    end;

    procedure FindStdItemJnlLinePrice(var StdItemJnlLine: Record "Standard Item Journal Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindStdItemJnlLinePrice(StdItemJnlLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        SetCurrency('', 0, 0D);
        SetVAT(false, 0, 0, '');
        SetUoM(Abs(StdItemJnlLine.Quantity), StdItemJnlLine."Qty. per Unit of Measure");
        StdItemJnlLine.TestField("Qty. per Unit of Measure");
        Item.Get(StdItemJnlLine."Item No.");

        FindSalesPrice(
          TempSalesPrice, '', '', '', '', StdItemJnlLine."Item No.", StdItemJnlLine."Variant Code",
          StdItemJnlLine."Unit of Measure Code", '', WorkDate(), false);
        CalcBestUnitPrice(TempSalesPrice);
        if FoundSalesPrice or
           not ((CalledByFieldNo = StdItemJnlLine.FieldNo(Quantity)) or
                (CalledByFieldNo = StdItemJnlLine.FieldNo("Variant Code")))
        then
            StdItemJnlLine.Validate("Unit Amount", TempSalesPrice."Unit Price");
        OnAfterFindStdItemJnlLinePrice(StdItemJnlLine, TempSalesPrice, CalledByFieldNo);
    end;

    procedure FindAnalysisReportPrice(ItemNo: Code[20]; Date: Date): Decimal
    var
        UnitPrice: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindAnalysisReportPrice(ItemNo, Date, UnitPrice, IsHandled, FoundSalesPrice);
        if IsHandled then
            exit(UnitPrice);

        SetCurrency('', 0, 0D);
        SetVAT(false, 0, 0, '');
        SetUoM(0, 1);
        Item.Get(ItemNo);

        FindSalesPrice(TempSalesPrice, '', '', '', '', ItemNo, '', '', '', Date, false);
        CalcBestUnitPrice(TempSalesPrice);
        if FoundSalesPrice then
            exit(TempSalesPrice."Unit Price");
        exit(Item."Unit Price");
    end;

    procedure CalcBestUnitPrice(var SalesPrice: Record "Sales Price")
    var
        BestSalesPrice: Record "Sales Price";
        BestSalesPriceFound: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCalcBestUnitPrice(SalesPrice, IsHandled);
        if IsHandled then
            exit;

        FoundSalesPrice := SalesPrice.FindSet();
        if FoundSalesPrice then
            repeat
                IsHandled := false;
                OnCalcBestUnitPriceOnBeforeCalcBestUnitPriceConvertPrice(SalesPrice, Qty, IsHandled, Item);
                if not IsHandled then
                    if IsInMinQty(SalesPrice."Unit of Measure Code", SalesPrice."Minimum Quantity") then begin
                        CalcBestUnitPriceConvertPrice(SalesPrice);

                        case true of
                            ((BestSalesPrice."Currency Code" = '') and (SalesPrice."Currency Code" <> '')) or
                            ((BestSalesPrice."Variant Code" = '') and (SalesPrice."Variant Code" <> '')):
                                begin
                                    BestSalesPrice := SalesPrice;
                                    BestSalesPriceFound := true;
                                end;
                            ((BestSalesPrice."Currency Code" = '') or (SalesPrice."Currency Code" <> '')) and
                          ((BestSalesPrice."Variant Code" = '') or (SalesPrice."Variant Code" <> '')):
                                if (BestSalesPrice."Unit Price" = 0) or
                                   (CalcLineAmount(BestSalesPrice) > CalcLineAmount(SalesPrice))
                                then begin
                                    BestSalesPrice := SalesPrice;
                                    BestSalesPriceFound := true;
                                end;
                        end;
                    end;
            until SalesPrice.Next() = 0;

        OnAfterCalcBestUnitPrice(SalesPrice, BestSalesPrice);

        // No price found in agreement
        if not BestSalesPriceFound then begin
            ConvertPriceToVAT(
              Item."Price Includes VAT", Item."VAT Prod. Posting Group",
              Item."VAT Bus. Posting Gr. (Price)", Item."Unit Price");
            ConvertPriceToUoM('', Item."Unit Price");
            ConvertPriceLCYToFCY('', Item."Unit Price");

            Clear(BestSalesPrice);
            BestSalesPrice."Unit Price" := Item."Unit Price";
            BestSalesPrice."Allow Line Disc." := AllowLineDisc;
            BestSalesPrice."Allow Invoice Disc." := AllowInvDisc;
            OnAfterCalcBestUnitPriceAsItemUnitPrice(BestSalesPrice, Item);
        end;

        SalesPrice := BestSalesPrice;
    end;

    local procedure CalcBestUnitPriceConvertPrice(var SalesPrice: Record "Sales Price")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBestUnitPriceConvertPrice(SalesPrice, IsHandled, Item);
        if IsHandled then
            exit;

        ConvertPriceToVAT(
            SalesPrice."Price Includes VAT", Item."VAT Prod. Posting Group",
            SalesPrice."VAT Bus. Posting Gr. (Price)", SalesPrice."Unit Price");
        ConvertPriceToUoM(SalesPrice."Unit of Measure Code", SalesPrice."Unit Price");
        ConvertPriceLCYToFCY(SalesPrice."Currency Code", SalesPrice."Unit Price");
    end;

    procedure CalcBestLineDisc(var SalesLineDisc: Record "Sales Line Discount")
    var
        BestSalesLineDisc: Record "Sales Line Discount";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBestLineDisc(SalesLineDisc, Item, IsHandled, QtyPerUOM, Qty);
        if IsHandled then
            exit;

        if SalesLineDisc.FindSet() then
            repeat
                if IsInMinQty(SalesLineDisc."Unit of Measure Code", SalesLineDisc."Minimum Quantity") then
                    case true of
                        ((BestSalesLineDisc."Currency Code" = '') and (SalesLineDisc."Currency Code" <> '')) or
                      ((BestSalesLineDisc."Variant Code" = '') and (SalesLineDisc."Variant Code" <> '')):
                            BestSalesLineDisc := SalesLineDisc;
                        ((BestSalesLineDisc."Currency Code" = '') or (SalesLineDisc."Currency Code" <> '')) and
                      ((BestSalesLineDisc."Variant Code" = '') or (SalesLineDisc."Variant Code" <> '')):
                            if BestSalesLineDisc."Line Discount %" < SalesLineDisc."Line Discount %" then
                                BestSalesLineDisc := SalesLineDisc;
                    end;
            until SalesLineDisc.Next() = 0;

        SalesLineDisc := BestSalesLineDisc;
    end;

    procedure FindSalesPrice(var ToSalesPrice: Record "Sales Price"; CustNo: Code[20]; ContNo: Code[20]; CustPriceGrCode: Code[10]; CampaignNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean)
    var
        FromSalesPrice: Record "Sales Price";
        TempTargetCampaignGr: Record "Campaign Target Group" temporary;
    begin
        if not ToSalesPrice.IsTemporary then
            Error(TempTableErr);

        ToSalesPrice.Reset();
        ToSalesPrice.DeleteAll();

        OnBeforeFindSalesPrice(
          ToSalesPrice, FromSalesPrice, QtyPerUOM, Qty, CustNo, ContNo, CustPriceGrCode, CampaignNo,
          ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll);

        FromSalesPrice.SetRange("Item No.", ItemNo);
        FromSalesPrice.SetFilter("Variant Code", '%1|%2', VariantCode, '');
        FromSalesPrice.SetFilter("Ending Date", '%1|>=%2', 0D, StartingDate);
        if not ShowAll then begin
            FromSalesPrice.SetFilter("Currency Code", '%1|%2', CurrencyCode, '');
            if UOM <> '' then
                FromSalesPrice.SetFilter("Unit of Measure Code", '%1|%2', UOM, '');
            FromSalesPrice.SetRange("Starting Date", 0D, StartingDate);
        end;

        FromSalesPrice.SetRange("Sales Type", FromSalesPrice."Sales Type"::"All Customers");
        FromSalesPrice.SetRange("Sales Code");
        CopySalesPriceToSalesPrice(FromSalesPrice, ToSalesPrice);

        if CustNo <> '' then begin
            FromSalesPrice.SetRange("Sales Type", FromSalesPrice."Sales Type"::Customer);
            FromSalesPrice.SetRange("Sales Code", CustNo);
            CopySalesPriceToSalesPrice(FromSalesPrice, ToSalesPrice);
        end;

        if CustPriceGrCode <> '' then begin
            FromSalesPrice.SetRange("Sales Type", FromSalesPrice."Sales Type"::"Customer Price Group");
            FromSalesPrice.SetRange("Sales Code", CustPriceGrCode);
            CopySalesPriceToSalesPrice(FromSalesPrice, ToSalesPrice);
        end;

        if not ((CustNo = '') and (ContNo = '') and (CampaignNo = '')) then begin
            FromSalesPrice.SetRange("Sales Type", FromSalesPrice."Sales Type"::Campaign);
            if ActivatedCampaignExists(TempTargetCampaignGr, CustNo, ContNo, CampaignNo) then
                repeat
                    FromSalesPrice.SetRange("Sales Code", TempTargetCampaignGr."Campaign No.");
                    CopySalesPriceToSalesPrice(FromSalesPrice, ToSalesPrice);
                until TempTargetCampaignGr.Next() = 0;
        end;

        OnAfterFindSalesPrice(
          ToSalesPrice, FromSalesPrice, QtyPerUOM, Qty, CustNo, ContNo, CustPriceGrCode, CampaignNo,
          ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll);
    end;

    procedure FindSalesLineDisc(var ToSalesLineDisc: Record "Sales Line Discount"; CustNo: Code[20]; ContNo: Code[20]; CustDiscGrCode: Code[20]; CampaignNo: Code[20]; ItemNo: Code[20]; ItemDiscGrCode: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean)
    var
        FromSalesLineDisc: Record "Sales Line Discount";
        TempCampaignTargetGr: Record "Campaign Target Group" temporary;
        InclCampaigns: Boolean;
    begin
        OnBeforeFindSalesLineDisc(
          ToSalesLineDisc, CustNo, ContNo, CustDiscGrCode, CampaignNo, ItemNo, ItemDiscGrCode, VariantCode, UOM,
          CurrencyCode, StartingDate, ShowAll);

        FromSalesLineDisc.SetFilter("Ending Date", '%1|>=%2', 0D, StartingDate);
        FromSalesLineDisc.SetFilter("Variant Code", '%1|%2', VariantCode, '');
        OnFindSalesLineDiscOnAfterSetFilters(FromSalesLineDisc);
        if not ShowAll then begin
            FromSalesLineDisc.SetRange("Starting Date", 0D, StartingDate);
            FromSalesLineDisc.SetFilter("Currency Code", '%1|%2', CurrencyCode, '');
            if UOM <> '' then
                FromSalesLineDisc.SetFilter("Unit of Measure Code", '%1|%2', UOM, '');
        end;

        ToSalesLineDisc.Reset();
        ToSalesLineDisc.DeleteAll();
        for FromSalesLineDisc."Sales Type" := FromSalesLineDisc."Sales Type"::Customer to FromSalesLineDisc."Sales Type"::Campaign do
            if (FromSalesLineDisc."Sales Type" = FromSalesLineDisc."Sales Type"::"All Customers") or
               ((FromSalesLineDisc."Sales Type" = FromSalesLineDisc."Sales Type"::Customer) and (CustNo <> '')) or
               ((FromSalesLineDisc."Sales Type" = FromSalesLineDisc."Sales Type"::"Customer Disc. Group") and (CustDiscGrCode <> '')) or
               ((FromSalesLineDisc."Sales Type" = FromSalesLineDisc."Sales Type"::Campaign) and
                not ((CustNo = '') and (ContNo = '') and (CampaignNo = '')))
            then begin
                InclCampaigns := false;

                FromSalesLineDisc.SetRange("Sales Type", FromSalesLineDisc."Sales Type");
                case FromSalesLineDisc."Sales Type" of
                    FromSalesLineDisc."Sales Type"::"All Customers":
                        FromSalesLineDisc.SetRange("Sales Code");
                    FromSalesLineDisc."Sales Type"::Customer:
                        FromSalesLineDisc.SetRange("Sales Code", CustNo);
                    FromSalesLineDisc."Sales Type"::"Customer Disc. Group":
                        FromSalesLineDisc.SetRange("Sales Code", CustDiscGrCode);
                    FromSalesLineDisc."Sales Type"::Campaign:
                        begin
                            InclCampaigns := ActivatedCampaignExists(TempCampaignTargetGr, CustNo, ContNo, CampaignNo);
                            FromSalesLineDisc.SetRange("Sales Code", TempCampaignTargetGr."Campaign No.");
                        end;
                end;

                repeat
                    FromSalesLineDisc.SetRange(Type, FromSalesLineDisc.Type::Item);
                    FromSalesLineDisc.SetRange(Code, ItemNo);
                    CopySalesDiscToSalesDisc(FromSalesLineDisc, ToSalesLineDisc);

                    if ItemDiscGrCode <> '' then begin
                        FromSalesLineDisc.SetRange(Type, FromSalesLineDisc.Type::"Item Disc. Group");
                        FromSalesLineDisc.SetRange(Code, ItemDiscGrCode);
                        CopySalesDiscToSalesDisc(FromSalesLineDisc, ToSalesLineDisc);
                    end;

                    if InclCampaigns then begin
                        InclCampaigns := TempCampaignTargetGr.Next() <> 0;
                        FromSalesLineDisc.SetRange("Sales Code", TempCampaignTargetGr."Campaign No.");
                    end;
                until not InclCampaigns;
            end;

        OnAfterFindSalesLineDisc(
          ToSalesLineDisc, CustNo, ContNo, CustDiscGrCode, CampaignNo, ItemNo, ItemDiscGrCode, VariantCode, UOM,
          CurrencyCode, StartingDate, ShowAll);
    end;

    procedure CopySalesPrice(var SalesPrice: Record "Sales Price")
    begin
        SalesPrice.DeleteAll();
        CopySalesPriceToSalesPrice(TempSalesPrice, SalesPrice);
    end;

    local procedure CopySalesPriceToSalesPrice(var FromSalesPrice: Record "Sales Price"; var ToSalesPrice: Record "Sales Price")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesPriceToSalesPrice(FromSalesPrice, ToSalesPrice, IsHandled);
        if IsHandled then
            exit;

        if FromSalesPrice.FindSet() then
            repeat
                ToSalesPrice := FromSalesPrice;
                ToSalesPrice.Insert();
            until FromSalesPrice.Next() = 0;
    end;

    local procedure CopySalesDiscToSalesDisc(var FromSalesLineDisc: Record "Sales Line Discount"; var ToSalesLineDisc: Record "Sales Line Discount")
    begin
        if FromSalesLineDisc.FindSet() then
            repeat
                ToSalesLineDisc := FromSalesLineDisc;
                ToSalesLineDisc.Insert();
            until FromSalesLineDisc.Next() = 0;
    end;

    procedure SetItem(ItemNo: Code[20])
    begin
        Item.Get(ItemNo);
    end;

    procedure SetResPrice(Code2: Code[20]; WorkTypeCode: Code[10]; CurrencyCode: Code[10])
    begin
        ResPrice.Init();
        OnSetResPriceOnAfterInit(ResPrice);
        ResPrice.Code := Code2;
        ResPrice."Work Type Code" := WorkTypeCode;
        ResPrice."Currency Code" := CurrencyCode;
    end;

    procedure SetCurrency(CurrencyCode2: Code[10]; CurrencyFactor2: Decimal; ExchRateDate2: Date)
    begin
        PricesInCurrency := CurrencyCode2 <> '';
        if PricesInCurrency then begin
            Currency.Get(CurrencyCode2);
            Currency.TestField("Unit-Amount Rounding Precision");
            CurrencyFactor := CurrencyFactor2;
            ExchRateDate := ExchRateDate2;
        end else
            GLSetup.Get();
    end;

    procedure SetVAT(PriceInclVAT2: Boolean; VATPerCent2: Decimal; VATCalcType2: Option; VATBusPostingGr2: Code[20])
    begin
        PricesInclVAT := PriceInclVAT2;
        VATPerCent := VATPerCent2;
        VATCalcType := VATCalcType2;
        VATBusPostingGr := VATBusPostingGr2;
    end;

    procedure SetUoM(Qty2: Decimal; QtyPerUoM2: Decimal)
    begin
        Qty := Qty2;
        QtyPerUOM := QtyPerUoM2;
    end;

    procedure SetLineDisc(LineDiscPerCent2: Decimal; AllowLineDisc2: Boolean; AllowInvDisc2: Boolean)
    begin
        LineDiscPerCent := LineDiscPerCent2;
        AllowLineDisc := AllowLineDisc2;
        AllowInvDisc := AllowInvDisc2;
    end;

    local procedure SetBillToCustomerDependingOnBillingMethod(Job: Record "Job"; JobPlanningLine: Record "Job Planning Line"; var BillToCustomerNo: Code[20]; var BillToContactNo: Code[20])
    var
        JobTask: Record "Job Task";
    begin
        BillToCustomerNo := Job."Bill-to Customer No.";
        BillToContactNo := Job."Bill-to Contact No.";

        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            exit;

        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        if (JobTask."Bill-to Customer No." <> '') and (JobTask."Bill-to Customer No." <> Job."Bill-to Customer No.") then begin
            BillToCustomerNo := JobTask."Bill-to Customer No.";
            BillToContactNo := JobTask."Bill-to Contact No.";
        end;
    end;

    local procedure IsInMinQty(UnitofMeasureCode: Code[10]; MinQty: Decimal): Boolean
    begin
        if UnitofMeasureCode = '' then
            exit(MinQty <= QtyPerUOM * Qty);
        exit(MinQty <= Qty);
    end;

    procedure ConvertPriceToVAT(FromPricesInclVAT: Boolean; FromVATProdPostingGr: Code[20]; FromVATBusPostingGr: Code[20]; var UnitPrice: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        if FromPricesInclVAT then begin
            VATPostingSetup.Get(FromVATBusPostingGr, FromVATProdPostingGr);
            IsHandled := false;
            OnBeforeConvertPriceToVAT(VATPostingSetup, UnitPrice, IsHandled);
            if IsHandled then
                exit;

            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    VATPostingSetup."VAT %" := 0;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    Error(
                      Text010,
                      VATPostingSetup.FieldCaption("VAT Calculation Type"),
                      VATPostingSetup."VAT Calculation Type");
            end;

            case VATCalcType of
                VATCalcType::"Normal VAT",
                VATCalcType::"Full VAT",
                VATCalcType::"Sales Tax":
                    if PricesInclVAT then begin
                        if VATBusPostingGr <> FromVATBusPostingGr then
                            UnitPrice := UnitPrice * (100 + VATPerCent) / (100 + VATPostingSetup."VAT %");
                    end else
                        UnitPrice := UnitPrice / (1 + VATPostingSetup."VAT %" / 100);
                VATCalcType::"Reverse Charge VAT":
                    UnitPrice := UnitPrice / (1 + VATPostingSetup."VAT %" / 100);
            end;
        end else
            if PricesInclVAT then
                UnitPrice := UnitPrice * (1 + VATPerCent / 100);
    end;

    local procedure ConvertPriceToUoM(UnitOfMeasureCode: Code[10]; var UnitPrice: Decimal)
    begin
        if UnitOfMeasureCode = '' then
            UnitPrice := UnitPrice * QtyPerUOM;
    end;

    procedure ConvertPriceLCYToFCY(CurrencyCode: Code[10]; var UnitPrice: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if PricesInCurrency then begin
            if CurrencyCode = '' then
                UnitPrice :=
                  CurrExchRate.ExchangeAmtLCYToFCY(ExchRateDate, Currency.Code, UnitPrice, CurrencyFactor);
            UnitPrice := Round(UnitPrice, Currency."Unit-Amount Rounding Precision");
        end else
            UnitPrice := Round(UnitPrice, GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure CalcLineAmount(SalesPrice: Record "Sales Price") LineAmount: Decimal
    begin
        if SalesPrice."Allow Line Disc." then
            LineAmount := SalesPrice."Unit Price" * (1 - LineDiscPerCent / 100)
        else
            LineAmount := SalesPrice."Unit Price";
        OnAfterCalcLineAmount(SalesPrice, LineAmount, LineDiscPerCent);
    end;

    procedure GetSalesLinePrice(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesLinePrice(SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLinePriceExists(SalesHeader, SalesLine, true);

        if PAGE.RunModal(PAGE::"Get Sales Price", TempSalesPrice) = ACTION::LookupOK then begin
            SetVAT(
              SalesHeader."Prices Including VAT", SalesLine."VAT %", SalesLine."VAT Calculation Type".AsInteger(), SalesLine."VAT Bus. Posting Group");
            SetUoM(Abs(SalesLine.Quantity), SalesLine."Qty. per Unit of Measure");
            SetCurrency(
              SalesHeader."Currency Code", SalesHeader."Currency Factor", SalesHeaderExchDate(SalesHeader));

            if not IsInMinQty(TempSalesPrice."Unit of Measure Code", TempSalesPrice."Minimum Quantity") then
                Error(
                  Text000,
                  SalesLine.FieldCaption(Quantity),
                  TempSalesPrice.FieldCaption("Minimum Quantity"),
                  TempSalesPrice.TableCaption());
            if not (TempSalesPrice."Currency Code" in [SalesLine."Currency Code", '']) then
                Error(
                  Text001,
                  SalesLine.FieldCaption("Currency Code"),
                  SalesLine.TableCaption,
                  TempSalesPrice.TableCaption());
            if not (TempSalesPrice."Unit of Measure Code" in [SalesLine."Unit of Measure Code", '']) then
                Error(
                  Text001,
                  SalesLine.FieldCaption("Unit of Measure Code"),
                  SalesLine.TableCaption,
                  TempSalesPrice.TableCaption());
            if TempSalesPrice."Starting Date" > SalesHeaderStartDate(SalesHeader, DateCaption) then
                Error(
                  Text000,
                  DateCaption,
                  TempSalesPrice.FieldCaption("Starting Date"),
                  TempSalesPrice.TableCaption());

            ConvertPriceToVAT(
              TempSalesPrice."Price Includes VAT", Item."VAT Prod. Posting Group",
              TempSalesPrice."VAT Bus. Posting Gr. (Price)", TempSalesPrice."Unit Price");
            ConvertPriceToUoM(TempSalesPrice."Unit of Measure Code", TempSalesPrice."Unit Price");
            ConvertPriceLCYToFCY(TempSalesPrice."Currency Code", TempSalesPrice."Unit Price");

            SalesLine."Allow Invoice Disc." := TempSalesPrice."Allow Invoice Disc.";
            SalesLine."Allow Line Disc." := TempSalesPrice."Allow Line Disc.";
            if not SalesLine."Allow Line Disc." then
                SalesLine."Line Discount %" := 0;

            SalesLine.Validate("Unit Price", TempSalesPrice."Unit Price");
        end;

        OnAfterGetSalesLinePrice(SalesHeader, SalesLine, TempSalesPrice);
    end;

    procedure GetSalesLineLineDisc(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesLineLineDisc(SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLineLineDiscExists(SalesHeader, SalesLine, true);

        if PAGE.RunModal(PAGE::"Get Sales Line Disc.", TempSalesLineDisc) = ACTION::LookupOK then begin
            SetCurrency(SalesHeader."Currency Code", 0, 0D);
            SetUoM(Abs(SalesLine.Quantity), SalesLine."Qty. per Unit of Measure");

            if not IsInMinQty(TempSalesLineDisc."Unit of Measure Code", TempSalesLineDisc."Minimum Quantity")
            then
                Error(
                  Text000, SalesLine.FieldCaption(Quantity),
                  TempSalesLineDisc.FieldCaption("Minimum Quantity"),
                  TempSalesLineDisc.TableCaption());
            if not (TempSalesLineDisc."Currency Code" in [SalesLine."Currency Code", '']) then
                Error(
                  Text001,
                  SalesLine.FieldCaption("Currency Code"),
                  SalesLine.TableCaption,
                  TempSalesLineDisc.TableCaption());
            if not (TempSalesLineDisc."Unit of Measure Code" in [SalesLine."Unit of Measure Code", '']) then
                Error(
                  Text001,
                  SalesLine.FieldCaption("Unit of Measure Code"),
                  SalesLine.TableCaption,
                  TempSalesLineDisc.TableCaption());
            if TempSalesLineDisc."Starting Date" > SalesHeaderStartDate(SalesHeader, DateCaption) then
                Error(
                  Text000,
                  DateCaption,
                  TempSalesLineDisc.FieldCaption("Starting Date"),
                  TempSalesLineDisc.TableCaption());

            SalesLine.TestField("Allow Line Disc.");
            ValidateLineDiscountOnSalesLine(SalesLine);
        end;

        OnAfterGetSalesLineLineDisc(SalesLine, TempSalesLineDisc);
    end;

    local procedure ValidateLineDiscountOnSalesLine(var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateLineDiscountOnSalesLine(SalesLine, TempSalesLineDisc, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate("Line Discount %", TempSalesLineDisc."Line Discount %");
    end;

    procedure SalesLinePriceExists(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowAll: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLinePriceExistsProcedure(SalesHeader, SalesLine, ShowAll, TempSalesPrice, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (SalesLine.Type = SalesLine.Type::Item) and Item.Get(SalesLine."No.") then begin
            IsHandled := false;
            OnBeforeSalesLinePriceExists(
              SalesLine, SalesHeader, TempSalesPrice, Currency, CurrencyFactor,
              SalesHeaderStartDate(SalesHeader, DateCaption), Qty, QtyPerUOM, ShowAll, IsHandled);
            if not IsHandled then begin
                FindSalesPrice(
                  TempSalesPrice, GetCustNoForSalesHeader(SalesHeader), SalesHeader."Bill-to Contact No.",
                  SalesLine."Customer Price Group", '', SalesLine."No.", SalesLine."Variant Code", SalesLine."Unit of Measure Code",
                  SalesHeader."Currency Code", SalesHeaderStartDate(SalesHeader, DateCaption), ShowAll);
                OnAfterSalesLinePriceExists(SalesLine, SalesHeader, TempSalesPrice, ShowAll);
            end;
            exit(TempSalesPrice.FindFirst());
        end;
        Result := false;

        OnAfterSalesLinePriceExistsProcedure(SalesHeader, SalesLine, Res, DateCaption, ShowAll, Result);
    end;

    procedure SalesLineLineDiscExists(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        if (SalesLine.Type = SalesLine.Type::Item) and Item.Get(SalesLine."No.") then begin
            IsHandled := false;
            OnBeforeSalesLineLineDiscExists(
              SalesLine, SalesHeader, TempSalesLineDisc, SalesHeaderStartDate(SalesHeader, DateCaption),
              Qty, QtyPerUOM, ShowAll, IsHandled);
            if not IsHandled then begin
                FindSalesLineDisc(
                  TempSalesLineDisc, GetCustNoForSalesHeader(SalesHeader), SalesHeader."Bill-to Contact No.",
                  SalesLine."Customer Disc. Group", '', SalesLine."No.", Item."Item Disc. Group", SalesLine."Variant Code", SalesLine."Unit of Measure Code",
                  SalesHeader."Currency Code", SalesHeaderStartDate(SalesHeader, DateCaption), ShowAll);
                OnAfterSalesLineLineDiscExists(SalesLine, SalesHeader, TempSalesLineDisc, ShowAll);
            end;
            exit(TempSalesLineDisc.FindFirst())
        end;
        exit(false);
    end;

    procedure GetServLinePrice(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetServLinePrice(ServHeader, ServLine, IsHandled);
        if IsHandled then
            exit;

        ServLinePriceExists(ServHeader, ServLine, true);

        if PAGE.RunModal(PAGE::"Get Sales Price", TempSalesPrice) = ACTION::LookupOK then begin
            SetVAT(
              ServHeader."Prices Including VAT", ServLine."VAT %", ServLine."VAT Calculation Type".AsInteger(), ServLine."VAT Bus. Posting Group");
            SetUoM(Abs(ServLine.Quantity), ServLine."Qty. per Unit of Measure");
            SetCurrency(
              ServHeader."Currency Code", ServHeader."Currency Factor", ServHeaderExchDate(ServHeader));

            if not IsInMinQty(TempSalesPrice."Unit of Measure Code", TempSalesPrice."Minimum Quantity") then
                Error(
                  Text000,
                  ServLine.FieldCaption(Quantity),
                  TempSalesPrice.FieldCaption("Minimum Quantity"),
                  TempSalesPrice.TableCaption());
            if not (TempSalesPrice."Currency Code" in [ServLine."Currency Code", '']) then
                Error(
                  Text001,
                  ServLine.FieldCaption("Currency Code"),
                  ServLine.TableCaption,
                  TempSalesPrice.TableCaption());
            if not (TempSalesPrice."Unit of Measure Code" in [ServLine."Unit of Measure Code", '']) then
                Error(
                  Text001,
                  ServLine.FieldCaption("Unit of Measure Code"),
                  ServLine.TableCaption,
                  TempSalesPrice.TableCaption());
            if TempSalesPrice."Starting Date" > ServHeaderStartDate(ServHeader, DateCaption) then
                Error(
                  Text000,
                  DateCaption,
                  TempSalesPrice.FieldCaption("Starting Date"),
                  TempSalesPrice.TableCaption());

            ConvertPriceToVAT(
              TempSalesPrice."Price Includes VAT", Item."VAT Prod. Posting Group",
              TempSalesPrice."VAT Bus. Posting Gr. (Price)", TempSalesPrice."Unit Price");
            ConvertPriceToUoM(TempSalesPrice."Unit of Measure Code", TempSalesPrice."Unit Price");
            ConvertPriceLCYToFCY(TempSalesPrice."Currency Code", TempSalesPrice."Unit Price");

            ServLine."Allow Invoice Disc." := TempSalesPrice."Allow Invoice Disc.";
            ServLine."Allow Line Disc." := TempSalesPrice."Allow Line Disc.";
            if not ServLine."Allow Line Disc." then
                ServLine."Line Discount %" := 0;

            ServLine.Validate("Unit Price", TempSalesPrice."Unit Price");
            ServLine.ConfirmAdjPriceLineChange();
        end;
    end;

    procedure GetServLineLineDisc(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetServLineDisc(ServHeader, ServLine, IsHandled);
        if IsHandled then
            exit;

        ServLineLineDiscExists(ServHeader, ServLine, true);

        if PAGE.RunModal(PAGE::"Get Sales Line Disc.", TempSalesLineDisc) = ACTION::LookupOK then begin
            SetCurrency(ServHeader."Currency Code", 0, 0D);
            SetUoM(Abs(ServLine.Quantity), ServLine."Qty. per Unit of Measure");

            if not IsInMinQty(TempSalesLineDisc."Unit of Measure Code", TempSalesLineDisc."Minimum Quantity")
            then
                Error(
                  Text000, ServLine.FieldCaption(Quantity),
                  TempSalesLineDisc.FieldCaption("Minimum Quantity"),
                  TempSalesLineDisc.TableCaption());
            if not (TempSalesLineDisc."Currency Code" in [ServLine."Currency Code", '']) then
                Error(
                  Text001,
                  ServLine.FieldCaption("Currency Code"),
                  ServLine.TableCaption,
                  TempSalesLineDisc.TableCaption());
            if not (TempSalesLineDisc."Unit of Measure Code" in [ServLine."Unit of Measure Code", '']) then
                Error(
                  Text001,
                  ServLine.FieldCaption("Unit of Measure Code"),
                  ServLine.TableCaption,
                  TempSalesLineDisc.TableCaption());
            if TempSalesLineDisc."Starting Date" > ServHeaderStartDate(ServHeader, DateCaption) then
                Error(
                  Text000,
                  DateCaption,
                  TempSalesLineDisc.FieldCaption("Starting Date"),
                  TempSalesLineDisc.TableCaption());

            ServLine.TestField("Allow Line Disc.");
            ServLine.CheckLineDiscount(TempSalesLineDisc."Line Discount %");
            ServLine.Validate("Line Discount %", TempSalesLineDisc."Line Discount %");
            ServLine.ConfirmAdjPriceLineChange();
        end;
    end;

    local procedure GetCustNoForSalesHeader(SalesHeader: Record "Sales Header"): Code[20]
    var
        CustNo: Code[20];
    begin
        CustNo := SalesHeader."Bill-to Customer No.";
        OnGetCustNoForSalesHeader(SalesHeader, CustNo);
        exit(CustNo);
    end;

    [Scope('OnPrem')]
    procedure ServLinePriceExists(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        if (ServLine.Type = ServLine.Type::Item) and Item.Get(ServLine."No.") then begin
            IsHandled := false;
            OnBeforeServLinePriceExists(ServLine, ServHeader, TempSalesPrice, ShowAll, IsHandled);
            if not IsHandled then
                FindSalesPrice(
                  TempSalesPrice, ServLine."Bill-to Customer No.", ServHeader."Bill-to Contact No.",
                  ServLine."Customer Price Group", '', ServLine."No.", ServLine."Variant Code", ServLine."Unit of Measure Code",
                  ServHeader."Currency Code", ServHeaderStartDate(ServHeader, DateCaption), ShowAll);
            OnAfterServLinePriceExists(ServLine);
            exit(TempSalesPrice.Find('-'));
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ServLineLineDiscExists(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        if (ServLine.Type = ServLine.Type::Item) and Item.Get(ServLine."No.") then begin
            IsHandled := false;
            OnBeforeServLineLineDiscExists(ServLine, ServHeader, TempSalesLineDisc, ShowAll, IsHandled);
            if not IsHandled then
                FindSalesLineDisc(
                  TempSalesLineDisc, ServLine."Bill-to Customer No.", ServHeader."Bill-to Contact No.",
                  ServLine."Customer Disc. Group", '', ServLine."No.", Item."Item Disc. Group", ServLine."Variant Code", ServLine."Unit of Measure Code",
                  ServHeader."Currency Code", ServHeaderStartDate(ServHeader, DateCaption), ShowAll);
            OnAfterServLineLineDiscExists(ServLine);
            exit(TempSalesLineDisc.Find('-'));
        end;
        exit(false);
    end;

    procedure ActivatedCampaignExists(var ToCampaignTargetGr: Record "Campaign Target Group"; CustNo: Code[20]; ContNo: Code[20]; CampaignNo: Code[20]): Boolean
    var
        FromCampaignTargetGr: Record "Campaign Target Group";
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        if not ToCampaignTargetGr.IsTemporary then
            Error(TempTableErr);

        IsHandled := false;
        OnBeforeActivatedCampaignExists(ToCampaignTargetGr, CustNo, ContNo, CampaignNo, IsHandled);
        if IsHandled then
            exit;

        ToCampaignTargetGr.Reset();
        ToCampaignTargetGr.DeleteAll();

        if CampaignNo <> '' then begin
            ToCampaignTargetGr."Campaign No." := CampaignNo;
            ToCampaignTargetGr.Insert();
        end else begin
            FromCampaignTargetGr.SetRange(Type, FromCampaignTargetGr.Type::Customer);
            FromCampaignTargetGr.SetRange("No.", CustNo);
            if FromCampaignTargetGr.FindSet() then
                repeat
                    ToCampaignTargetGr := FromCampaignTargetGr;
                    ToCampaignTargetGr.Insert();
                until FromCampaignTargetGr.Next() = 0
            else
                if Cont.Get(ContNo) then begin
                    FromCampaignTargetGr.SetRange(Type, FromCampaignTargetGr.Type::Contact);
                    FromCampaignTargetGr.SetRange("No.", Cont."Company No.");
                    if FromCampaignTargetGr.FindSet() then
                        repeat
                            ToCampaignTargetGr := FromCampaignTargetGr;
                            ToCampaignTargetGr.Insert();
                        until FromCampaignTargetGr.Next() = 0;
                end;
        end;
        exit(ToCampaignTargetGr.FindFirst())
    end;

    procedure SalesHeaderExchDate(SalesHeader: Record "Sales Header"): Date
    begin
        if SalesHeader."Posting Date" <> 0D then
            exit(SalesHeader."Posting Date");
        exit(WorkDate());
    end;

    procedure SalesHeaderStartDate(var SalesHeader: Record "Sales Header"; var DateCaption: Text[30]): Date
    var
        StartDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesHeaderStartDate(SalesHeader, DateCaption, StartDate, IsHandled);
        if IsHandled then
            exit(StartDate);

        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"] then begin
            DateCaption := SalesHeader.FieldCaption("Posting Date");
            exit(SalesHeader."Posting Date")
        end else begin
            DateCaption := SalesHeader.FieldCaption("Order Date");
            exit(SalesHeader."Order Date");
        end;
    end;

    procedure ServHeaderExchDate(ServHeader: Record Microsoft.Service.Document."Service Header"): Date
    begin
        if (ServHeader."Document Type" = ServHeader."Document Type"::Quote) and
           (ServHeader."Posting Date" = 0D)
        then
            exit(WorkDate());
        exit(ServHeader."Posting Date");
    end;

    procedure ServHeaderStartDate(ServHeader: Record Microsoft.Service.Document."Service Header"; var DateCaption: Text[30]): Date
    begin
        if ServHeader."Document Type" in [ServHeader."Document Type"::Invoice, ServHeader."Document Type"::"Credit Memo"] then begin
            DateCaption := ServHeader.FieldCaption("Posting Date");
            exit(ServHeader."Posting Date")
        end else begin
            DateCaption := ServHeader.FieldCaption("Order Date");
            exit(ServHeader."Order Date");
        end;
    end;

    procedure NoOfSalesLinePrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowAll: Boolean) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfSalesLinePrice(SalesHeader, SalesLine, ShowAll, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if SalesLinePriceExists(SalesHeader, SalesLine, ShowAll) then
            exit(TempSalesPrice.Count);
    end;

    procedure NoOfSalesLineLineDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowAll: Boolean) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfSalesLineLineDisc(SalesHeader, SalesLine, ShowAll, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if SalesLineLineDiscExists(SalesHeader, SalesLine, ShowAll) then
            exit(TempSalesLineDisc.Count);
    end;

    procedure NoOfServLinePrice(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line"; ShowAll: Boolean) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfServLinePrice(ServHeader, ServLine, ShowAll, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ServLinePriceExists(ServHeader, ServLine, ShowAll) then
            exit(TempSalesPrice.Count);
    end;

    procedure NoOfServLineLineDisc(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line"; ShowAll: Boolean) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfServLineLineDisc(ServHeader, ServLine, ShowAll, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ServLineLineDiscExists(ServHeader, ServLine, ShowAll) then
            exit(TempSalesLineDisc.Count);
    end;

    procedure FindJobPlanningLinePrice(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer)
    var
        Job: Record Job;
        BillToCustomerNo, BillToContactNo : Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindJobPlanningLinePrice(JobPlanningLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        SetCurrency(JobPlanningLine."Currency Code", JobPlanningLine."Currency Factor", JobPlanningLine."Planning Date");
        SetVAT(false, 0, 0, '');
        SetUoM(Abs(JobPlanningLine.Quantity), JobPlanningLine."Qty. per Unit of Measure");
        SetLineDisc(0, true, true);

        case JobPlanningLine.Type of
            JobPlanningLine.Type::Item:
                begin
                    Job.Get(JobPlanningLine."Job No.");
                    Item.Get(JobPlanningLine."No.");
                    JobPlanningLine.TestField("Qty. per Unit of Measure");
                    SetBillToCustomerDependingOnBillingMethod(Job, JobPlanningLine, BillToCustomerNo, BillToContactNo);
                    FindSalesPrice(
                      TempSalesPrice, BillToCustomerNo, BillToContactNo,
                      Job."Customer Price Group", '', JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code",
                      Job."Currency Code", JobPlanningLine."Planning Date", false);
                    CalcBestUnitPrice(TempSalesPrice);
                    if FoundSalesPrice or
                       not ((CalledByFieldNo = JobPlanningLine.FieldNo(Quantity)) or
                            (CalledByFieldNo = JobPlanningLine.FieldNo("Location Code")) or
                            (CalledByFieldNo = JobPlanningLine.FieldNo("Variant Code")))
                    then begin
                        JobPlanningLine."Unit Price" := TempSalesPrice."Unit Price";
                        AllowLineDisc := TempSalesPrice."Allow Line Disc.";
                    end;
                end;
            JobPlanningLine.Type::Resource:
                begin
                    Job.Get(JobPlanningLine."Job No.");
                    SetResPrice(JobPlanningLine."No.", JobPlanningLine."Work Type Code", JobPlanningLine."Currency Code");
                    CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResPrice);
                    IsHandled := false;
                    OnAfterFindJobPlanningLineResPrice(JobPlanningLine, ResPrice, CalledByFieldNo, AllowLineDisc, IsHandled);
                    if not IsHandled then begin
                        ConvertPriceLCYToFCY(ResPrice."Currency Code", ResPrice."Unit Price");
                        JobPlanningLine."Unit Price" := ResPrice."Unit Price" * JobPlanningLine."Qty. per Unit of Measure";
                    end;
                end;
        end;
        OnFindJobPlanningLinePriceOnBeforeJobPlanningLineFindJTPrice(JobPlanningLine, ResPrice);
        JobPlanningLineFindJTPrice(JobPlanningLine);
    end;

    procedure JobPlanningLineFindJTPrice(var JobPlanningLine: Record "Job Planning Line")
    var
        JobItemPrice: Record "Job Item Price";
        JobResPrice: Record "Job Resource Price";
        JobGLAccPrice: Record "Job G/L Account Price";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobPlanningLineFindJTPrice(JobPlanningLine, IsHandled);
        if IsHandled then
            exit;

        case JobPlanningLine.Type of
            JobPlanningLine.Type::Item:
                begin
                    JobItemPrice.SetRange("Job No.", JobPlanningLine."Job No.");
                    JobItemPrice.SetRange("Item No.", JobPlanningLine."No.");
                    JobItemPrice.SetRange("Variant Code", JobPlanningLine."Variant Code");
                    JobItemPrice.SetRange("Unit of Measure Code", JobPlanningLine."Unit of Measure Code");
                    JobItemPrice.SetRange("Currency Code", JobPlanningLine."Currency Code");
                    JobItemPrice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
                    OnJobPlanningLineFindJTPriceOnAfterSetJobItemPriceFilters(JobItemPrice, JobPlanningLine);
                    if JobItemPrice.FindFirst() then
                        CopyJobItemPriceToJobPlanLine(JobPlanningLine, JobItemPrice)
                    else begin
                        JobItemPrice.SetRange("Job Task No.", ' ');
                        if JobItemPrice.FindFirst() then
                            CopyJobItemPriceToJobPlanLine(JobPlanningLine, JobItemPrice);
                    end;

                    if JobItemPrice.IsEmpty() or (not JobItemPrice."Apply Job Discount") then
                        FindJobPlanningLineLineDisc(JobPlanningLine);
                end;
            JobPlanningLine.Type::Resource:
                begin
                    Res.Get(JobPlanningLine."No.");
                    JobResPrice.SetRange("Job No.", JobPlanningLine."Job No.");
                    JobResPrice.SetRange("Currency Code", JobPlanningLine."Currency Code");
                    JobResPrice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
                    OnJobPlanningLineFindJTPriceOnAfterSetJobResPriceFilters(JobResPrice, JobPlanningLine);
                    case true of
                        JobPlanningLineFindJobResPrice(JobPlanningLine, JobResPrice, JobResPrice.Type::Resource):
                            CopyJobResPriceToJobPlanLine(JobPlanningLine, JobResPrice);
                        JobPlanningLineFindJobResPrice(JobPlanningLine, JobResPrice, JobResPrice.Type::"Group(Resource)"):
                            CopyJobResPriceToJobPlanLine(JobPlanningLine, JobResPrice);
                        JobPlanningLineFindJobResPrice(JobPlanningLine, JobResPrice, JobResPrice.Type::All):
                            CopyJobResPriceToJobPlanLine(JobPlanningLine, JobResPrice);
                        else begin
                            JobResPrice.SetRange("Job Task No.", '');
                            case true of
                                JobPlanningLineFindJobResPrice(JobPlanningLine, JobResPrice, JobResPrice.Type::Resource):
                                    CopyJobResPriceToJobPlanLine(JobPlanningLine, JobResPrice);
                                JobPlanningLineFindJobResPrice(JobPlanningLine, JobResPrice, JobResPrice.Type::"Group(Resource)"):
                                    CopyJobResPriceToJobPlanLine(JobPlanningLine, JobResPrice);
                                JobPlanningLineFindJobResPrice(JobPlanningLine, JobResPrice, JobResPrice.Type::All):
                                    CopyJobResPriceToJobPlanLine(JobPlanningLine, JobResPrice);
                            end;
                        end;
                    end;
                end;
            JobPlanningLine.Type::"G/L Account":
                begin
                    JobGLAccPrice.SetRange("Job No.", JobPlanningLine."Job No.");
                    JobGLAccPrice.SetRange("G/L Account No.", JobPlanningLine."No.");
                    JobGLAccPrice.SetRange("Currency Code", JobPlanningLine."Currency Code");
                    JobGLAccPrice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
                    OnJobPlanningLineFindJTPriceOnAfterSetJobGLAccPriceFilters(JobGLAccPrice, JobPlanningLine);
                    if JobGLAccPrice.FindFirst() then
                        CopyJobGLAccPriceToJobPlanLine(JobPlanningLine, JobGLAccPrice)
                    else begin
                        JobGLAccPrice.SetRange("Job Task No.", '');
                        if JobGLAccPrice.FindFirst() then
                            CopyJobGLAccPriceToJobPlanLine(JobPlanningLine, JobGLAccPrice);
                    end;
                end;
        end;
    end;

    local procedure CopyJobItemPriceToJobPlanLine(var JobPlanningLine: Record "Job Planning Line"; JobItemPrice: Record "Job Item Price")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyJobItemPriceToJobPlanLine(JobPlanningLine, JobItemPrice, IsHandled);
        if IsHandled then
            exit;

        if JobItemPrice."Apply Job Price" then begin
            JobPlanningLine."Unit Price" := JobItemPrice."Unit Price";
            JobPlanningLine."Cost Factor" := JobItemPrice."Unit Cost Factor";
        end;
        if JobItemPrice."Apply Job Discount" then
            JobPlanningLine."Line Discount %" := JobItemPrice."Line Discount %";
    end;

    local procedure CopyJobResPriceToJobPlanLine(var JobPlanningLine: Record "Job Planning Line"; JobResPrice: Record "Job Resource Price")
    begin
        if JobResPrice."Apply Job Price" then begin
            JobPlanningLine."Unit Price" := JobResPrice."Unit Price" * JobPlanningLine."Qty. per Unit of Measure";
            JobPlanningLine."Cost Factor" := JobResPrice."Unit Cost Factor";
        end;
        if JobResPrice."Apply Job Discount" then
            JobPlanningLine."Line Discount %" := JobResPrice."Line Discount %";
    end;

    local procedure JobPlanningLineFindJobResPrice(var JobPlanningLine: Record "Job Planning Line"; var JobResPrice: Record "Job Resource Price"; PriceType: Option Resource,"Group(Resource)",All): Boolean
    begin
        case PriceType of
            PriceType::Resource:
                begin
                    JobResPrice.SetRange(Type, JobResPrice.Type::Resource);
                    JobResPrice.SetRange("Work Type Code", JobPlanningLine."Work Type Code");
                    JobResPrice.SetRange(Code, JobPlanningLine."No.");
                    exit(JobResPrice.Find('-'));
                end;
            PriceType::"Group(Resource)":
                begin
                    JobResPrice.SetRange(Type, JobResPrice.Type::"Group(Resource)");
                    JobResPrice.SetRange(Code, Res."Resource Group No.");
                    exit(FindJobResPrice(JobResPrice, JobPlanningLine."Work Type Code"));
                end;
            PriceType::All:
                begin
                    JobResPrice.SetRange(Type, JobResPrice.Type::All);
                    JobResPrice.SetRange(Code);
                    exit(FindJobResPrice(JobResPrice, JobPlanningLine."Work Type Code"));
                end;
        end;
    end;

    local procedure CopyJobGLAccPriceToJobPlanLine(var JobPlanningLine: Record "Job Planning Line"; JobGLAccPrice: Record "Job G/L Account Price")
    begin
        JobPlanningLine."Unit Cost" := JobGLAccPrice."Unit Cost";
        JobPlanningLine."Unit Price" := JobGLAccPrice."Unit Price" * JobPlanningLine."Qty. per Unit of Measure";
        JobPlanningLine."Cost Factor" := JobGLAccPrice."Unit Cost Factor";
        JobPlanningLine."Line Discount %" := JobGLAccPrice."Line Discount %";
    end;

    procedure FindJobJnlLinePrice(var JobJnlLine: Record "Job Journal Line"; CalledByFieldNo: Integer)
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindJobJnlLinePrice(JobJnlLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        SetCurrency(JobJnlLine."Currency Code", JobJnlLine."Currency Factor", JobJnlLine."Posting Date");
        SetVAT(false, 0, 0, '');
        SetUoM(Abs(JobJnlLine.Quantity), JobJnlLine."Qty. per Unit of Measure");

        case JobJnlLine.Type of
            JobJnlLine.Type::Item:
                begin
                    Item.Get(JobJnlLine."No.");
                    JobJnlLine.TestField("Qty. per Unit of Measure");
                    Job.Get(JobJnlLine."Job No.");

                    FindSalesPrice(
                      TempSalesPrice, Job."Bill-to Customer No.", Job."Bill-to Contact No.",
                      JobJnlLine."Customer Price Group", '', JobJnlLine."No.", JobJnlLine."Variant Code", JobJnlLine."Unit of Measure Code",
                      JobJnlLine."Currency Code", JobJnlLine."Posting Date", false);
                    CalcBestUnitPrice(TempSalesPrice);
                    if FoundSalesPrice or
                       not ((CalledByFieldNo = JobJnlLine.FieldNo(Quantity)) or
                            (CalledByFieldNo = JobJnlLine.FieldNo("Variant Code")))
                    then
                        JobJnlLine."Unit Price" := TempSalesPrice."Unit Price";
                end;
            JobJnlLine.Type::Resource:
                begin
                    IsHandled := false;
                    OnFindJobJnlLinePriceOnBeforeResourceGetJob(JobJnlLine, IsHandled);
                    if not IsHandled then
                        Job.Get(JobJnlLine."Job No.");
                    SetResPrice(JobJnlLine."No.", JobJnlLine."Work Type Code", JobJnlLine."Currency Code");
                    OnBeforeFindJobJnlLineResPrice(JobJnlLine, ResPrice);
                    CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResPrice);
                    IsHandled := false;
                    OnAfterFindJobJnlLineResPrice(JobJnlLine, ResPrice, CalledByFieldNo, IsHandled);
                    if not IsHandled then begin
                        ConvertPriceLCYToFCY(ResPrice."Currency Code", ResPrice."Unit Price");
                        JobJnlLine."Unit Price" := ResPrice."Unit Price" * JobJnlLine."Qty. per Unit of Measure";
                    end;
                end;
        end;
        OnFindJobJnlLinePriceOnBeforeJobJnlLineFindJTPrice(JobJnlLine);
        JobJnlLineFindJTPrice(JobJnlLine);
    end;

    local procedure JobJnlLineFindJobResPrice(var JobJnlLine: Record "Job Journal Line"; var JobResPrice: Record "Job Resource Price"; PriceType: Option Resource,"Group(Resource)",All): Boolean
    begin
        case PriceType of
            PriceType::Resource:
                begin
                    JobResPrice.SetRange(Type, JobResPrice.Type::Resource);
                    JobResPrice.SetRange("Work Type Code", JobJnlLine."Work Type Code");
                    JobResPrice.SetRange(Code, JobJnlLine."No.");
                    exit(JobResPrice.Find('-'));
                end;
            PriceType::"Group(Resource)":
                begin
                    JobResPrice.SetRange(Type, JobResPrice.Type::"Group(Resource)");
                    JobResPrice.SetRange(Code, Res."Resource Group No.");
                    exit(FindJobResPrice(JobResPrice, JobJnlLine."Work Type Code"));
                end;
            PriceType::All:
                begin
                    JobResPrice.SetRange(Type, JobResPrice.Type::All);
                    JobResPrice.SetRange(Code);
                    exit(FindJobResPrice(JobResPrice, JobJnlLine."Work Type Code"));
                end;
        end;
    end;

    local procedure CopyJobResPriceToJobJnlLine(var JobJnlLine: Record "Job Journal Line"; JobResPrice: Record "Job Resource Price")
    begin
        if JobResPrice."Apply Job Price" then begin
            JobJnlLine."Unit Price" := JobResPrice."Unit Price" * JobJnlLine."Qty. per Unit of Measure";
            JobJnlLine."Cost Factor" := JobResPrice."Unit Cost Factor";
        end;
        if JobResPrice."Apply Job Discount" then
            JobJnlLine."Line Discount %" := JobResPrice."Line Discount %";

        OnAfterCopyJobResPriceToJobJnlLine(JobJnlLine);
    end;

    local procedure CopyJobGLAccPriceToJobJnlLine(var JobJnlLine: Record "Job Journal Line"; JobGLAccPrice: Record "Job G/L Account Price")
    begin
        JobJnlLine."Unit Cost" := JobGLAccPrice."Unit Cost";
        JobJnlLine."Unit Price" := JobGLAccPrice."Unit Price" * JobJnlLine."Qty. per Unit of Measure";
        JobJnlLine."Cost Factor" := JobGLAccPrice."Unit Cost Factor";
        JobJnlLine."Line Discount %" := JobGLAccPrice."Line Discount %";
    end;

    procedure JobJnlLineFindJTPrice(var JobJnlLine: Record "Job Journal Line")
    var
        JobItemPrice: Record "Job Item Price";
        JobResPrice: Record "Job Resource Price";
        JobGLAccPrice: Record "Job G/L Account Price";
    begin
        case JobJnlLine.Type of
            JobJnlLine.Type::Item:
                begin
                    JobItemPrice.SetRange("Job No.", JobJnlLine."Job No.");
                    JobItemPrice.SetRange("Item No.", JobJnlLine."No.");
                    JobItemPrice.SetRange("Variant Code", JobJnlLine."Variant Code");
                    JobItemPrice.SetRange("Unit of Measure Code", JobJnlLine."Unit of Measure Code");
                    JobItemPrice.SetRange("Currency Code", JobJnlLine."Currency Code");
                    JobItemPrice.SetRange("Job Task No.", JobJnlLine."Job Task No.");
                    OnJobJnlLineFindJTPriceOnAfterSetJobItemPriceFilters(JobItemPrice, JobJnlLine);
                    if JobItemPrice.FindFirst() then
                        CopyJobItemPriceToJobJnlLine(JobJnlLine, JobItemPrice)
                    else begin
                        JobItemPrice.SetRange("Job Task No.", ' ');
                        if JobItemPrice.FindFirst() then
                            CopyJobItemPriceToJobJnlLine(JobJnlLine, JobItemPrice);
                    end;
                    if JobItemPrice.IsEmpty() or (not JobItemPrice."Apply Job Discount") then
                        FindJobJnlLineLineDisc(JobJnlLine);
                    OnAfterJobJnlLineFindJTPriceItem(JobJnlLine);
                end;
            JobJnlLine.Type::Resource:
                begin
                    Res.Get(JobJnlLine."No.");
                    JobResPrice.SetRange("Job No.", JobJnlLine."Job No.");
                    JobResPrice.SetRange("Currency Code", JobJnlLine."Currency Code");
                    JobResPrice.SetRange("Job Task No.", JobJnlLine."Job Task No.");
                    case true of
                        JobJnlLineFindJobResPrice(JobJnlLine, JobResPrice, JobResPrice.Type::Resource):
                            CopyJobResPriceToJobJnlLine(JobJnlLine, JobResPrice);
                        JobJnlLineFindJobResPrice(JobJnlLine, JobResPrice, JobResPrice.Type::"Group(Resource)"):
                            CopyJobResPriceToJobJnlLine(JobJnlLine, JobResPrice);
                        JobJnlLineFindJobResPrice(JobJnlLine, JobResPrice, JobResPrice.Type::All):
                            CopyJobResPriceToJobJnlLine(JobJnlLine, JobResPrice);
                        else begin
                            JobResPrice.SetRange("Job Task No.", '');
                            case true of
                                JobJnlLineFindJobResPrice(JobJnlLine, JobResPrice, JobResPrice.Type::Resource):
                                    CopyJobResPriceToJobJnlLine(JobJnlLine, JobResPrice);
                                JobJnlLineFindJobResPrice(JobJnlLine, JobResPrice, JobResPrice.Type::"Group(Resource)"):
                                    CopyJobResPriceToJobJnlLine(JobJnlLine, JobResPrice);
                                JobJnlLineFindJobResPrice(JobJnlLine, JobResPrice, JobResPrice.Type::All):
                                    CopyJobResPriceToJobJnlLine(JobJnlLine, JobResPrice);
                            end;
                        end;
                    end;
                    OnAfterJobJnlLineFindJTPriceResource(JobJnlLine);
                end;
            JobJnlLine.Type::"G/L Account":
                begin
                    JobGLAccPrice.SetRange("Job No.", JobJnlLine."Job No.");
                    JobGLAccPrice.SetRange("G/L Account No.", JobJnlLine."No.");
                    JobGLAccPrice.SetRange("Currency Code", JobJnlLine."Currency Code");
                    JobGLAccPrice.SetRange("Job Task No.", JobJnlLine."Job Task No.");
                    if JobGLAccPrice.FindFirst() then
                        CopyJobGLAccPriceToJobJnlLine(JobJnlLine, JobGLAccPrice)
                    else begin
                        JobGLAccPrice.SetRange("Job Task No.", '');
                        if JobGLAccPrice.FindFirst() then;
                        CopyJobGLAccPriceToJobJnlLine(JobJnlLine, JobGLAccPrice);
                    end;
                    OnAfterJobJnlLineFindJTPriceGLAccount(JobJnlLine);
                end;
        end;
    end;

    local procedure CopyJobItemPriceToJobJnlLine(var JobJnlLine: Record "Job Journal Line"; JobItemPrice: Record "Job Item Price")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyJobItemPriceToJobJnlLine(JobJnlLine, JobItemPrice, IsHandled);
        if IsHandled then
            exit;

        if JobItemPrice."Apply Job Price" then begin
            JobJnlLine."Unit Price" := JobItemPrice."Unit Price";
            JobJnlLine."Cost Factor" := JobItemPrice."Unit Cost Factor";
        end;
        if JobItemPrice."Apply Job Discount" then
            JobJnlLine."Line Discount %" := JobItemPrice."Line Discount %";
    end;

    local procedure FindJobPlanningLineLineDisc(var JobPlanningLine: Record "Job Planning Line")
    begin
        SetCurrency(JobPlanningLine."Currency Code", JobPlanningLine."Currency Factor", JobPlanningLine."Planning Date");
        SetUoM(Abs(JobPlanningLine.Quantity), JobPlanningLine."Qty. per Unit of Measure");
        JobPlanningLine.TestField("Qty. per Unit of Measure");
        if JobPlanningLine.Type = JobPlanningLine.Type::Item then begin
            JobPlanningLineLineDiscExists(JobPlanningLine, false);
            CalcBestLineDisc(TempSalesLineDisc);
            if AllowLineDisc then
                JobPlanningLine."Line Discount %" := TempSalesLineDisc."Line Discount %"
            else
                JobPlanningLine."Line Discount %" := 0;
        end;

        OnAfterFindJobPlanningLineLineDisc(JobPlanningLine, TempSalesLineDisc);
    end;

    local procedure JobPlanningLineLineDiscExists(var JobPlanningLine: Record "Job Planning Line"; ShowAll: Boolean): Boolean
    var
        Job: Record Job;
    begin
        if (JobPlanningLine.Type = JobPlanningLine.Type::Item) and Item.Get(JobPlanningLine."No.") then begin
            Job.Get(JobPlanningLine."Job No.");
            OnBeforeJobPlanningLineLineDiscExists(JobPlanningLine);
            FindSalesLineDisc(
              TempSalesLineDisc, Job."Bill-to Customer No.", Job."Bill-to Contact No.",
              Job."Customer Disc. Group", '', JobPlanningLine."No.", Item."Item Disc. Group", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code",
              JobPlanningLine."Currency Code", JobPlanningLineStartDate(JobPlanningLine, DateCaption), ShowAll);
            OnAfterJobPlanningLineLineDiscExists(JobPlanningLine);
            exit(TempSalesLineDisc.Find('-'));
        end;
        exit(false);
    end;

    local procedure JobPlanningLineStartDate(JobPlanningLine: Record "Job Planning Line"; var DateCaption: Text[30]): Date
    begin
        DateCaption := JobPlanningLine.FieldCaption("Planning Date");
        exit(JobPlanningLine."Planning Date");
    end;

    local procedure FindJobJnlLineLineDisc(var JobJnlLine: Record "Job Journal Line")
    begin
        SetCurrency(JobJnlLine."Currency Code", JobJnlLine."Currency Factor", JobJnlLine."Posting Date");
        SetUoM(Abs(JobJnlLine.Quantity), JobJnlLine."Qty. per Unit of Measure");
        JobJnlLine.TestField("Qty. per Unit of Measure");
        if JobJnlLine.Type = JobJnlLine.Type::Item then begin
            JobJnlLineLineDiscExists(JobJnlLine, false);
            CalcBestLineDisc(TempSalesLineDisc);
            JobJnlLine."Line Discount %" := TempSalesLineDisc."Line Discount %";
        end;

        OnAfterFindJobJnlLineLineDisc(JobJnlLine, TempSalesLineDisc);
    end;

    local procedure JobJnlLineLineDiscExists(var JobJnlLine: Record "Job Journal Line"; ShowAll: Boolean): Boolean
    var
        Job: Record Job;
    begin
        if (JobJnlLine.Type = JobJnlLine.Type::Item) and Item.Get(JobJnlLine."No.") then begin
            Job.Get(JobJnlLine."Job No.");
            OnBeforeJobJnlLineLineDiscExists(JobJnlLine);
            FindSalesLineDisc(
              TempSalesLineDisc, Job."Bill-to Customer No.", Job."Bill-to Contact No.",
              Job."Customer Disc. Group", '', JobJnlLine."No.", Item."Item Disc. Group", JobJnlLine."Variant Code", JobJnlLine."Unit of Measure Code",
              JobJnlLine."Currency Code", JobJnlLineStartDate(JobJnlLine, DateCaption), ShowAll);
            OnAfterJobJnlLineLineDiscExists(JobJnlLine);
            exit(TempSalesLineDisc.Find('-'));
        end;
        exit(false);
    end;

    local procedure JobJnlLineStartDate(JobJnlLine: Record "Job Journal Line"; var DateCaption: Text[30]): Date
    begin
        DateCaption := JobJnlLine.FieldCaption("Posting Date");
        exit(JobJnlLine."Posting Date");
    end;

    local procedure FindJobResPrice(var JobResPrice: Record "Job Resource Price"; WorkTypeCode: Code[10]): Boolean
    begin
        JobResPrice.SetRange("Work Type Code", WorkTypeCode);
        if JobResPrice.FindFirst() then
            exit(true);
        JobResPrice.SetRange("Work Type Code", '');
        exit(JobResPrice.FindFirst())
    end;

    procedure FindResPrice(var ResJournalLine: Record "Res. Journal Line")
    begin
        GLSetup.Get();
        ResPrice.Init();
        ResPrice.Code := ResJournalLine."Resource No.";
        ResPrice."Work Type Code" := ResJournalLine."Work Type Code";
        ResJournalLine.BeforeFindResPrice(ResPrice);
        CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResPrice);
        ResJournalLine.AfterFindResPrice(ResPrice);
        ResJournalLine."Unit Price" :=
            Round(ResPrice."Unit Price" * ResJournalLine."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
        ResJournalLine.Validate("Unit Price");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBestUnitPrice(var SalesPrice: Record "Sales Price"; var BestSalesPrice: Record "Sales Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBestUnitPriceAsItemUnitPrice(var SalesPrice: Record "Sales Price"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(SalesPrice: Record "Sales Price"; var LineAmount: Decimal; var LineDiscPerCent: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyJobResPriceToJobJnlLine(var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindItemJnlLinePrice(var ItemJournalLine: Record "Item Journal Line"; var SalesPrice: Record "Sales Price"; CalledByFieldNo: Integer; FoundSalesPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobJnlLineResPrice(var JobJournalLine: Record "Job Journal Line"; var ResourcePrice: Record "Resource Price"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobJnlLineLineDisc(var JobJournalLine: Record "Job Journal Line"; var TempSalesLineDisc: Record "Sales Line Discount" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobPlanningLineLineDisc(var JobPlanningLine: Record "Job Planning Line"; var TempSalesLineDisc: Record "Sales Line Discount" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobPlanningLineResPrice(var JobPlanningLine: Record "Job Planning Line"; var ResourcePrice: Record "Resource Price"; CalledByFieldNo: Integer; var AllowLineDisc: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindStdItemJnlLinePrice(var StdItemJnlLine: Record "Standard Item Journal Line"; var SalesPrice: Record "Sales Price"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindSalesLinePrice(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var SalesPrice: Record "Sales Price"; var ResourcePrice: Record "Resource Price"; CalledByFieldNo: Integer; FoundSalesPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindSalesLineLineDisc(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var SalesLineDiscount: Record "Sales Line Discount")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindSalesPrice(var ToSalesPrice: Record "Sales Price"; var FromSalesPrice: Record "Sales Price"; QtyPerUOM: Decimal; Qty: Decimal; CustNo: Code[20]; ContNo: Code[20]; CustPriceGrCode: Code[10]; CampaignNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindSalesLineItemPrice(var SalesLine: Record "Sales Line"; var TempSalesPrice: Record "Sales Price" temporary; var FoundSalesPrice: Boolean; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindSalesLineResPrice(var SalesLine: Record "Sales Line"; var ResPrice: Record "Resource Price"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindSalesLineDisc(var ToSalesLineDisc: Record "Sales Line Discount"; CustNo: Code[20]; ContNo: Code[20]; CustDiscGrCode: Code[20]; CampaignNo: Code[20]; ItemNo: Code[20]; ItemDiscGrCode: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindServLinePrice(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var SalesPrice: Record "Sales Price"; var ResourcePrice: Record "Resource Price"; var ServiceCost: Record Microsoft.Service.Pricing."Service Cost"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindServLineResPrice(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ResPrice: Record "Resource Price"; var HideResUnitPriceMessage: Boolean; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindServLineDisc(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var SalesLineDiscount: Record "Sales Line Discount")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesLinePrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempSalesPrice: Record "Sales Price" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesLineLineDisc(var SalesLine: Record "Sales Line"; var SalesLineDiscount: Record "Sales Line Discount")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobJnlLineFindJTPriceGLAccount(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobJnlLineFindJTPriceItem(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobJnlLineFindJTPriceResource(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobJnlLineLineDiscExists(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobPlanningLineLineDiscExists(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineLineDiscExists(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var TempSalesLineDisc: Record "Sales Line Discount" temporary; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLinePriceExists(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var TempSalesPrice: Record "Sales Price" temporary; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLinePriceExistsProcedure(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Res: Record Resource; var DateCaption: Text[30]; var ShowAll: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServLinePriceExists(var ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServLineLineDiscExists(var ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeActivatedCampaignExists(var ToCampaignTargetGr: Record "Campaign Target Group"; CustNo: Code[20]; ContNo: Code[20]; CampaignNo: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBestLineDisc(var SalesLineDisc: Record "Sales Line Discount"; Item: Record Item; var IsHandled: Boolean; QtyPerUOM: Decimal; Qty: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBestUnitPrice(var SalesPrice: Record "Sales Price"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertPriceToVAT(var VATPostingSetup: Record "VAT Posting Setup"; var UnitPrice: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyJobItemPriceToJobJnlLine(var JobJnlLine: Record "Job Journal Line"; JobItemPrice: Record "Job Item Price"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyJobItemPriceToJobPlanLine(var JobPlanningLine: Record "Job Planning Line"; JobItemPrice: Record "Job Item Price"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesPriceToSalesPrice(var FromSalesPrice: Record "Sales Price"; var ToSalesPrice: Record "Sales Price"; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindAnalysisReportPrice(ItemNo: Code[20]; Date: Date; var UnitPrice: Decimal; var IsHandled: Boolean; var FoundSalesPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemJnlLinePrice(var ItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindJobJnlLinePrice(var JobJournalLine: Record "Job Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindJobPlanningLinePrice(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindJobJnlLineResPrice(var JobJournalLine: Record "Job Journal Line"; var ResourcePrice: Record "Resource Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesPrice(var ToSalesPrice: Record "Sales Price"; var FromSalesPrice: Record "Sales Price"; var QtyPerUOM: Decimal; var Qty: Decimal; var CustNo: Code[20]; var ContNo: Code[20]; var CustPriceGrCode: Code[10]; var CampaignNo: Code[20]; var ItemNo: Code[20]; var VariantCode: Code[10]; var UOM: Code[10]; var CurrencyCode: Code[10]; var StartingDate: Date; var ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLinePrice(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLineDisc(var ToSalesLineDisc: Record "Sales Line Discount"; var CustNo: Code[20]; ContNo: Code[20]; var CustDiscGrCode: Code[20]; var CampaignNo: Code[20]; var ItemNo: Code[20]; var ItemDiscGrCode: Code[20]; var VariantCode: Code[10]; var UOM: Code[10]; var CurrencyCode: Code[10]; var StartingDate: Date; var ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLineLineDisc(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServLinePrice(var ServiceLine: Record Microsoft.Service.Document."Service Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServLineDisc(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindStdItemJnlLinePrice(var StandardItemJournalLine: Record "Standard Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesLinePrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesLineLineDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetServLinePrice(ServHeader: Record Microsoft.Service.Document."Service Header"; var ServLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetServLineDisc(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobJnlLineLineDiscExists(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobPlanningLineLineDiscExists(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobPlanningLineFindJTPrice(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderStartDate(var SalesHeader: Record "Sales Header"; var DateCaption: Text[30]; var StartDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfSalesLineLineDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowAll: Boolean; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfSalesLinePrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowAll: Boolean; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfServLineLineDisc(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; ShowAll: Boolean; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfServLinePrice(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; ShowAll: Boolean; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineLineDiscExists(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var TempSalesLineDisc: Record "Sales Line Discount" temporary; StartingDate: Date; Qty: Decimal; QtyPerUOM: Decimal; ShowAll: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLinePriceExists(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var TempSalesPrice: Record "Sales Price" temporary; Currency: Record Currency; CurrencyFactor: Decimal; StartingDate: Date; Qty: Decimal; QtyPerUOM: Decimal; ShowAll: Boolean; var InHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLinePriceExistsProcedure(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowAll: Boolean; var TempSalesPrice: Record "Sales Price" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLinePriceExists(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TempSalesPrice: Record "Sales Price" temporary; ShowAll: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLineLineDiscExists(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TempSalesLineDisc: Record "Sales Line Discount" temporary; ShowAll: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCustNoForSalesHeader(var SalesHeader: Record "Sales Header"; var CustomerNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobJnlLinePriceOnBeforeJobJnlLineFindJTPrice(var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobJnlLinePriceOnBeforeResourceGetJob(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesLineDiscOnAfterSetFilters(var SalesLineDiscount: Record "Sales Line Discount")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesLineLineDiscOnBeforeCalcLineDisc(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempSalesLineDiscount: Record "Sales Line Discount" temporary; Qty: Decimal; QtyPerUOM: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobJnlLineFindJTPriceOnAfterSetJobItemPriceFilters(var JobItemPrice: Record "Job Item Price"; JobJnlLine: Record "Job Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobPlanningLineFindJTPriceOnAfterSetJobGLAccPriceFilters(var JobItemPrice: Record "Job G/L Account Price"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobPlanningLineFindJTPriceOnAfterSetJobItemPriceFilters(var JobItemPrice: Record "Job Item Price"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobPlanningLineFindJTPriceOnAfterSetJobResPriceFilters(var JobResPrice: Record "Job Resource Price"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobPlanningLinePriceOnBeforeJobPlanningLineFindJTPrice(var JobPlanningLine: Record "Job Planning Line"; var ResPrice: Record "Resource Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesLinePriceOnAfterSetResPrice(var SalesLine: Record "Sales Line"; var ResPrice: Record "Resource Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesLinePriceOnAfterSetLineDisc(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesLinePriceOnItemTypeOnAfterSetUnitPrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempSalesPrice: Record "Sales Price" temporary; CalledByFieldNo: Integer; FoundSalesPrice: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcBestUnitPriceConvertPrice(var SalesPrice: Record "Sales Price"; var IsHandled: Boolean; Item: Record "Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBestUnitPriceOnBeforeCalcBestUnitPriceConvertPrice(var SalesPrice: Record "Sales Price"; Qty: Decimal; var IsHandled: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetResPriceOnAfterInit(var ResourcePrice: Record "Resource Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesLinePriceOnCalcBestUnitPrice(SalesLine: Record "Sales Line"; var TempSalesPrice: Record "Sales Price" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineDiscountOnSalesLine(var SalesLine: Record "Sales Line"; var SalesLineDiscount: Record "Sales Line Discount" temporary; var IsHandled: Boolean)
    begin
    end;
}
