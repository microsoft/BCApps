// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Document;

codeunit 5984 "Serv. Price Calculation V15"
{

    var
        ServPriceCalcMgt: Codeunit "Serv. Price Calc. Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnCountDiscount', '', true, true)]
    local procedure OnCountDiscount(TableID: Integer; Header: Variant; Line: Variant; ShowAll: Boolean; var Result: Integer)
    begin
        case TableID of
            Database::"Service Line":
                Result := ServPriceCalcMgt.NoOfServLineLineDisc(Header, Line, ShowAll);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnCountPrice', '', true, true)]
    local procedure OnCountPrice(TableID: Integer; Header: Variant; Line: Variant; ShowAll: Boolean; var Result: Integer)
    begin
        case TableID of
            Database::"Service Line":
                Result := ServPriceCalcMgt.NoOfServLinePrice(Header, Line, ShowAll);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnIsDiscountExists', '', true, true)]
    local procedure OnIsDiscountExists(TableID: Integer; Header: Variant; Line: Variant; ShowAll: Boolean; var Result: Boolean)
    begin
        case TableID of
            Database::"Service Line":
                Result := ServPriceCalcMgt.ServLineLineDiscExists(Header, Line, ShowAll);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnIsPriceExists', '', true, true)]
    local procedure OnIsPriceExists(TableID: Integer; Header: Variant; Line: Variant; ShowAll: Boolean; var Result: Boolean)
    begin
        case TableID of
            Database::"Service Line":
                Result := ServPriceCalcMgt.ServLinePriceExists(Header, Line, ShowAll);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnPickDiscount', '', true, true)]
    local procedure OnPickDiscount(TableID: Integer; Header: Variant; Line: Variant; var PriceType: Enum "Price Type")
    begin
        case TableID of
            Database::"Service Line":
                begin
                    ServPriceCalcMgt.GetServLineLineDisc(Header, Line);
                    PriceType := PriceType::Sale;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnPickPrice', '', true, true)]
    local procedure OnPickPrice(TableID: Integer; Header: Variant; Line: Variant)
    begin
        case TableID of
            Database::"Service Line":
                ServPriceCalcMgt.GetServLinePrice(Header, Line);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnAfterApplyPriceSalesHandler', '', true, true)]
    local procedure OnAfterApplyPriceSalesHandler(var CurrLineWithPrice: Interface "Line With Price"; Header: Variant; Line: Variant; CalledByFieldNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        case CurrLineWithPrice.GetTableNo() of
            Database::"Service Line":
                begin
                    ServiceLine := Line;
                    ServPriceCalcMgt.FindServLinePrice(Header, ServiceLine, CalledByFieldNo);
                    CurrLineWithPrice.SetLine("Price Type"::Sale, ServiceLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnAfterApplyDiscountSalesHandler', '', true, true)]
    local procedure OnAfterApplyDiscountSalesHandler(var CurrLineWithPrice: Interface "Line With Price"; Header: Variant; Line: Variant)
    var
        ServiceLine: Record "Service Line";
    begin
        case CurrLineWithPrice.GetTableNo() of
            Database::"Service Line":
                begin
                    ServiceLine := Line;
                    ServPriceCalcMgt.FindServLineDisc(Header, ServiceLine);
                    CurrLineWithPrice.SetLine("Price Type"::Sale, ServiceLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnAfterApplyPricePurchHandler', '', true, true)]
    local procedure OnAfterApplyPricePurchHandler(var CurrLineWithPrice: Interface "Line With Price"; Header: Variant; Line: Variant; CalledByFieldNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        case CurrLineWithPrice.GetTableNo() of
            Database::"Service Line":
                begin
                    ServiceLine := Line;
                    if ServiceLine.Type <> ServiceLine.Type::Resource then
                        exit;
                    ServPriceCalcMgt.FindResUnitCost(ServiceLine);
                    CurrLineWithPrice.SetLine("Price Type"::Purchase, ServiceLine);
                end;
        end;
    end;

}
