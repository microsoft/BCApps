// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;

codeunit 7010 "Purch. Price Calc. Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        Vend: Record Vendor;
        ResCost: Record "Resource Cost";
        Currency: Record Currency;
        TempPurchPrice: Record "Purchase Price" temporary;
        TempPurchLineDisc: Record "Purchase Line Discount" temporary;
        LineDiscPerCent: Decimal;
        Qty: Decimal;
        QtyPerUOM: Decimal;
        VATPerCent: Decimal;
        PricesInclVAT: Boolean;
        VATBusPostingGr: Code[20];
        PricesInCurrency: Boolean;
        PriceInSKU: Boolean;
        CurrencyFactor: Decimal;
        ExchRateDate: Date;
        FoundPurchPrice: Boolean;
        DateCaption: Text[30];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 is less than %2 in the %3.';
        Text001: Label 'The %1 in the %2 must be same as in the %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure FindPurchLinePrice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindPurchLinePrice(PurchLine, PurchHeader, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        SetCurrency(PurchHeader."Currency Code", PurchHeader."Currency Factor", PurchHeaderExchDate(PurchHeader));
        SetVAT(PurchHeader."Prices Including VAT", PurchLine.GetVATPct(), PurchLine."VAT Bus. Posting Group");
        SetUoM(Abs(PurchLine.Quantity), PurchLine."Qty. per Unit of Measure");
        SetLineDisc(PurchLine."Line Discount %");

        PurchLine.TestField("Qty. per Unit of Measure");
        if PricesInCurrency then
            PurchHeader.TestField("Currency Factor");

        case PurchLine.Type of
            PurchLine.Type::Item:
                begin
                    Item.Get(PurchLine."No.");
                    if (PurchHeader."Pay-to Vendor No." <> '') or (PurchHeader."Document Type" <> PurchHeader."Document Type"::Quote) then
                        if not Vend.Get(PurchHeader."Pay-to Vendor No.") then
                            Vend.Get(PurchLine."Pay-to Vendor No.");
                    PriceInSKU := SKU.Get(PurchLine."Location Code", PurchLine."No.", PurchLine."Variant Code");
                    PurchLinePriceExists(PurchHeader, PurchLine, false);
                    CalcBestDirectUnitCost(TempPurchPrice);
                    if (FoundPurchPrice or
                        not ((CalledByFieldNo = PurchLine.FieldNo("Job No.")) or (CalledByFieldNo = PurchLine.FieldNo("Job Task No.")) or
                             (CalledByFieldNo = PurchLine.FieldNo(Quantity)) or
                             ((CalledByFieldNo = PurchLine.FieldNo("Variant Code")) and not PriceInSKU))) and
                       (PurchLine."Prepmt. Amt. Inv." = 0)
                    then
                        PurchLine."Direct Unit Cost" := TempPurchPrice."Direct Unit Cost";
                end;
            PurchLine.Type::Resource:
                begin
                    ResCost.Init();
                    ResCost.Code := PurchLine."No.";
                    ResCost."Work Type Code" := '';
                    OnFindPurchLinePriceOnBeforeRunResourceFindCost(ResCost);
                    CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
                    ConvertPriceLCYToFCY(PurchLine."Currency Code", ResCost."Unit Cost");
                    PurchLine."Direct Unit Cost" :=
                      Round(ResCost."Direct Unit Cost" * PurchLine."Qty. per Unit of Measure", Currency."Unit-Amount Rounding Precision");
                end;
        end;
        OnAfterFindPurchLinePrice(PurchLine, PurchHeader, TempPurchPrice, CalledByFieldNo, PriceInSKU, FoundPurchPrice);
    end;

    procedure FindItemJnlLinePrice(var ItemJnlLine: Record "Item Journal Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemJnlLinePrice(ItemJnlLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.TestField("Qty. per Unit of Measure");
        SetCurrency('', 0, 0D);
        SetVAT(false, 0, '');
        SetUoM(Abs(ItemJnlLine.Quantity), ItemJnlLine."Qty. per Unit of Measure");

        Item.Get(ItemJnlLine."Item No.");
        PriceInSKU := SKU.Get(ItemJnlLine."Location Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code");

        FindPurchPrice(
          TempPurchPrice, '', ItemJnlLine."Item No.", ItemJnlLine."Variant Code",
          ItemJnlLine."Unit of Measure Code", '', ItemJnlLine."Posting Date", false);

        OnFindItemJnlLinePriceOnBeforeCalcBestDirectUnitCost(ItemJnlLine, TempPurchPrice);
        CalcBestDirectUnitCost(TempPurchPrice);

        if FoundPurchPrice or
           not ((CalledByFieldNo = ItemJnlLine.FieldNo(Quantity)) or
                ((CalledByFieldNo = ItemJnlLine.FieldNo("Variant Code")) and not PriceInSKU))
        then
            ItemJnlLine."Unit Amount" := TempPurchPrice."Direct Unit Cost";
    end;

    procedure FindReqLinePrice(var ReqLine: Record "Requisition Line"; CalledByFieldNo: Integer)
    var
        VendorNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReqLinePriceOnBeforeWith(ReqLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        if ReqLine.Type = ReqLine.Type::Item then begin
            if not Vend.Get(ReqLine."Vendor No.") then
                Vend.Init()
            else
                if Vend."Pay-to Vendor No." <> '' then
                    if not Vend.Get(Vend."Pay-to Vendor No.") then
                        Vend.Init();
            if Vend."No." <> '' then
                VendorNo := Vend."No."
            else
                VendorNo := ReqLine."Vendor No.";

            SetCurrency(ReqLine."Currency Code", ReqLine."Currency Factor", ReqLine."Order Date");
            SetVAT(Vend."Prices Including VAT", 0, '');
            SetUoM(Abs(ReqLine.Quantity), ReqLine."Qty. per Unit of Measure");

            ReqLine.TestField("Qty. per Unit of Measure");
            if PricesInCurrency then
                ReqLine.TestField("Currency Factor");

            Item.Get(ReqLine."No.");
            PriceInSKU := SKU.Get(ReqLine."Location Code", ReqLine."No.", ReqLine."Variant Code");

            IsHandled := false;
            OnBeforeFindReqLinePrice(TempPurchPrice, ReqLine, IsHandled);
            if not IsHandled then
                FindPurchPrice(
                  TempPurchPrice, VendorNo, ReqLine."No.", ReqLine."Variant Code",
                  ReqLine."Unit of Measure Code", ReqLine."Currency Code", ReqLine."Order Date", false);
            CalcBestDirectUnitCost(TempPurchPrice);

            if FoundPurchPrice or
               not ((CalledByFieldNo = ReqLine.FieldNo(Quantity)) or
                    ((CalledByFieldNo = ReqLine.FieldNo("Variant Code")) and not PriceInSKU))
            then
                ReqLine."Direct Unit Cost" := TempPurchPrice."Direct Unit Cost";
        end;

        OnAfterFindReqLinePrice(ReqLine, TempPurchPrice, CalledByFieldNo);
    end;

    procedure FindInvtDocLinePrice(var InvtDocLine: Record "Invt. Document Line"; CalledByFieldNo: Integer)
    begin
        InvtDocLine.TestField("Qty. per Unit of Measure");
        SetCurrency('', 0, 0D);
        SetVAT(false, 0, '');
        SetUoM(Abs(InvtDocLine.Quantity), InvtDocLine."Qty. per Unit of Measure");

        Item.Get(InvtDocLine."Item No.");
        PriceInSKU := SKU.Get(InvtDocLine."Location Code", InvtDocLine."Item No.", InvtDocLine."Variant Code");

        FindPurchPrice(
          TempPurchPrice, '', InvtDocLine."Item No.", InvtDocLine."Variant Code",
          InvtDocLine."Unit of Measure Code", '', InvtDocLine."Posting Date", false);
        CalcBestDirectUnitCost(TempPurchPrice);

        if FoundPurchPrice or
           not ((CalledByFieldNo = InvtDocLine.FieldNo(Quantity)) or
                (((CalledByFieldNo = InvtDocLine.FieldNo("Variant Code")) and not PriceInSKU)))
        then
            InvtDocLine."Unit Amount" := TempPurchPrice."Direct Unit Cost";
    end;

    procedure FindPurchLineLineDisc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindPurchLineLineDisc(PurchLine, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        SetCurrency(PurchHeader."Currency Code", 0, 0D);
        SetUoM(Abs(PurchLine.Quantity), PurchLine."Qty. per Unit of Measure");

        PurchLine.TestField("Qty. per Unit of Measure");

        if PurchLine.Type = PurchLine.Type::Item then begin
            PurchLineLineDiscExists(PurchHeader, PurchLine, false);
            CalcBestLineDisc(TempPurchLineDisc);

            PurchLine."Line Discount %" := TempPurchLineDisc."Line Discount %";
        end;

        OnAfterFindPurchLineLineDisc(PurchLine, PurchHeader, TempPurchLineDisc);
    end;

    procedure FindStdItemJnlLinePrice(var StdItemJnlLine: Record "Standard Item Journal Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindStdItemJnlLinePrice(StdItemJnlLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        StdItemJnlLine.TestField("Qty. per Unit of Measure");
        SetCurrency('', 0, 0D);
        SetVAT(false, 0, '');
        SetUoM(Abs(StdItemJnlLine.Quantity), StdItemJnlLine."Qty. per Unit of Measure");

        Item.Get(StdItemJnlLine."Item No.");
        PriceInSKU := SKU.Get(StdItemJnlLine."Location Code", StdItemJnlLine."Item No.", StdItemJnlLine."Variant Code");

        FindPurchPrice(
          TempPurchPrice, '', StdItemJnlLine."Item No.", StdItemJnlLine."Variant Code",
          StdItemJnlLine."Unit of Measure Code", '', WorkDate(), false);
        CalcBestDirectUnitCost(TempPurchPrice);

        if FoundPurchPrice or
           not ((CalledByFieldNo = StdItemJnlLine.FieldNo(Quantity)) or
                ((CalledByFieldNo = StdItemJnlLine.FieldNo("Variant Code")) and not PriceInSKU))
        then
            StdItemJnlLine."Unit Amount" := TempPurchPrice."Direct Unit Cost";
    end;

    procedure FindReqLineDisc(var ReqLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReqLineDiscOnBeforeWith(ReqLine, IsHandled);
        if IsHandled then
            exit;

        SetCurrency(ReqLine."Currency Code", 0, 0D);
        SetUoM(Abs(ReqLine.Quantity), ReqLine."Qty. per Unit of Measure");

        ReqLine.TestField("Qty. per Unit of Measure");

        if ReqLine.Type = ReqLine.Type::Item then begin
            IsHandled := false;
            OnBeforeFindReqLineDisc(ReqLine, TempPurchLineDisc, IsHandled);
            if not IsHandled then
                FindPurchLineDisc(
                  TempPurchLineDisc, ReqLine."Vendor No.", ReqLine."No.", ReqLine."Variant Code",
                  ReqLine."Unit of Measure Code", ReqLine."Currency Code", ReqLine."Order Date", false,
                  ReqLine."Qty. per Unit of Measure", Abs(ReqLine.Quantity));
            OnAfterFindReqLineDisc(ReqLine);
            CalcBestLineDisc(TempPurchLineDisc);

            ReqLine."Line Discount %" := TempPurchLineDisc."Line Discount %";
        end;
    end;

    procedure CalcBestDirectUnitCost(var PurchPrice: Record "Purchase Price")
    var
        BestPurchPrice: Record "Purchase Price";
        BestPurchPriceFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBestDirectUnitCost(PurchPrice, BestPurchPrice, BestPurchPriceFound, IsHandled, SKU, Item);
        if IsHandled then
            exit;

        FoundPurchPrice := PurchPrice.Find('-');
        if FoundPurchPrice then
            repeat
                if IsInMinQty(PurchPrice."Unit of Measure Code", PurchPrice."Minimum Quantity") then begin
                    OnCalcBestDirectUnitCostOnBeforeConvertPriceToVAT(PurchPrice);
                    ConvertPriceToVAT(
                      Vend."Prices Including VAT", Item."VAT Prod. Posting Group",
                      Vend."VAT Bus. Posting Group", PurchPrice."Direct Unit Cost");
                    ConvertPriceToUoM(PurchPrice."Unit of Measure Code", PurchPrice."Direct Unit Cost");
                    ConvertPriceLCYToFCY(PurchPrice."Currency Code", PurchPrice."Direct Unit Cost");

                    case true of
                        ((BestPurchPrice."Currency Code" = '') and (PurchPrice."Currency Code" <> '')) or
                        ((BestPurchPrice."Variant Code" = '') and (PurchPrice."Variant Code" <> '')):
                            begin
                                BestPurchPrice := PurchPrice;
                                BestPurchPriceFound := true;
                            end;
                        ((BestPurchPrice."Currency Code" = '') or (PurchPrice."Currency Code" <> '')) and
                      ((BestPurchPrice."Variant Code" = '') or (PurchPrice."Variant Code" <> '')):
                            if (BestPurchPrice."Direct Unit Cost" = 0) or
                               (CalcLineAmount(BestPurchPrice) > CalcLineAmount(PurchPrice))
                            then begin
                                BestPurchPrice := PurchPrice;
                                BestPurchPriceFound := true;
                            end;
                    end;
                end;
            until PurchPrice.Next() = 0;
        IsHandled := false;
        OnAfterCalcBestDirectUnitCostFound(PurchPrice, BestPurchPriceFound, IsHandled);
        if IsHandled then
            exit;

        // No price found in agreement
        if not BestPurchPriceFound then begin
            IsHandled := false;
            OnCalcBestDirectUnitCostOnBeforeNoPriceFound(BestPurchPrice, Item, IsHandled);
            if not IsHandled then begin
                PriceInSKU := PriceInSKU and (SKU."Last Direct Cost" <> 0);
                if PriceInSKU then
                    BestPurchPrice."Direct Unit Cost" := SKU."Last Direct Cost"
                else
                    BestPurchPrice."Direct Unit Cost" := Item."Last Direct Cost";
            end;
            ConvertPriceToVAT(false, Item."VAT Prod. Posting Group", '', BestPurchPrice."Direct Unit Cost");
            ConvertPriceToUoM('', BestPurchPrice."Direct Unit Cost");
            ConvertPriceLCYToFCY('', BestPurchPrice."Direct Unit Cost");
            OnCalcBestDirectUnitCostOnAfterSetUnitCost(BestPurchPrice);
        end;

        PurchPrice := BestPurchPrice;
    end;

    procedure CalcBestLineDisc(var PurchLineDisc: Record "Purchase Line Discount")
    var
        BestPurchLineDisc: Record "Purchase Line Discount";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBestLineDisc(PurchLineDisc, Item, IsHandled, QtyPerUOM, Qty);
        if IsHandled then
            exit;

        if PurchLineDisc.Find('-') then
            repeat
                if IsInMinQty(PurchLineDisc."Unit of Measure Code", PurchLineDisc."Minimum Quantity") then
                    case true of
                        ((BestPurchLineDisc."Currency Code" = '') and (PurchLineDisc."Currency Code" <> '')) or
                      ((BestPurchLineDisc."Variant Code" = '') and (PurchLineDisc."Variant Code" <> '')):
                            BestPurchLineDisc := PurchLineDisc;
                        ((BestPurchLineDisc."Currency Code" = '') or (PurchLineDisc."Currency Code" <> '')) and
                      ((BestPurchLineDisc."Variant Code" = '') or (PurchLineDisc."Variant Code" <> '')):
                            if BestPurchLineDisc."Line Discount %" < PurchLineDisc."Line Discount %" then
                                BestPurchLineDisc := PurchLineDisc;
                    end;
            until PurchLineDisc.Next() = 0;

        OnAfterCalcBestLineDisc(PurchLineDisc, BestPurchLineDisc);
        PurchLineDisc := BestPurchLineDisc;
    end;

    procedure FindPurchPrice(var ToPurchPrice: Record "Purchase Price"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean)
    var
        FromPurchPrice: Record "Purchase Price";
    begin
        OnBeforeFindPurchPrice(
          ToPurchPrice, FromPurchPrice, VendorNo, ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll, Qty, QtyPerUOM);

        FromPurchPrice.SetRange("Item No.", ItemNo);
        FromPurchPrice.SetRange("Vendor No.", VendorNo);
        FromPurchPrice.SetFilter("Ending Date", '%1|>=%2', 0D, StartingDate);
        FromPurchPrice.SetFilter("Variant Code", '%1|%2', VariantCode, '');
        if not ShowAll then begin
            FromPurchPrice.SetRange("Starting Date", 0D, StartingDate);
            FromPurchPrice.SetFilter("Currency Code", '%1|%2', CurrencyCode, '');
            FromPurchPrice.SetFilter("Unit of Measure Code", '%1|%2', UOM, '');
        end;

        ToPurchPrice.Reset();
        ToPurchPrice.DeleteAll();
        if FromPurchPrice.Find('-') then
            repeat
                ToPurchPrice := FromPurchPrice;
                ToPurchPrice.Insert();
            until FromPurchPrice.Next() = 0;

        OnAfterFindPurchPrice(
          ToPurchPrice, FromPurchPrice, VendorNo, ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll, Qty, QtyPerUOM);
    end;

    procedure FindPurchLineDisc(var ToPurchLineDisc: Record "Purchase Line Discount"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean; QuantityPerUoM: Decimal; Quantity: Decimal)
    var
        FromPurchLineDisc: Record "Purchase Line Discount";
    begin
        OnBeforeFindPurchLineDsic(ToPurchLineDisc, VendorNo, ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll, QuantityPerUoM, Quantity);
        FromPurchLineDisc.SetRange("Item No.", ItemNo);
        FromPurchLineDisc.SetRange("Vendor No.", VendorNo);
        FromPurchLineDisc.SetFilter("Ending Date", '%1|>=%2', 0D, StartingDate);
        FromPurchLineDisc.SetFilter("Variant Code", '%1|%2', VariantCode, '');
        OnFindPurchLineDiscOnAfterSetFilters(FromPurchLineDisc);
        if not ShowAll then begin
            FromPurchLineDisc.SetRange("Starting Date", 0D, StartingDate);
            FromPurchLineDisc.SetFilter("Currency Code", '%1|%2', CurrencyCode, '');
            FromPurchLineDisc.SetFilter("Unit of Measure Code", '%1|%2', UOM, '');
        end;

        ToPurchLineDisc.Reset();
        ToPurchLineDisc.DeleteAll();

        if FromPurchLineDisc.Find('-') then
            repeat
                ToPurchLineDisc := FromPurchLineDisc;
                ToPurchLineDisc.Insert();
            until FromPurchLineDisc.Next() = 0;

        OnAfterFindPurchLineDisc(ToPurchLineDisc, FromPurchLineDisc, ItemNo, QuantityPerUoM, Quantity, ShowAll);
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
        OnAfterSetCurrency(CurrencyFactor, ExchRateDate, PricesInCurrency, PricesInclVAT, VATPerCent, VATBusPostingGr, DateCaption, PriceInSKU, FoundPurchPrice);
    end;

    procedure SetVAT(PriceInclVAT2: Boolean; VATPerCent2: Decimal; VATBusPostingGr2: Code[20])
    begin
        PricesInclVAT := PriceInclVAT2;
        VATPerCent := VATPerCent2;
        VATBusPostingGr := VATBusPostingGr2;
    end;

    procedure SetUoM(Qty2: Decimal; QtyPerUoM2: Decimal)
    begin
        Qty := Qty2;
        QtyPerUOM := QtyPerUoM2;
    end;

    procedure SetLineDisc(LineDiscPerCent2: Decimal)
    begin
        LineDiscPerCent := LineDiscPerCent2;
    end;

    local procedure IsInMinQty(UnitofMeasureCode: Code[10]; MinQty: Decimal) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsInMinQty(Item, UnitofMeasureCode, MinQty, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if UnitofMeasureCode = '' then
            exit(MinQty <= QtyPerUOM * Qty);
        exit(MinQty <= Qty);
    end;

    local procedure ConvertPriceToVAT(FromPriceInclVAT: Boolean; FromVATProdPostingGr: Code[20]; FromVATBusPostingGr: Code[20]; var UnitPrice: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        if FromPriceInclVAT then begin
            if not VATPostingSetup.Get(FromVATBusPostingGr, FromVATProdPostingGr) then
                VATPostingSetup.Init();

            IsHandled := false;
            OnBeforeConvertPriceToVAT(VATPostingSetup, VATBusPostingGr, FromVATBusPostingGr, UnitPrice, PricesInclVAT, IsHandled);
            if IsHandled then
                exit;

            if PricesInclVAT then begin
                if VATBusPostingGr <> FromVATBusPostingGr then
                    UnitPrice := UnitPrice * (100 + VATPerCent) / (100 + VATPostingSetup."VAT %");
            end else
                UnitPrice := UnitPrice / (1 + VATPostingSetup."VAT %" / 100);
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

    local procedure CalcLineAmount(PurchPrice: Record "Purchase Price") Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLineAmount(PurchPrice, LineDiscPerCent, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(PurchPrice."Direct Unit Cost" * (1 - LineDiscPerCent / 100));
    end;

    [Scope('OnPrem')]
    procedure PurchLinePriceExists(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        if (PurchLine.Type = PurchLine.Type::Item) and Item.Get(PurchLine."No.") then begin
            IsHandled := false;
            OnBeforePurchLinePriceExists(PurchLine, PurchHeader, TempPurchPrice, ShowAll, IsHandled, DateCaption);
            if not IsHandled then
                FindPurchPrice(
                  TempPurchPrice, PurchLine."Pay-to Vendor No.", PurchLine."No.", PurchLine."Variant Code", PurchLine."Unit of Measure Code",
                  PurchHeader."Currency Code", PurchHeaderStartDate(PurchHeader, DateCaption), ShowAll);
            OnAfterPurchLinePriceExists(PurchLine);
            exit(TempPurchPrice.Find('-'));
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure PurchLineLineDiscExists(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        if (PurchLine.Type = PurchLine.Type::Item) and Item.Get(PurchLine."No.") then begin
            IsHandled := false;
            OnBeforePurchLineLineDiscExists(PurchLine, PurchHeader, TempPurchLineDisc, ShowAll, IsHandled, DateCaption);
            if not IsHandled then
                FindPurchLineDisc(
                  TempPurchLineDisc, PurchLine."Pay-to Vendor No.", PurchLine."No.", PurchLine."Variant Code", PurchLine."Unit of Measure Code",
                  PurchHeader."Currency Code", PurchHeaderStartDate(PurchHeader, DateCaption), ShowAll,
                  PurchLine."Qty. per Unit of Measure", PurchLine.Quantity);
            OnAfterPurchLineLineDiscExists(PurchLine);
            exit(TempPurchLineDisc.Find('-'));
        end;
        exit(false);
    end;

    local procedure PurchHeaderExchDate(var PurchHeader: Record "Purchase Header"): Date
    begin
        if PurchHeader."Posting Date" <> 0D then
            exit(PurchHeader."Posting Date");
        exit(WorkDate());
    end;

    local procedure PurchHeaderStartDate(var PurchHeader: Record "Purchase Header"; var DateCaption: Text[30]) StartDate: Date
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderStartDate(PurchHeader, DateCaption, StartDate, IsHandled);
        if IsHandled then
            exit(StartDate);

        if PurchHeader."Document Type" in [PurchHeader."Document Type"::Invoice, PurchHeader."Document Type"::"Credit Memo"] then begin
            DateCaption := PurchHeader.FieldCaption("Posting Date");
            exit(PurchHeader."Posting Date")
        end else begin
            DateCaption := PurchHeader.FieldCaption("Order Date");
            exit(PurchHeader."Order Date");
        end;
    end;

    procedure FindJobPlanningLinePrice(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer)
    var
        JTHeader: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindJobPlanningLinePrice(JobPlanningLine, CalledByFieldNo, IsHandled);
        if not IsHandled then begin
            SetCurrency(JobPlanningLine."Currency Code", JobPlanningLine."Currency Factor", JobPlanningLine."Planning Date");
            SetVAT(false, 0, '');
            SetUoM(Abs(JobPlanningLine.Quantity), JobPlanningLine."Qty. per Unit of Measure");

            JobPlanningLine.TestField("Qty. per Unit of Measure");

            case JobPlanningLine.Type of
                JobPlanningLine.Type::Item:
                    begin
                        Item.Get(JobPlanningLine."No.");
                        PriceInSKU := SKU.Get('', JobPlanningLine."No.", JobPlanningLine."Variant Code");
                        JTHeader.Get(JobPlanningLine."Job No.");

                        FindPurchPrice(
                          TempPurchPrice, '', JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code", '', JobPlanningLine."Planning Date", false);
                        PricesInCurrency := false;
                        GLSetup.Get();
                        CalcBestDirectUnitCost(TempPurchPrice);
                        SetCurrency(JobPlanningLine."Currency Code", JobPlanningLine."Currency Factor", JobPlanningLine."Planning Date");

                        if FoundPurchPrice or
                           not ((CalledByFieldNo = JobPlanningLine.FieldNo(Quantity)) or
                                ((CalledByFieldNo = JobPlanningLine.FieldNo("Variant Code")) and not PriceInSKU))
                        then
                            JobPlanningLine."Direct Unit Cost (LCY)" := TempPurchPrice."Direct Unit Cost";
                    end;
                JobPlanningLine.Type::Resource:
                    begin
                        ResCost.Init();
                        ResCost.Code := JobPlanningLine."No.";
                        ResCost."Work Type Code" := JobPlanningLine."Work Type Code";
                        OnFindJobPlanningLinePriceOnBeforeResourceFindCost(JobPlanningLine, ResCost);
                        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
                        JobPlanningLine.AfterResourceFindCost(ResCost);
                        OnAfterJobPlanningLineFindResCost(JobPlanningLine, CalledByFieldNo, ResCost);
                        ConvertPriceLCYToFCY(JobPlanningLine."Currency Code", ResCost."Unit Cost");
                        JobPlanningLine."Direct Unit Cost (LCY)" := Round(ResCost."Direct Unit Cost" * JobPlanningLine."Qty. per Unit of Measure",
                            Currency."Unit-Amount Rounding Precision");
                        JobPlanningLine.Validate("Unit Cost (LCY)", Round(ResCost."Unit Cost" * JobPlanningLine."Qty. per Unit of Measure",
                            Currency."Unit-Amount Rounding Precision"));
                    end;
            end;
            JobPlanningLine.Validate("Direct Unit Cost (LCY)");
        end;
        OnAfterFindJobPlanningLinePrice(JobPlanningLine, ResCost);
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
        SetVAT(false, 0, '');
        SetUoM(Abs(JobJnlLine.Quantity), JobJnlLine."Qty. per Unit of Measure");

        JobJnlLine.TestField("Qty. per Unit of Measure");

        case JobJnlLine.Type of
            JobJnlLine.Type::Item:
                begin
                    Item.Get(JobJnlLine."No.");
                    PriceInSKU := SKU.Get('', JobJnlLine."No.", JobJnlLine."Variant Code");
                    Job.Get(JobJnlLine."Job No.");

                    FindPurchPrice(
                      TempPurchPrice, '', JobJnlLine."No.", JobJnlLine."Variant Code", JobJnlLine."Unit of Measure Code", JobJnlLine."Country/Region Code", JobJnlLine."Posting Date", false);
                    PricesInCurrency := false;
                    GLSetup.Get();

                    OnFindJobJnlLinePriceOnBeforeCalcBestDirectUnitCost(JobJnlLine, TempPurchPrice);
                    CalcBestDirectUnitCost(TempPurchPrice);
                    SetCurrency(JobJnlLine."Currency Code", JobJnlLine."Currency Factor", JobJnlLine."Posting Date");

                    if FoundPurchPrice or
                       not ((CalledByFieldNo = JobJnlLine.FieldNo(Quantity)) or
                            ((CalledByFieldNo = JobJnlLine.FieldNo("Variant Code")) and not PriceInSKU))
                    then
                        JobJnlLine."Direct Unit Cost (LCY)" := TempPurchPrice."Direct Unit Cost";
                    OnAfterFindJobJnlLinePriceItem(JobJnlLine);
                end;
            JobJnlLine.Type::Resource:
                begin
                    ResCost.Init();
                    ResCost.Code := JobJnlLine."No.";
                    ResCost."Work Type Code" := JobJnlLine."Work Type Code";
                    OnFindJobJnlLinePriceOnBeforeResourceFindCost(JobJnlLine, ResCost);
                    CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
                    JobJnlLine.AfterResourceFindCost(ResCost);
                    OnAfterJobJnlLineFindResCost(JobJnlLine, CalledByFieldNo, ResCost);
                    ConvertPriceLCYToFCY(JobJnlLine."Currency Code", ResCost."Unit Cost");
                    JobJnlLine."Direct Unit Cost (LCY)" :=
                      Round(ResCost."Direct Unit Cost" * JobJnlLine."Qty. per Unit of Measure", Currency."Unit-Amount Rounding Precision");
                    JobJnlLine.Validate("Unit Cost (LCY)",
                      Round(ResCost."Unit Cost" * JobJnlLine."Qty. per Unit of Measure", Currency."Unit-Amount Rounding Precision"));
                    OnAfterFindJobJnlLinePriceResource(JobJnlLine, ResCost);
                end;
        end;
        OnAfterFindJobJnlLinePrice(JobJnlLine, IsHandled);
        if not IsHandled then
            JobJnlLine.Validate("Direct Unit Cost (LCY)");
    end;

    procedure NoOfPurchLinePrice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ShowAll: Boolean) ReturnValue: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfPurchLinePrice(PurchHeader, PurchLine, ShowAll, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if PurchLinePriceExists(PurchHeader, PurchLine, ShowAll) then
            exit(TempPurchPrice.Count);
    end;

    procedure NoOfPurchLineLineDisc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ShowAll: Boolean) ReturnValue: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfPurchLineLineDisc(PurchHeader, PurchLine, ShowAll, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if PurchLineLineDiscExists(PurchHeader, PurchLine, ShowAll) then
            exit(TempPurchLineDisc.Count);
    end;

    procedure GetPurchLinePrice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchLinePrice(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLinePriceExists(PurchHeader, PurchLine, true);

        if PAGE.RunModal(PAGE::"Get Purchase Price", TempPurchPrice) = ACTION::LookupOK then begin
            SetVAT(PurchHeader."Prices Including VAT", PurchLine."VAT %", PurchLine."VAT Bus. Posting Group");
            SetUoM(Abs(PurchLine.Quantity), PurchLine."Qty. per Unit of Measure");
            SetCurrency(PurchHeader."Currency Code", PurchHeader."Currency Factor", PurchHeaderExchDate(PurchHeader));
            OnGetPurchLinePriceOnAfterLookup(PurchHeader, PurchLine, TempPurchPrice);

            if not IsInMinQty(TempPurchPrice."Unit of Measure Code", TempPurchPrice."Minimum Quantity") then
                Error(
                  Text000,
                  PurchLine.FieldCaption(Quantity),
                  TempPurchPrice.FieldCaption("Minimum Quantity"),
                  TempPurchPrice.TableCaption());
            if not (TempPurchPrice."Currency Code" in [PurchLine."Currency Code", '']) then
                Error(
                  Text001,
                  PurchLine.FieldCaption("Currency Code"),
                  PurchLine.TableCaption,
                  TempPurchPrice.TableCaption());
            if not (TempPurchPrice."Unit of Measure Code" in [PurchLine."Unit of Measure Code", '']) then
                Error(
                  Text001,
                  PurchLine.FieldCaption("Unit of Measure Code"),
                  PurchLine.TableCaption,
                  TempPurchPrice.TableCaption());
            if TempPurchPrice."Starting Date" > PurchHeaderStartDate(PurchHeader, DateCaption) then
                Error(
                  Text000,
                  DateCaption,
                  TempPurchPrice.FieldCaption("Starting Date"),
                  TempPurchPrice.TableCaption());

            ConvertPriceToVAT(
              PurchHeader."Prices Including VAT", Item."VAT Prod. Posting Group",
              PurchLine."VAT Bus. Posting Group", TempPurchPrice."Direct Unit Cost");
            ConvertPriceToUoM(TempPurchPrice."Unit of Measure Code", TempPurchPrice."Direct Unit Cost");
            ConvertPriceLCYToFCY(TempPurchPrice."Currency Code", TempPurchPrice."Direct Unit Cost");

            PurchLine.Validate("Direct Unit Cost", TempPurchPrice."Direct Unit Cost");
        end;

        OnAfterGetPurchLinePrice(PurchHeader, PurchLine, TempPurchPrice, QtyPerUOM);
    end;

    procedure GetPurchLineLineDisc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchLineDisc(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLineLineDiscExists(PurchHeader, PurchLine, true);

        if PAGE.RunModal(PAGE::"Get Purchase Line Disc.", TempPurchLineDisc) = ACTION::LookupOK then begin
            SetCurrency(PurchHeader."Currency Code", 0, 0D);
            SetUoM(Abs(PurchLine.Quantity), PurchLine."Qty. per Unit of Measure");
            OnGetPurchLineLineDiscOnAfterLookup(PurchHeader, PurchLine, TempPurchLineDisc);

            if not IsInMinQty(TempPurchLineDisc."Unit of Measure Code", TempPurchLineDisc."Minimum Quantity") then
                Error(
                  Text000, PurchLine.FieldCaption(Quantity),
                  TempPurchLineDisc.FieldCaption("Minimum Quantity"),
                  TempPurchLineDisc.TableCaption());
            if not (TempPurchLineDisc."Currency Code" in [PurchLine."Currency Code", '']) then
                Error(
                  Text001,
                  PurchLine.FieldCaption("Currency Code"),
                  PurchLine.TableCaption,
                  TempPurchLineDisc.TableCaption());
            if not (TempPurchLineDisc."Unit of Measure Code" in [PurchLine."Unit of Measure Code", '']) then
                Error(
                  Text001,
                  PurchLine.FieldCaption("Unit of Measure Code"),
                  PurchLine.TableCaption,
                  TempPurchLineDisc.TableCaption());
            if TempPurchLineDisc."Starting Date" > PurchHeaderStartDate(PurchHeader, DateCaption) then
                Error(
                  Text000,
                  DateCaption,
                  TempPurchLineDisc.FieldCaption("Starting Date"),
                  TempPurchLineDisc.TableCaption());

            PurchLine.Validate("Line Discount %", TempPurchLineDisc."Line Discount %");
        end;

        OnAfterGetPurchLineLineDisc(PurchLine, TempPurchLineDisc);
    end;

    procedure SetItem(ItemNo: Code[20])
    begin
        Item.Get(ItemNo);
    end;

    procedure SetVendor(VendorNo: Code[20])
    begin
        Vend.Get(VendorNo);
    end;

    procedure FindResUnitCost(var ResJournalLine: Record "Res. Journal Line")
    begin
        GLSetup.Get();
        ResCost.Init();
        ResCost.Code := ResJournalLine."Resource No.";
        ResCost."Work Type Code" := ResJournalLine."Work Type Code";
        ResJournalLine.AfterInitResourceCost(ResCost);
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        ResJournalLine.AfterFindResUnitCost(ResCost);
        ResJournalLine."Direct Unit Cost" :=
            Round(ResCost."Direct Unit Cost" * ResJournalLine."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
        ResJournalLine."Unit Cost" :=
            Round(ResCost."Unit Cost" * ResJournalLine."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
        ResJournalLine.Validate("Unit Cost");
    end;

    procedure FindResUnitCost(var SalesLine: Record "Sales Line")
    begin
        ResCost.Init();
        SalesLine.FindResUnitCostOnAfterInitResCost(ResCost);
        ResCost.Code := SalesLine."No.";
        ResCost."Work Type Code" := SalesLine."Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        SalesLine.AfterFindResUnitCost(ResCost);
        SalesLine.Validate("Unit Cost (LCY)", ResCost."Unit Cost" * SalesLine."Qty. per Unit of Measure");
    end;

    procedure FindResUnitCost(var ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        ResCost.Init();
        ResCost.Code := ServiceLine."No.";
        ResCost."Work Type Code" := ServiceLine."Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        ServiceLine.AfterResourseFindCost(ResCost);
        ServiceLine.Validate("Unit Cost (LCY)", ResCost."Unit Cost" * ServiceLine."Qty. per Unit of Measure");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBestDirectUnitCostFound(var PurchPrice: Record "Purchase Price"; var BestPurchPriceFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBestLineDisc(var PurchaLineDisc: Record "Purchase Line Discount"; var BestPurchLineDisc: Record "Purchase Line Discount");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobJnlLinePrice(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobPlanningLinePrice(var JobPlanningLine: Record "Job Planning Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobJnlLinePriceItem(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobJnlLinePriceResource(var JobJournalLine: Record "Job Journal Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPurchPrice(var ToPurchPrice: Record "Purchase Price"; FromPurchasePrice: Record "Purchase Price"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean; Qty: Decimal; QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPurchLinePrice(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var PurchasePrice: Record "Purchase Price"; CalledByFieldNo: Integer; PriceInSKU: Boolean; FoundPurchPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPurchLineDisc(var ToPurchaseLineDiscount: Record "Purchase Line Discount"; var FromPurchaseLineDiscount: Record "Purchase Line Discount"; ItemNo: Code[20]; QuantityPerUoM: Decimal; Quantity: Decimal; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPurchLineLineDisc(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempPurchLineDisc: Record "Purchase Line Discount" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindReqLinePrice(var ReqLine: Record "Requisition Line"; var TempPurchasePrice: Record "Purchase Price" temporary; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindReqLineDisc(var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchLinePrice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempPurchasePrice: Record "Purchase Price" temporary; QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchLineLineDisc(var PurchaseLine: Record "Purchase Line"; var TempPurchLineDisc: Record "Purchase Line Discount");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobJnlLineFindResCost(var JobJournalLine: Record "Job Journal Line"; CalledByFieldNo: Integer; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobPlanningLineFindResCost(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineLineDiscExists(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLinePriceExists(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrency(var CurrencyFactor: Decimal; var ExchRateDate: Date; var PricesInCurrency: Boolean; var PricesInclVAT: Boolean; var VATPerCent: Decimal; var VATBusPostingGr: Code[20]; var DateCaption: Text[30]; var PriceInSKU: Boolean; var FoundPurchPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBestDirectUnitCost(var PurchPrice: Record "Purchase Price"; var BestPurchPrice: Record "Purchase Price"; var BestPurchPriceFound: Boolean; var IsHandled: Boolean; var StockkeepingUnit: Record "Stockkeeping Unit"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBestLineDisc(var PurchLineDisc: Record "Purchase Line Discount"; Item: Record Item; var IsHandled: Boolean; QtyPerUOM: Decimal; Qty: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineAmount(var PurchasePrice: Record "Purchase Price"; LineDiscPerCent: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertPriceToVAT(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGr: Code[20]; FromVATBusPostingGr: Code[20]; UnitPrice: Decimal; PricesInclVAT: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemJnlLinePrice(var ItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindJobJnlLinePrice(var JobJnlLine: Record "Job Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindJobPlanningLinePrice(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLinePrice(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLineDsic(var ToPurchLineDisc: Record "Purchase Line Discount"; var VendorNo: Code[20]; var ItemNo: Code[20]; var VariantCode: Code[10]; var UOM: Code[10]; var CurrencyCode: Code[10]; var StartingDate: Date; var ShowAll: Boolean; var QuantityPerUoM: Decimal; var Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchPrice(var ToPurchPrice: Record "Purchase Price"; var FromPurchasePrice: Record "Purchase Price"; var VendorNo: Code[20]; var ItemNo: Code[20]; var VariantCode: Code[10]; var UOM: Code[10]; var CurrencyCode: Code[10]; var StartingDate: Date; var ShowAll: Boolean; var Qty: Decimal; var QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReqLinePrice(var TempPurchasePrice: Record "Purchase Price" temporary; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReqLinePriceOnBeforeWith(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReqLineDisc(var ReqLine: Record "Requisition Line"; var TempPurchaseLineDiscount: Record "Purchase Line Discount" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReqLineDiscOnBeforeWith(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindStdItemJnlLinePrice(var StandardItemJnlLine: Record "Standard Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchLineDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchLinePrice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsInMinQty(var Item: Record Item; UnitofMeasureCode: Code[10]; MinQty: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfPurchLineLineDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ShowAll: Boolean; var ReturnValue: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfPurchLinePrice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ShowAll: Boolean; var ReturnValue: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLinePriceExists(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempPurchasePrice: Record "Purchase Price" temporary; ShowAll: Boolean; var IsHandled: Boolean; var DateCaption: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineLineDiscExists(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempPurchLineDisc: Record "Purchase Line Discount" temporary; ShowAll: Boolean; var IsHandled: Boolean; var DateCaption: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderStartDate(var PurchaseHeader: Record "Purchase Header"; var DateCaption: Text[30]; var StartDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLineLineDisc(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBestDirectUnitCostOnAfterSetUnitCost(var PurchasePrice: Record "Purchase Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBestDirectUnitCostOnBeforeConvertPriceToVAT(var PurchasePrice: Record "Purchase Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBestDirectUnitCostOnBeforeNoPriceFound(var PurchasePrice: Record "Purchase Price"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobPlanningLinePriceOnBeforeResourceFindCost(JobPlanningLine: Record "Job Planning Line"; var ResCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobJnlLinePriceOnBeforeResourceFindCost(JobJournalLine: Record "Job Journal Line"; var ResCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchLinePriceOnAfterLookup(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempPurchasePrice: Record "Purchase Price" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchLineLineDiscOnAfterLookup(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempPurchaseLineDiscount: Record "Purchase Line Discount" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemJnlLinePriceOnBeforeCalcBestDirectUnitCost(var ItemJournalLine: Record "Item Journal Line"; var TempPurchasePrice: Record "Purchase Price" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPurchLineDiscOnAfterSetFilters(var FromPurchLineDisc: Record "Purchase Line Discount");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPurchLinePriceOnBeforeRunResourceFindCost(var ResCost: record "Resource cost");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobJnlLinePriceOnBeforeCalcBestDirectUnitCost(var JobJournalLine: Record "Job Journal Line"; var TempPurchasePrice: Record "Purchase Price" temporary)
    begin
    end;
}
