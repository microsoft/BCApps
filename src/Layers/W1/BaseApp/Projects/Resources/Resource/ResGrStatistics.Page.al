// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Foundation.Period;

page 230 "Res. Gr. Statistics"
{
    Caption = 'Res. Gr. Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Resource Group";

    layout
    {
        area(content)
        {
            group(Usage)
            {
                Caption = 'Usage';
                fixed(Control1903895201)
                {
                    ShowCaption = false;
                    group("This Period")
                    {
                        Caption = 'This Period';
                        field("ResGrDateName[1]"; ResGrDateName[1])
                        {
                            ApplicationArea = Jobs;
                            ShowCaption = false;
                        }
                        field("ResGrCapacity[1]"; ResGrCapacity[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the scheduled capacity of the resource group. The amount is the sum of values in the Quantity field on project planning lines for the resource group.';
                        }
                        field("UnusedCapacity[1]"; UnusedCapacity[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Unused Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the difference between the capacity and the capacity used. It is calculated as follows: Unused Capacity = Capacity - Charg. Usage + Not Charg. Usage.';
                        }
                        field(Text000; Text000)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Not Chargeable Usage';
                            ToolTip = 'Specifies resource group usage that is not chargeable, displayed in units of measure or unit prices. Nonchargeable usage can be posted in the resource group journal and the project journal.';
                            Visible = false;
                        }
                        field("ResGrUsageUnits[1][1]"; ResGrUsageUnits[1] [1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Units';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the usage, displayed in the specified unit of measure.';
                        }
                        field("ResGrUsagePrice[1][1]"; ResGrUsagePrice[1] [1])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field("Chargeable Usage"; Text000)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Chargeable Usage';
                            ToolTip = 'Specifies the chargeable usage. Chargeable usage can be posted in the resource group journal and the project journal.';
                            Visible = false;
                        }
                        field("ResGrUsageUnits[1][2]"; ResGrUsageUnits[1] [2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Units';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the usage, displayed in the specified unit of measure.';
                        }
                        field("ResGrUsagePrice[1][2]"; ResGrUsagePrice[1] [2])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field("ChargeablePct[1]"; ChargeablePct[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Chargeable % (Units)';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of usage that applies to chargeable units. It is calculated as follows: Chargeable % = (Chargeable Units + Nonchargeable Units) x 100.';
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Year';
                        field(Placeholder2; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrCapacity[2]"; ResGrCapacity[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the scheduled capacity of the resource group. The amount is the sum of values in the Quantity field on project planning lines for the resource group.';
                        }
                        field("UnusedCapacity[2]"; UnusedCapacity[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Unused Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the difference between the capacity and the capacity used. It is calculated as follows: Unused Capacity = Capacity - Charg. Usage + Not Charg. Usage.';
                        }
                        field(Placeholder3; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrUsageUnits[2][1]"; ResGrUsageUnits[2] [1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Units';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the usage, displayed in the specified unit of measure.';
                        }
                        field("ResGrUsagePrice[2][1]"; ResGrUsagePrice[2] [1])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field(Placeholder4; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrUsageUnits[2][2]"; ResGrUsageUnits[2] [2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Units';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the usage, displayed in the specified unit of measure.';
                        }
                        field("ResGrUsagePrice[2][2]"; ResGrUsagePrice[2] [2])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field("ChargeablePct[2]"; ChargeablePct[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Chargeable % (Units)';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of usage that applies to chargeable units. It is calculated as follows: Chargeable % = (Chargeable Units + Nonchargeable Units) x 100.';
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Year';
                        field(Placeholder5; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrCapacity[3]"; ResGrCapacity[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the scheduled capacity of the resource group. The amount is the sum of values in the Quantity field on project planning lines for the resource group.';
                        }
                        field("UnusedCapacity[3]"; UnusedCapacity[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Unused Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the difference between the capacity and the capacity used. It is calculated as follows: Unused Capacity = Capacity - Charg. Usage + Not Charg. Usage.';
                        }
                        field(Placeholder6; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrUsageUnits[3][1]"; ResGrUsageUnits[3] [1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Units';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the usage, displayed in the specified unit of measure.';
                        }
                        field("ResGrUsagePrice[3][1]"; ResGrUsagePrice[3] [1])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field(Placeholder7; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrUsageUnits[3][2]"; ResGrUsageUnits[3] [2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Units';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the usage, displayed in the specified unit of measure.';
                        }
                        field("ResGrUsagePrice[3][2]"; ResGrUsagePrice[3] [2])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field("ChargeablePct[3]"; ChargeablePct[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Chargeable % (Units)';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of usage that applies to chargeable units. It is calculated as follows: Chargeable % = (Chargeable Units + Nonchargeable Units) x 100.';
                        }
                    }
                    group(Total)
                    {
                        Caption = 'Total';
                        field(Placeholder8; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrCapacity[4]"; ResGrCapacity[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the scheduled capacity of the resource group. The amount is the sum of values in the Quantity field on project planning lines for the resource group.';
                        }
                        field("UnusedCapacity[4]"; UnusedCapacity[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Unused Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the difference between the capacity and the capacity used. It is calculated as follows: Unused Capacity = Capacity - Charg. Usage + Not Charg. Usage.';
                        }
                        field(Placeholder10; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrUsageUnits[4][1]"; ResGrUsageUnits[4] [1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Units';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the usage, displayed in the specified unit of measure.';
                        }
                        field("ResGrUsagePrice[4][1]"; ResGrUsagePrice[4] [1])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field(Placeholder12; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("ResGrUsageUnits[4][2]"; ResGrUsageUnits[4] [2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Units';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the usage, displayed in the specified unit of measure.';
                        }
                        field("ResGrUsagePrice[4][2]"; ResGrUsagePrice[4] [2])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field("ChargeablePct[4]"; ChargeablePct[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Chargeable % (Units)';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of usage that applies to chargeable units. It is calculated as follows: Chargeable % = (Chargeable Units + Nonchargeable Units) x 100.';
                        }
                    }
                }
            }
            group(Sale)
            {
                Caption = 'Sale';
                fixed(Control1904230701)
                {
                    ShowCaption = false;
                    group(Control1903100001)
                    {
                        Caption = 'This Period';
                        field(Placeholder14; ResGrDateName[1])
                        {
                            ApplicationArea = Jobs;
                            ShowCaption = false;
                        }
                        field("UnitPrice[1]"; UnitPrice[1])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Invoiced';
                            ToolTip = 'Specifies the unit prices of postings of the type sale. Sales can be posted in the resource group journal and the sales lines.';
                        }
                        field("InvoicedPct[1]"; InvoicedPct[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of invoiced amounts in unit prices. It is calculated as follows: Invoiced % = (Invoiced (LCY) / Usage(Unit Price)) x 100.';
                        }
                        field("ResGrUsageCost[1]"; ResGrUsageCost[1])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Usage (Cost)';
                            ToolTip = 'Specifies values for project usage based on cost. Specifies, based on cost, how many of the resources in the group have been used.';
                        }
                        field("Profit[1]"; Profit[1])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit amounts.';
                        }
                        field("ResGrProfitPct[1]"; ResGrProfitPct[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the profit percentages.';
                        }
                    }
                    group(Control1900724401)
                    {
                        Caption = 'This Year';
                        field(Placeholer15; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("UnitPrice[2]"; UnitPrice[2])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Invoiced';
                            ToolTip = 'Specifies the unit prices of postings of the type sale. Sales can be posted in the resource group journal and the sales lines.';
                        }
                        field("InvoicedPct[2]"; InvoicedPct[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of invoiced amounts in unit prices. It is calculated as follows: Invoiced % = (Invoiced (LCY) / Usage(Unit Price)) x 100.';
                        }
                        field("ResGrUsageCost[2]"; ResGrUsageCost[2])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Usage (Cost)';
                            ToolTip = 'Specifies values for project usage based on cost. Specifies, based on cost, how many of the resources in the group have been used.';
                        }
                        field("Profit[2]"; Profit[2])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit amounts.';
                        }
                        field("ResGrProfitPct[2]"; ResGrProfitPct[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the profit percentages.';
                        }
                    }
                    group(Control1900724301)
                    {
                        Caption = 'Last Year';
                        field(Placeholder16; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("UnitPrice[3]"; UnitPrice[3])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Invoiced';
                            ToolTip = 'Specifies the unit prices of postings of the type sale. Sales can be posted in the resource group journal and the sales lines.';
                        }
                        field("InvoicedPct[3]"; InvoicedPct[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of invoiced amounts in unit prices. It is calculated as follows: Invoiced % = (Invoiced (LCY) / Usage(Unit Price)) x 100.';
                        }
                        field("ResGrUsageCost[3]"; ResGrUsageCost[3])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Usage (Cost)';
                            ToolTip = 'Specifies values for project usage based on cost. Specifies, based on cost, how many of the resources in the group have been used.';
                        }
                        field("Profit[3]"; Profit[3])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit amounts.';
                        }
                        field("ResGrProfitPct[3]"; ResGrProfitPct[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the profit percentages.';
                        }
                    }
                    group(Control1900724201)
                    {
                        Caption = 'Total';
                        field(Placeholder17; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field("UnitPrice[4]"; UnitPrice[4])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Invoiced';
                            ToolTip = 'Specifies the unit prices of postings of the type sale. Sales can be posted in the resource group journal and the sales lines.';
                        }
                        field("InvoicedPct[4]"; InvoicedPct[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of invoiced amounts in unit prices. It is calculated as follows: Invoiced % = (Invoiced (LCY) / Usage(Unit Price)) x 100.';
                        }
                        field("ResGrUsageCost[4]"; ResGrUsageCost[4])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Usage (Cost)';
                            ToolTip = 'Specifies values for project usage based on cost. Specifies, based on cost, how many of the resources in the group have been used.';
                        }
                        field("Profit[4]"; Profit[4])
                        {
                            ApplicationArea = Jobs;
                            AutoFormatType = 1;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit amounts.';
                        }
                        field("ResGrProfitPct[4]"; ResGrProfitPct[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the profit percentages.';
                        }
                    }
                }
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
            DateFilterCalc.CreateAccountingPeriodFilter(ResGrDateFilter[1], ResGrDateName[1], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(ResGrDateFilter[2], ResGrDateName[2], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(ResGrDateFilter[3], ResGrDateName[3], CurrentDate, -1);
        end;

        Clear(TotalUsageUnits);

        for i := 1 to 4 do begin
            Rec.SetFilter("Date Filter", ResGrDateFilter[i]);
            Rec.SetRange("Chargeable Filter");
            Rec.CalcFields(Capacity, "Usage (Cost)", "Sales (Price)");

            ResGrCapacity[i] := Rec.Capacity;
            ResGrUsageCost[i] := Rec."Usage (Cost)";
            UnitPrice[i] := Rec."Sales (Price)";

            for j := 1 to 2 do begin
                if j = 1 then
                    Chargeable := false
                else
                    Chargeable := true;
                Rec.SetRange("Chargeable Filter", Chargeable);
                Rec.CalcFields("Usage (Qty.)", "Usage (Price)");
                ResGrUsageUnits[i] [j] := Rec."Usage (Qty.)";
                ResGrUsagePrice[i] [j] := Rec."Usage (Price)";
                TotalUsageUnits[i] := TotalUsageUnits[i] + Rec."Usage (Qty.)";
            end;

            UnusedCapacity[i] := ResGrCapacity[i] - TotalUsageUnits[i];
            ChargeablePct[i] := CalcPercentage(ResGrUsageUnits[i] [2], TotalUsageUnits[i]);
            InvoicedPct[i] := CalcPercentage(UnitPrice[i], ResGrUsagePrice[i] [2]);
            Profit[i] := UnitPrice[i] - ResGrUsageCost[i];
            ResGrProfitPct[i] := CalcPercentage(Profit[i], UnitPrice[i]);
        end;

        Rec.SetRange("Date Filter");
        Rec.SetRange("Chargeable Filter");
    end;

    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
        ResGrDateName: array[4] of Text[30];
        i: Integer;
        j: Integer;
        Chargeable: Boolean;
        CurrentDate: Date;
        ResGrUsageCost: array[4] of Decimal;
        UnitPrice: array[4] of Decimal;
        TotalUsageUnits: array[4] of Decimal;
        ResGrUsageUnits: array[4, 2] of Decimal;
        ResGrUsagePrice: array[4, 2] of Decimal;
        ChargeablePct: array[4] of Decimal;
        InvoicedPct: array[4] of Decimal;
        Profit: array[4] of Decimal;
        ResGrProfitPct: array[4] of Decimal;
#pragma warning disable AA0074
        Text000: Label 'Placeholder';
#pragma warning restore AA0074

    protected var
        ResGrDateFilter: array[4] of Text[30];
        ResGrCapacity: array[4] of Decimal;
        UnusedCapacity: array[4] of Decimal;

    local procedure CalcPercentage(PartAmount: Decimal; Base: Decimal): Decimal
    begin
        if Base <> 0 then
            exit(100 * PartAmount / Base);

        exit(0);
    end;
}

