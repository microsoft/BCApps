// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Inventory.Reports;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.Reports;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;
using System.Reflection;

page 9079 "Role Center Page Dispatcher"
{
    SourceTable = AllObjWithCaption;
    SourceTableTemporary = true;

    trigger OnOpenPage()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(Rec."Object Type", Rec."Object ID") then begin
            FindRepacementObject(AllObjWithCaption);
            case AllObjWithCaption."Object Type" of
                AllObjWithCaption."Object Type"::Page:
                    Page.Run(AllObjWithCaption."Object ID");
                AllObjWithCaption."Object Type"::Report:
                    Report.Run(AllObjWithCaption."Object ID");
            end;
        end;
        error('');
    end;

    local procedure FindRepacementObject(var AllObjWithCaption: Record AllObjWithCaption)
    begin
        case AllObjWithCaption."Object Type" of
            AllObjWithCaption."Object Type"::Page:
                GetPageReplacement(AllObjWithCaption);
            AllObjWithCaption."Object Type"::Report:
                GetReportReplacement(AllObjWithCaption);
        end
    end;

    local procedure GetPageReplacement(var AllObjWithCaption: Record AllObjWithCaption)
    begin
        case AllObjWithCaption."Object ID" of
            Page::"Purchase Prices",
            Page::"Purchase Line Discounts":
                if IsExtendedPriceCalculationEnabled() then
                    AllObjWithCaption."Object ID" := Page::"Purchase Price Lists";
            Page::"Resource Costs":
                if IsExtendedPriceCalculationEnabled() then
                    AllObjWithCaption."Object ID" := Page::"Purchase Job Price Lists";
            Page::"Resource Prices":
                if IsExtendedPriceCalculationEnabled() then
                    AllObjWithCaption."Object ID" := Page::"Sales Job Price Lists";
            Page::"Resource Price Changes":
                if IsExtendedPriceCalculationEnabled() then
                    AllObjWithCaption."Object ID" := Page::"Price Worksheet";
            Page::"Sales Prices",
            Page::"Sales Line Discounts":
                if IsExtendedPriceCalculationEnabled() then
                    AllObjWithCaption."Object ID" := Page::"Sales Price Lists";
            Page::"Sales Price Worksheet":
                if IsExtendedPriceCalculationEnabled() then
                    AllObjWithCaption."Object ID" := Page::"Price Worksheet";
        end;
    end;

    local procedure GetReportReplacement(var AllObjWithCaption: Record AllObjWithCaption)
    begin
        case AllObjWithCaption."Object ID" of
            Report::"Price List":
                if IsExtendedPriceCalculationEnabled() then
                    AllObjWithCaption."Object ID" := Report::"Item Price List";
            Report::"Resource - Price List":
                if IsExtendedPriceCalculationEnabled() then
                    AllObjWithCaption."Object ID" := Report::"Res. Price List";
            Report::"Suggest Res. Price Chg. (Res.)",
            Report::"Suggest Res. Price Chg.(Price)",
            Report::"Implement Res. Price Change":
                if IsExtendedPriceCalculationEnabled() then begin
                    AllObjWithCaption."Object Type" := AllObjWithCaption."Object Type"::Page;
                    AllObjWithCaption."Object ID" := Page::"Price Worksheet";
                end;
        end;
    end;

    local procedure IsExtendedPriceCalculationEnabled(): Boolean;
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        exit(PriceCalculationMgt.IsExtendedPriceCalculationEnabled());
    end;
}
