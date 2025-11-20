// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Foundation.Period;

page 9107 "Resource Statistics FactBox"
{
    Caption = 'Resource Statistics';
    PageType = CardPart;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource No.';
                ToolTip = 'Specifies a number for the resource.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field(ResCapacity; ResCapacity)
            {
                ApplicationArea = Jobs;
                Caption = 'Capacity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the scheduled capacity of the resource. The amount is the sum of values in the Quantity field on project planning lines for the resource.';
            }
            field(UnusedCapacity; UnusedCapacity)
            {
                ApplicationArea = Jobs;
                Caption = 'Unused Capacity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the difference between the capacity and the capacity used. It is calculated as follows: Unused Capacity = Capacity - Charg. Usage + Not Charg. Usage.';
            }
            field(UnitPrice; UnitPrice)
            {
                ApplicationArea = Jobs;
                AutoFormatType = 1;
                Caption = 'Invoiced';
                ToolTip = 'Specifies the unit prices of postings of the type sale. Sales can be posted in the resource group journal and the sales lines.';
            }
            field(InvoicedPct; InvoicedPct)
            {
                ApplicationArea = Jobs;
                Caption = 'Invoiced %';
                DecimalPlaces = 1 : 1;
                ToolTip = 'Specifies the percentage of invoiced amounts in unit prices. It is calculated as follows: Invoiced % = (Invoiced (LCY) / Usage(Unit Price)) x 100.';
            }
            field(ResUsageCost; ResUsageCost)
            {
                ApplicationArea = Jobs;
                AutoFormatType = 1;
                Caption = 'Usage (Cost)';
                ToolTip = 'Specifies values for project usage based on cost. Specifies, based on cost, how much the resources has been used.';
            }
            field(Profit; Profit)
            {
                ApplicationArea = Jobs;
                AutoFormatType = 1;
                Caption = 'Profit';
                ToolTip = 'Specifies the profit amounts.';
            }
            field(ResProfitPct; ResProfitPct)
            {
                ApplicationArea = Jobs;
                Caption = 'Profit %';
                DecimalPlaces = 1 : 1;
                ToolTip = 'Specifies the profit percentages.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if CurrentDate <> WorkDate() then begin
            CurrentDate := WorkDate();
            DateFilterCalc.CreateFiscalYearFilter(ResDateFilter, ResDateName, CurrentDate, 0);
        end;

        Clear(TotalUsageUnits);

        Rec.SetFilter("Date Filter", ResDateFilter);
        Rec.SetRange("Chargeable Filter");
        Rec.CalcFields(Capacity, "Usage (Cost)", "Sales (Price)");

        ResCapacity := Rec.Capacity;
        ResUsageCost := Rec."Usage (Cost)";
        UnitPrice := Rec."Sales (Price)";

        for j := 1 to 2 do begin
            if j = 1 then
                Chargeable := false
            else
                Chargeable := true;
            Rec.SetRange("Chargeable Filter", Chargeable);
            Rec.CalcFields("Usage (Qty.)", "Usage (Price)");
            ResUsagePrice := Rec."Usage (Price)";
            TotalUsageUnits := TotalUsageUnits + Rec."Usage (Qty.)";
        end;

        UnusedCapacity := ResCapacity - TotalUsageUnits;
        InvoicedPct := CalcPercentage(UnitPrice, ResUsagePrice);
        Profit := UnitPrice - ResUsageCost;
        ResProfitPct := CalcPercentage(Profit, UnitPrice);

        Rec.SetRange("Date Filter");
        Rec.SetRange("Chargeable Filter");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ResCapacity := 0;
        UnusedCapacity := 0;
        UnitPrice := 0;
        InvoicedPct := 0;
        ResUsageCost := 0;
        Profit := 0;
        ResProfitPct := 0;

        exit(Rec.Find(Which));
    end;

    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
        CurrentDate: Date;
        UnitPrice: Decimal;
        InvoicedPct: Decimal;
        ResUsageCost: Decimal;
        Profit: Decimal;
        ResProfitPct: Decimal;
        ResDateFilter: Text[30];
        ResDateName: Text[30];
        Chargeable: Boolean;
        TotalUsageUnits: Decimal;
        ResUsagePrice: Decimal;
        j: Integer;

    protected var
        ResCapacity: Decimal;
        UnusedCapacity: Decimal;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Resource Card", Rec);
    end;

    local procedure CalcPercentage(PartAmount: Decimal; Base: Decimal): Decimal
    begin
        if Base <> 0 then
            exit(100 * PartAmount / Base);

        exit(0);
    end;
}

