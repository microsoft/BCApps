// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Requisition;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;

codeunit 7003 "Price Calculation - V15" implements "Price Calculation"
{

    trigger OnRun()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange(Implementation, PriceCalculationSetup.Implementation::"Not Defined");
        PriceCalculationSetup.DeleteAll();
        AddSupportedSetup(PriceCalculationSetup);
        PriceCalculationSetup.ModifyAll(Default, true);
    end;

    var
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";
        PurchPriceCalcMgt: Codeunit "Purch. Price Calc. Mgt.";
        CurrLineWithPrice: Interface "Line With Price";

    procedure GetID(): Integer
    begin
        exit(Codeunit::"Price Calculation - V15");
    end;

    procedure GetLine(var Line: Variant)
    begin
        CurrLineWithPrice.GetLine(Line);
    end;

    procedure Init(NewLineWithPrice: Interface "Line With Price"; PriceCalculationSetup: Record "Price Calculation Setup")
    begin
        CurrLineWithPrice := NewLineWithPrice;
    end;

    procedure ApplyDiscount()
    var
        PriceType: Enum "Price Type";
    begin
        case CurrLineWithPrice.GetPriceType() of
            PriceType::Sale:
                ApplyDiscountSalesHandler();
            PriceType::Purchase:
                ApplyDiscountPurchHandler();
        end;
    end;

    procedure ApplyPrice(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
    begin
        case CurrLineWithPrice.GetPriceType() of
            PriceType::Sale:
                ApplyPriceSalesHandler(CalledByFieldNo);
            PriceType::Purchase:
                ApplyPricePurchHandler(CalledByFieldNo);
        end;
    end;

    procedure CountDiscount(ShowAll: Boolean) Result: Integer;
    var
        Header: Variant;
        Line: Variant;
    begin
        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Sales Line":
                Result := SalesPriceCalcMgt.NoOfSalesLineLineDisc(Header, Line, ShowAll);
            Database::Microsoft.Service.Document."Service Line":
                Result := SalesPriceCalcMgt.NoOfServLineLineDisc(Header, Line, ShowAll);
            Database::"Purchase Line":
                Result := PurchPriceCalcMgt.NoOfPurchLineLineDisc(Header, Line, ShowAll);
        end;
    end;

    procedure CountPrice(ShowAll: Boolean) Result: Integer;
    var
        Header: Variant;
        Line: Variant;
    begin
        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Sales Line":
                Result := SalesPriceCalcMgt.NoOfSalesLinePrice(Header, Line, ShowAll);
            Database::Microsoft.Service.Document."Service Line":
                Result := SalesPriceCalcMgt.NoOfServLinePrice(Header, Line, ShowAll);
            Database::"Purchase Line":
                Result := PurchPriceCalcMgt.NoOfPurchLinePrice(Header, Line, ShowAll);
        end;
    end;

    procedure FindDiscount(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempSalesLineDiscount: Record "Sales Line Discount" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        AmountType: Enum "Price Amount Type";
        PriceSourceType: Enum "Price Source Type";
    begin
        if IsDisabled() then
            exit;

        CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        SalesPriceCalcMgt.FindSalesLineDisc(
            TempSalesLineDiscount,
            PriceCalculationBufferMgt.GetSource(PriceSourceType::Customer),
            PriceCalculationBufferMgt.GetSource(PriceSourceType::Contact),
            PriceCalculationBufferMgt.GetSource(PriceSourceType::"Customer Disc. Group"),
            PriceCalculationBufferMgt.GetSource(PriceSourceType::Campaign),
            PriceCalculationBuffer."Asset No.",
            PriceCalculationBuffer."Item Disc. Group",
            PriceCalculationBuffer."Variant Code",
            PriceCalculationBuffer."Unit of Measure Code",
            PriceCalculationBuffer."Currency Code",
            PriceCalculationBuffer."Document Date",
            ShowAll);

        CopyFromToPriceListLine.CopyFrom(TempSalesLineDiscount, TempPriceListLine);
        Found := not TempPriceListLine.IsEmpty();
        if not Found then
            PriceCalculationBufferMgt.FillBestLine(AmountType::Discount, TempPriceListLine);
    end;

    procedure FindPrice(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempSalesPrice: Record "Sales Price" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        AmountType: Enum "Price Amount Type";
        PriceSourceType: Enum "Price Source Type";
    begin
        if IsDisabled() then
            exit;

        CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        SalesPriceCalcMgt.FindSalesPrice(
            TempSalesPrice,
            PriceCalculationBufferMgt.GetSource(PriceSourceType::Customer),
            PriceCalculationBufferMgt.GetSource(PriceSourceType::Contact),
            CopyStr(PriceCalculationBufferMgt.GetSource(PriceSourceType::"Customer Price Group"), 1, 10),
            PriceCalculationBufferMgt.GetSource(PriceSourceType::Campaign),
            PriceCalculationBuffer."Asset No.",
            PriceCalculationBuffer."Variant Code",
            PriceCalculationBuffer."Unit of Measure Code",
            PriceCalculationBuffer."Currency Code",
            PriceCalculationBuffer."Document Date",
            ShowAll);

        CopyFromToPriceListLine.CopyFrom(TempSalesPrice, TempPriceListLine);
        Found := not TempPriceListLine.IsEmpty();
        if not Found then
            PriceCalculationBufferMgt.FillBestLine(AmountType::Price, TempPriceListLine);
    end;

    procedure IsDiscountExists(ShowAll: Boolean) Result: Boolean;
    var
        Header: Variant;
        Line: Variant;
    begin
        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Sales Line":
                Result := SalesPriceCalcMgt.SalesLineLineDiscExists(Header, Line, ShowAll);
            Database::Microsoft.Service.Document."Service Line":
                Result := SalesPriceCalcMgt.ServLineLineDiscExists(Header, Line, ShowAll);
            Database::"Purchase Line":
                Result := PurchPriceCalcMgt.PurchLineLineDiscExists(Header, Line, ShowAll);
        end;
    end;

    procedure IsPriceExists(ShowAll: Boolean) Result: Boolean;
    var
        Header: Variant;
        Line: Variant;
    begin
        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Sales Line":
                Result := SalesPriceCalcMgt.SalesLinePriceExists(Header, Line, ShowAll);
            Database::Microsoft.Service.Document."Service Line":
                Result := SalesPriceCalcMgt.ServLinePriceExists(Header, Line, ShowAll);
            Database::"Purchase Line":
                Result := PurchPriceCalcMgt.PurchLinePriceExists(Header, Line, ShowAll);
        end;
    end;

    procedure PickDiscount()
    var
        Header: Variant;
        Line: Variant;
        PriceType: Enum "Price Type";
    begin
        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Sales Line":
                begin
                    SalesPriceCalcMgt.GetSalesLineLineDisc(Header, Line);
                    PriceType := PriceType::Sale;
                end;
            Database::Microsoft.Service.Document."Service Line":
                begin
                    SalesPriceCalcMgt.GetServLineLineDisc(Header, Line);
                    PriceType := PriceType::Sale;
                end;
            Database::"Purchase Line":
                begin
                    PurchPriceCalcMgt.GetPurchLineLineDisc(Header, Line);
                    PriceType := PriceType::Purchase;
                end;
        end;
        CurrLineWithPrice.SetLine(PriceType, Header, Line);
    end;

    procedure PickPrice()
    var
        Header: Variant;
        Line: Variant;
    begin
        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Sales Line":
                SalesPriceCalcMgt.GetSalesLinePrice(Header, Line);
            Database::Microsoft.Service.Document."Service Line":
                SalesPriceCalcMgt.GetServLinePrice(Header, Line);
            Database::"Purchase Line":
                PurchPriceCalcMgt.GetPurchLinePrice(Header, Line);
        end;
        CurrLineWithPrice.SetLine(CurrLineWithPrice.GetPriceType(), Header, Line);
    end;

    procedure ShowPrices(var TempPriceListLine: Record "Price List Line")
    var
        TempSalesPrice: Record "Sales Price" temporary;
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
    begin
        CopyFromToPriceListLine.CopyTo(TempSalesPrice, TempPriceListLine);
        if TempSalesPrice.FindSet() then
            PAGE.RunModal(PAGE::"Get Sales Price", TempSalesPrice);
    end;

    local procedure IsDisabled() Result: Boolean;
    begin
        OnIsDisabled(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsDisabled(var Disabled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Mgt.", 'OnFindSupportedSetup', '', false, false)]
    local procedure OnFindImplementationHandler(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        AddSupportedSetup(TempPriceCalculationSetup);
    end;

    local procedure AddSupportedSetup(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        TempPriceCalculationSetup.Init();
        TempPriceCalculationSetup.Validate(Implementation, TempPriceCalculationSetup.Implementation::"Business Central (Version 15.0)");
        TempPriceCalculationSetup.Method := TempPriceCalculationSetup.Method::"Lowest Price";
        TempPriceCalculationSetup.Enabled := not IsDisabled();
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Purchase;
        TempPriceCalculationSetup.Insert(true);
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Sale;
        TempPriceCalculationSetup.Insert(true);
    end;

    local procedure ApplyPriceSalesHandler(CalledByFieldNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        ResJournalLine: Record "Res. Journal Line";
        SalesLine: Record "Sales Line";
        ServiceLine: Record Microsoft.Service.Document."Service Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        Header: Variant;
        Line: Variant;
        PriceType: Enum "Price Type";
    begin
        if IsDisabled() then
            exit;

        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Item Journal Line":
                begin
                    ItemJournalLine := Line;
                    if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Sale then begin
                        SalesPriceCalcMgt.FindItemJnlLinePrice(ItemJournalLine, CalledByFieldNo);
                        CurrLineWithPrice.SetLine(PriceType::Sale, ItemJournalLine);
                    end;
                end;
            Database::"Job Journal Line":
                begin
                    JobJournalLine := Line;
                    SalesPriceCalcMgt.FindJobJnlLinePrice(JobJournalLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine(PriceType::Sale, JobJournalLine);
                end;
            Database::"Job Planning Line":
                begin
                    JobPlanningLine := Line;
                    if CalledByFieldNo = JobTransferLine.JobTransferMarkerFieldNo() then
                        SalesPriceCalcMgt.JobPlanningLineFindJTPrice(JobPlanningLine)
                    else
                        SalesPriceCalcMgt.FindJobPlanningLinePrice(JobPlanningLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine(PriceType::Sale, JobPlanningLine);
                end;
            Database::"Res. Journal Line":
                begin
                    ResJournalLine := Line;
                    SalesPriceCalcMgt.FindResPrice(ResJournalLine);
                    CurrLineWithPrice.SetLine(PriceType::Sale, ResJournalLine);
                end;
            Database::"Sales Line":
                begin
                    SalesLine := Line;
                    SalesPriceCalcMgt.FindSalesLinePrice(Header, SalesLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine(PriceType::Sale, SalesLine);
                end;
            Database::Microsoft.Service.Document."Service Line":
                begin
                    ServiceLine := Line;
                    SalesPriceCalcMgt.FindServLinePrice(Header, ServiceLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine(PriceType::Sale, ServiceLine);
                end;
            Database::"Standard Item Journal Line":
                begin
                    StandardItemJournalLine := Line;
                    if StandardItemJournalLine."Entry Type" = StandardItemJournalLine."Entry Type"::Sale then begin
                        SalesPriceCalcMgt.FindStdItemJnlLinePrice(StandardItemJournalLine, CalledByFieldNo);
                        CurrLineWithPrice.SetLine(PriceType::Sale, StandardItemJournalLine);
                    end;
                end;
        end;

        OnAfterApplyPriceSalesHandler(CurrLineWithPrice, Header, Line, CalledByFieldNo);
    end;

    local procedure ApplyDiscountSalesHandler()
    var
        SalesLine: Record "Sales Line";
        ServiceLine: Record Microsoft.Service.Document."Service Line";
        Header: Variant;
        Line: Variant;
        PriceType: Enum "Price Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyDiscountSalesHandler(CurrLineWithPrice, IsHandled);
        if IsHandled then
            exit;

        if IsDisabled() then
            exit;

        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Sales Line":
                begin
                    SalesLine := Line;
                    SalesPriceCalcMgt.FindSalesLineLineDisc(Header, SalesLine);
                    CurrLineWithPrice.SetLine(PriceType::Sale, SalesLine);
                end;
            Database::Microsoft.Service.Document."Service Line":
                begin
                    ServiceLine := Line;
                    SalesPriceCalcMgt.FindServLineDisc(Header, ServiceLine);
                    CurrLineWithPrice.SetLine(PriceType::Sale, ServiceLine);
                end;
        end;
    end;

    local procedure ApplyPricePurchHandler(CalledByFieldNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        ResJournalLine: Record "Res. Journal Line";
        PriceListLine: Record "Price List Line";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
        ServiceLine: Record Microsoft.Service.Document."Service Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        Header: Variant;
        Line: Variant;
        PriceType: Enum "Price Type";
    begin
        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Item Journal Line":
                begin
                    ItemJournalLine := Line;
                    if ItemJournalLine."Entry Type" in
                        [ItemJournalLine."Entry Type"::Purchase,
                         ItemJournalLine."Entry Type"::Output,
                         ItemJournalLine."Entry Type"::"Assembly Output"]
                    then begin
                        PurchPriceCalcMgt.FindItemJnlLinePrice(ItemJournalLine, CalledByFieldNo);
                        CurrLineWithPrice.SetLine(PriceType::Purchase, ItemJournalLine);
                    end;
                end;
            Database::"Job Journal Line":
                begin
                    JobJournalLine := Line;
                    PurchPriceCalcMgt.FindJobJnlLinePrice(JobJournalLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, JobJournalLine);
                end;
            Database::"Job Planning Line":
                begin
                    JobPlanningLine := Line;
                    PurchPriceCalcMgt.FindJobPlanningLinePrice(JobPlanningLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, JobPlanningLine);
                end;
            Database::"Purchase Line":
                begin
                    PurchaseLine := Line;
                    PurchPriceCalcMgt.FindPurchLinePrice(Header, PurchaseLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, PurchaseLine);
                end;
            Database::"Price List Line":
                begin
                    PriceListLine := Line;
                    FindPriceListLine(PriceListLine);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, PriceListLine);
                end;
            Database::"Res. Journal Line":
                begin
                    ResJournalLine := Line;
                    PurchPriceCalcMgt.FindResUnitCost(ResJournalLine);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, ResJournalLine);
                end;
            Database::"Requisition Line":
                begin
                    RequisitionLine := Line;
                    PurchPriceCalcMgt.FindReqLinePrice(RequisitionLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, RequisitionLine);
                end;
            Database::"Sales Line":
                begin
                    SalesLine := Line;
                    if SalesLine.Type <> SalesLine.Type::Resource then
                        exit;
                    PurchPriceCalcMgt.FindResUnitCost(SalesLine);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, SalesLine);
                end;
            Database::Microsoft.Service.Document."Service Line":
                begin
                    ServiceLine := Line;
                    if ServiceLine.Type <> ServiceLine.Type::Resource then
                        exit;
                    PurchPriceCalcMgt.FindResUnitCost(ServiceLine);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, ServiceLine);
                end;
            Database::"Standard Item Journal Line":
                begin
                    StandardItemJournalLine := Line;
                    if StandardItemJournalLine."Entry Type" in
                        [StandardItemJournalLine."Entry Type"::Purchase,
                         StandardItemJournalLine."Entry Type"::Output]
                    then begin
                        PurchPriceCalcMgt.FindStdItemJnlLinePrice(StandardItemJournalLine, CalledByFieldNo);
                        CurrLineWithPrice.SetLine(PriceType::Purchase, StandardItemJournalLine);
                    end;
                end;
        end;
        OnAfterApplyPricePurchHandler(CurrLineWithPrice, Header, Line, CalledByFieldNo);
    end;

    local procedure FindPriceListLine(var PriceListLine: Record "Price List Line")
    var
        ResourceCost: Record "Resource Cost";
    begin
        case PriceListLine."Price Type" of
            PriceListLine."Price Type"::Purchase:
                case PriceListLine."Asset Type" of
                    PriceListLine."Asset Type"::Resource:
                        begin
                            ResourceCost.Init();
                            ResourceCost.Code := PriceListLine."Asset No.";
                            ResourceCost."Work Type Code" := '';
                            OnFindPriceListLineOnBeforeRunResourceFindCost(ResourceCost, PriceListLine);
                            CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResourceCost);
                            PriceListLine."Unit Cost" := ResourceCost."Unit Cost";
                            PriceListLine."Direct Unit Cost" := ResourceCost."Direct Unit Cost";
                        end;
                end;
        end;
    end;

    local procedure ApplyDiscountPurchHandler()
    var
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Header: Variant;
        Line: Variant;
        PriceType: Enum "Price Type";
    begin
        if IsDisabled() then
            exit;

        CurrLineWithPrice.GetLine(Header, Line);
        case CurrLineWithPrice.GetTableNo() of
            Database::"Purchase Line":
                begin
                    PurchaseLine := Line;
                    PurchPriceCalcMgt.FindPurchLineLineDisc(Header, PurchaseLine);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, PurchaseLine);
                end;
            Database::"Requisition Line":
                begin
                    RequisitionLine := Line;
                    PurchPriceCalcMgt.FindReqLineDisc(RequisitionLine);
                    CurrLineWithPrice.SetLine(PriceType::Purchase, RequisitionLine);
                end;

        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyPriceSalesHandler(var CurrLineWithPrice: Interface "Line With Price"; Header: Variant; Line: Variant; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyPricePurchHandler(var CurrLineWithPrice: Interface "Line With Price"; Header: Variant; Line: Variant; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPriceListLineOnBeforeRunResourceFindCost(var ResourceCost: Record "Resource Cost"; PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyDiscountSalesHandler(var CurrLineWithPrice: Interface "Line With Price"; var IsHandled: Boolean)
    begin
    end;
}
