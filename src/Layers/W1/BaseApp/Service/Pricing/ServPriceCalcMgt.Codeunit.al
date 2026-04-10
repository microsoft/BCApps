// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using Microsoft.Service.Pricing;

codeunit 6087 "Serv. Price Calc. Mgt."
{
    var
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        ResPrice: Record "Resource Price";
        Currency: Record Currency;
        TempSalesPrice: Record "Sales Price" temporary;
        TempSalesLineDisc: Record "Sales Line Discount" temporary;
        LineDiscPerCent: Decimal;
        Qty: Decimal;
        AllowLineDisc: Boolean;
        AllowInvDisc: Boolean;
        VATPerCent: Decimal;
        PricesInclVAT: Boolean;
        VATCalcType: Enum "Tax Calculation Type";
        VATBusPostingGr: Code[20];
        QtyPerUOM: Decimal;
        PricesInCurrency: Boolean;
        CurrencyFactor: Decimal;
        ExchRateDate: Date;
        FoundSalesPrice: Boolean;
        HideResUnitPriceMessage: Boolean;
        DateCaption: Text;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 is less than %2 in the %3.';
        Text010: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        Text018: Label '%1 %2 is greater than %3 and was adjusted to %4.';
        Text001: Label 'The %1 in the %2 must be same as in the %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TempTableErr: Label 'The table passed as a parameter must be temporary.';

    procedure FindServLinePrice(ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; CalledByFieldNo: Integer)
    var
        ServCost: Record "Service Cost";
        Res: Record Resource;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindServLinePrice(ServLine, ServHeader, CalledByFieldNo, IsHandled);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeFindServLinePrice(ServLine, ServHeader, CalledByFieldNo, IsHandled);
#endif
        if IsHandled then
            exit;

        ServHeader.Get(ServLine."Document Type", ServLine."Document No.");
        if ServLine.Type <> ServLine.Type::" " then begin
            SetCurrency(
              ServHeader."Currency Code", ServHeader."Currency Factor", ServHeaderExchDate(ServHeader));
            SetVAT(ServHeader."Prices Including VAT", ServLine."VAT %", ServLine."VAT Calculation Type", ServLine."VAT Bus. Posting Group");
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
#if not CLEAN28
                    SalesPriceCalcMgt.RunOnAfterFindServLineResPrice(ServLine, ResPrice, HideResUnitPriceMessage, CalledByFieldNo, IsHandled);
#endif
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnAfterFindServLinePrice(ServLine, ServHeader, TempSalesPrice, ResPrice, ServCost, CalledByFieldNo);
#endif
    end;

    procedure FindServLineDisc(ServHeader: Record "Service Header"; var ServLine: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindServLineDisc(ServHeader, ServLine, IsHandled);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeFindServLineDisc(ServHeader, ServLine, IsHandled);
#endif
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnAfterFindServLineDisc(ServLine, ServHeader, TempSalesLineDisc);
#endif
    end;

    procedure CalcBestUnitPrice(var SalesPrice: Record "Sales Price")
    var
        BestSalesPrice: Record "Sales Price";
        BestSalesPriceFound: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCalcBestUnitPrice(SalesPrice, IsHandled);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeCalcBestUnitPrice(SalesPrice, IsHandled);
#endif
        if IsHandled then
            exit;

        FoundSalesPrice := SalesPrice.FindSet();
        if FoundSalesPrice then
            repeat
                IsHandled := false;
                OnCalcBestUnitPriceOnBeforeCalcBestUnitPriceConvertPrice(SalesPrice, Qty, IsHandled, Item);
#if not CLEAN28
                SalesPriceCalcMgt.RunOnCalcBestUnitPriceOnBeforeCalcBestUnitPriceConvertPrice(SalesPrice, Qty, IsHandled, Item);
#endif
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnAfterCalcBestUnitPrice(SalesPrice, BestSalesPrice);
#endif

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
#if not CLEAN28
            SalesPriceCalcMgt.RunOnAfterCalcBestUnitPriceAsItemUnitPrice(BestSalesPrice, Item);
#endif
        end;

        SalesPrice := BestSalesPrice;
    end;

    local procedure CalcBestUnitPriceConvertPrice(var SalesPrice: Record "Sales Price")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBestUnitPriceConvertPrice(SalesPrice, IsHandled, Item);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeCalcBestUnitPriceConvertPrice(SalesPrice, IsHandled, Item);
#endif
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeCalcBestLineDisc(SalesLineDisc, Item, IsHandled, QtyPerUOM, Qty);
#endif
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeFindSalesPrice(
          ToSalesPrice, FromSalesPrice, QtyPerUOM, Qty, CustNo, ContNo, CustPriceGrCode, CampaignNo,
          ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll);
#endif

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
            if SalesPriceCalcMgt.ActivatedCampaignExists(TempTargetCampaignGr, CustNo, ContNo, CampaignNo) then
                repeat
                    FromSalesPrice.SetRange("Sales Code", TempTargetCampaignGr."Campaign No.");
                    CopySalesPriceToSalesPrice(FromSalesPrice, ToSalesPrice);
                until TempTargetCampaignGr.Next() = 0;
        end;

        OnAfterFindSalesPrice(
          ToSalesPrice, FromSalesPrice, QtyPerUOM, Qty, CustNo, ContNo, CustPriceGrCode, CampaignNo,
          ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnAfterFindSalesPrice(
          ToSalesPrice, FromSalesPrice, QtyPerUOM, Qty, CustNo, ContNo, CustPriceGrCode, CampaignNo,
          ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll);
#endif
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeFindSalesLineDisc(
          ToSalesLineDisc, CustNo, ContNo, CustDiscGrCode, CampaignNo, ItemNo, ItemDiscGrCode, VariantCode, UOM,
          CurrencyCode, StartingDate, ShowAll);
#endif

        FromSalesLineDisc.SetFilter("Ending Date", '%1|>=%2', 0D, StartingDate);
        FromSalesLineDisc.SetFilter("Variant Code", '%1|%2', VariantCode, '');
        OnFindSalesLineDiscOnAfterSetFilters(FromSalesLineDisc);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnFindSalesLineDiscOnAfterSetFilters(FromSalesLineDisc);
#endif
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
                            InclCampaigns := SalesPriceCalcMgt.ActivatedCampaignExists(TempCampaignTargetGr, CustNo, ContNo, CampaignNo);
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnAfterFindSalesLineDisc(
          ToSalesLineDisc, CustNo, ContNo, CustDiscGrCode, CampaignNo, ItemNo, ItemDiscGrCode, VariantCode, UOM,
          CurrencyCode, StartingDate, ShowAll);
#endif
    end;

    procedure FindResUnitCost(var ServiceLine: Record "Service Line")
    var
        ResCost: Record "Resource Cost";
    begin
        ResCost.Init();
        ResCost.Code := ServiceLine."No.";
        ResCost."Work Type Code" := ServiceLine."Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        ServiceLine.AfterResourseFindCost(ResCost);
        ServiceLine.Validate("Unit Cost (LCY)", ResCost."Unit Cost" * ServiceLine."Qty. per Unit of Measure");
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeCopySalesPriceToSalesPrice(FromSalesPrice, ToSalesPrice, IsHandled);
#endif
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnSetResPriceOnAfterInit(ResPrice);
#endif
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

    procedure SetVAT(PriceInclVAT2: Boolean; VATPerCent2: Decimal; VATCalcType2: Enum "Tax Calculation Type"; VATBusPostingGr2: Code[20])
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
#if not CLEAN28
            SalesPriceCalcMgt.RunOnBeforeConvertPriceToVAT(VATPostingSetup, UnitPrice, IsHandled);
#endif
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
#if not CLEAN28
        SalesPriceCalcMgt.RunOnAfterCalcLineAmount(SalesPrice, LineAmount, LineDiscPerCent);
#endif
    end;

    procedure GetServLinePrice(ServHeader: Record "Service Header"; var ServLine: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetServLinePrice(ServHeader, ServLine, IsHandled);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeGetServLinePrice(ServHeader, ServLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ServLinePriceExists(ServHeader, ServLine, true);

        if PAGE.RunModal(PAGE::"Get Sales Price", TempSalesPrice) = ACTION::LookupOK then begin
            SetVAT(
              ServHeader."Prices Including VAT", ServLine."VAT %", ServLine."VAT Calculation Type", ServLine."VAT Bus. Posting Group");
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

    procedure GetServLineLineDisc(ServHeader: Record "Service Header"; var ServLine: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetServLineDisc(ServHeader, ServLine, IsHandled);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeGetServLineDisc(ServHeader, ServLine, IsHandled);
#endif
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

    [Scope('OnPrem')]
    procedure ServLinePriceExists(ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        if (ServLine.Type = ServLine.Type::Item) and Item.Get(ServLine."No.") then begin
            IsHandled := false;
            OnBeforeServLinePriceExists(ServLine, ServHeader, TempSalesPrice, ShowAll, IsHandled);
#if not CLEAN28
            SalesPriceCalcMgt.RunOnBeforeServLinePriceExists(ServLine, ServHeader, TempSalesPrice, ShowAll, IsHandled);
#endif
            if not IsHandled then
                FindSalesPrice(
                  TempSalesPrice, ServLine."Bill-to Customer No.", ServHeader."Bill-to Contact No.",
                  ServLine."Customer Price Group", '', ServLine."No.", ServLine."Variant Code", ServLine."Unit of Measure Code",
                  ServHeader."Currency Code", ServHeaderStartDate(ServHeader, DateCaption), ShowAll);
            OnAfterServLinePriceExists(ServLine);
#if not CLEAN28
            SalesPriceCalcMgt.RunOnAfterServLinePriceExists(ServLine);
#endif
            exit(TempSalesPrice.Find('-'));
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ServLineLineDiscExists(ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        if (ServLine.Type = ServLine.Type::Item) and Item.Get(ServLine."No.") then begin
            IsHandled := false;
            OnBeforeServLineLineDiscExists(ServLine, ServHeader, TempSalesLineDisc, ShowAll, IsHandled);
#if not CLEAN28
            SalesPriceCalcMgt.RunOnBeforeServLineLineDiscExists(ServLine, ServHeader, TempSalesLineDisc, ShowAll, IsHandled);
#endif
            if not IsHandled then
                FindSalesLineDisc(
                  TempSalesLineDisc, ServLine."Bill-to Customer No.", ServHeader."Bill-to Contact No.",
                  ServLine."Customer Disc. Group", '', ServLine."No.", Item."Item Disc. Group", ServLine."Variant Code", ServLine."Unit of Measure Code",
                  ServHeader."Currency Code", ServHeaderStartDate(ServHeader, DateCaption), ShowAll);
            OnAfterServLineLineDiscExists(ServLine);
#if not CLEAN28
            SalesPriceCalcMgt.RunOnAfterServLineLineDiscExists(ServLine);
#endif
            exit(TempSalesLineDisc.Find('-'));
        end;
        exit(false);
    end;

    procedure ServHeaderExchDate(ServHeader: Record "Service Header"): Date
    begin
        if (ServHeader."Document Type" = ServHeader."Document Type"::Quote) and
           (ServHeader."Posting Date" = 0D)
        then
            exit(WorkDate());
        exit(ServHeader."Posting Date");
    end;

    procedure ServHeaderStartDate(ServHeader: Record "Service Header"; var DateCaption2: Text): Date
    begin
        if ServHeader."Document Type" in [ServHeader."Document Type"::Invoice, ServHeader."Document Type"::"Credit Memo"] then begin
            DateCaption2 := ServHeader.FieldCaption("Posting Date");
            exit(ServHeader."Posting Date")
        end else begin
            DateCaption2 := ServHeader.FieldCaption("Order Date");
            exit(ServHeader."Order Date");
        end;
    end;

    procedure NoOfServLinePrice(ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; ShowAll: Boolean) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfServLinePrice(ServHeader, ServLine, ShowAll, Result, IsHandled);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeNoOfServLinePrice(ServHeader, ServLine, ShowAll, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        if ServLinePriceExists(ServHeader, ServLine, ShowAll) then
            exit(TempSalesPrice.Count);
    end;

    procedure NoOfServLineLineDisc(ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; ShowAll: Boolean) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfServLineLineDisc(ServHeader, ServLine, ShowAll, Result, IsHandled);
#if not CLEAN28
        SalesPriceCalcMgt.RunOnBeforeNoOfServLineLineDisc(ServHeader, ServLine, ShowAll, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        if ServLineLineDiscExists(ServHeader, ServLine, ShowAll) then
            exit(TempSalesLineDisc.Count);
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
    local procedure OnAfterFindSalesPrice(var ToSalesPrice: Record "Sales Price"; var FromSalesPrice: Record "Sales Price"; QtyPerUOM: Decimal; Qty: Decimal; CustNo: Code[20]; ContNo: Code[20]; CustPriceGrCode: Code[10]; CampaignNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindSalesLineDisc(var ToSalesLineDisc: Record "Sales Line Discount"; CustNo: Code[20]; ContNo: Code[20]; CustDiscGrCode: Code[20]; CampaignNo: Code[20]; ItemNo: Code[20]; ItemDiscGrCode: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindServLinePrice(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var SalesPrice: Record "Sales Price"; var ResourcePrice: Record "Resource Price"; var ServiceCost: Record "Service Cost"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindServLineResPrice(var ServiceLine: Record "Service Line"; var ResPrice: Record "Resource Price"; var HideResUnitPriceMessage: Boolean; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindServLineDisc(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var SalesLineDiscount: Record "Sales Line Discount")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServLinePriceExists(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServLineLineDiscExists(var ServiceLine: Record "Service Line")
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
    local procedure OnBeforeCopySalesPriceToSalesPrice(var FromSalesPrice: Record "Sales Price"; var ToSalesPrice: Record "Sales Price"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesPrice(var ToSalesPrice: Record "Sales Price"; var FromSalesPrice: Record "Sales Price"; var QtyPerUOM: Decimal; var Qty: Decimal; var CustNo: Code[20]; var ContNo: Code[20]; var CustPriceGrCode: Code[10]; var CampaignNo: Code[20]; var ItemNo: Code[20]; var VariantCode: Code[10]; var UOM: Code[10]; var CurrencyCode: Code[10]; var StartingDate: Date; var ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLineDisc(var ToSalesLineDisc: Record "Sales Line Discount"; var CustNo: Code[20]; ContNo: Code[20]; var CustDiscGrCode: Code[20]; var CampaignNo: Code[20]; var ItemNo: Code[20]; var ItemDiscGrCode: Code[20]; var VariantCode: Code[10]; var UOM: Code[10]; var CurrencyCode: Code[10]; var StartingDate: Date; var ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServLinePrice(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServLineDisc(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetServLinePrice(ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetServLineDisc(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfServLineLineDisc(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ShowAll: Boolean; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfServLinePrice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ShowAll: Boolean; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLinePriceExists(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var TempSalesPrice: Record "Sales Price" temporary; ShowAll: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLineLineDiscExists(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var TempSalesLineDisc: Record "Sales Line Discount" temporary; ShowAll: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesLineDiscOnAfterSetFilters(var SalesLineDiscount: Record "Sales Line Discount")
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
}
