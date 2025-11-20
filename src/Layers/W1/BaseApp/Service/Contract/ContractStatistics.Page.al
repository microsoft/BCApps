// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Service.Ledger;

page 6059 "Contract Statistics"
{
    Caption = 'Contract Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Service Contract Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                fixed(Control1903895201)
                {
                    ShowCaption = false;
                    group(Resources)
                    {
                        Caption = 'Resources';
                        field("Income[1]"; Income[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Amount';
                            ToolTip = 'Specifies the net amount of all invoiced service item lines in the service contract.';
                        }
                        field("TotalDiscount[1]"; TotalDiscount[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Discount Amount';
                            ToolTip = 'Specifies the amount of discount being applied for the contract.';
                        }
                        field("TotalCost[1]"; TotalCost[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost Amount';
                            ToolTip = 'Specifies the total amount of costs for all service item lines in the service contract.';
                        }
                        field("ProfitAmount[1]"; ProfitAmount[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit Amount';
                            ToolTip = 'Specifies the amount of profit, after the cost amount has been subtracted from the total amount.';
                        }
                        field("ProfitAmountPercent[1]"; ProfitAmountPercent[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the amount of profit as a percentage of the invoiced amount.';
                        }
                        field(Placeholder; '')
                        {
                            ApplicationArea = Prepayments;
                            Caption = 'Prepaid Amount';
                            ToolTip = 'Specifies the sum of all amounts that have been prepaid.';
                        }
                        field("Total Amount"; '')
                        {
                            ApplicationArea = Service;
                            Caption = 'Total Amount';
                            ToolTip = 'Specifies the sum of the invoiced amount and the prepaid amount.';
                        }
                        field("Profit Amount"; '')
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit Amount';
                            ToolTip = 'Specifies the amount of profit, after the cost amount has been subtracted from the total amount.';
                        }
                        field("Profit %"; '')
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            ToolTip = 'Specifies the amount of profit as a percentage of the total amount.';
                        }
                    }
                    group(Items)
                    {
                        Caption = 'Items';
                        field("Income[2]"; Income[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Amount';
                            ToolTip = 'Specifies the net amount of all invoiced service item lines in the service contract.';
                        }
                        field("TotalDiscount[2]"; TotalDiscount[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Discount Amount';
                            ToolTip = 'Specifies the amount of discount being applied for the contract.';
                        }
                        field("TotalCost[2]"; TotalCost[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost Amount';
                            ToolTip = 'Specifies the total amount of costs for all service item lines in the service contract.';
                        }
                        field("ProfitAmount[2]"; ProfitAmount[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit Amount';
                            ToolTip = 'Specifies the amount of profit, after the cost amount has been subtracted from the total amount.';
                        }
                        field("ProfitAmountPercent[2]"; ProfitAmountPercent[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the amount of profit as a percentage of the invoiced amount.';
                        }
                        field(Placeholder2; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder3; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder4; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder5; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                    }
                    group("Costs && G/L Accounts")
                    {
                        Caption = 'Costs && G/L Accounts';
                        field("Income[3]"; Income[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Amount';
                            ToolTip = 'Specifies the net amount of all invoiced service item lines in the service contract.';
                        }
                        field("TotalDiscount[3]"; TotalDiscount[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Discount Amount';
                            ToolTip = 'Specifies the amount of discount being applied for the contract.';
                        }
                        field("TotalCost[3]"; TotalCost[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost Amount';
                            ToolTip = 'Specifies the total amount of costs for all service item lines in the service contract.';
                        }
                        field("ProfitAmount[3]"; ProfitAmount[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit Amount';
                            ToolTip = 'Specifies the amount of profit, after the cost amount has been subtracted from the total amount.';
                        }
                        field("ProfitAmountPercent[3]"; ProfitAmountPercent[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the amount of profit as a percentage of the invoiced amount.';
                        }
                        field(Placeholder6; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder7; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder8; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placehoder9; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                    }
                    group("Service Contracts")
                    {
                        Caption = 'Service Contracts';
                        field("Income[4]"; Income[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Amount';
                            ToolTip = 'Specifies the net amount of all invoiced service item lines in the service contract.';
                        }
                        field("TotalDiscount[4]"; TotalDiscount[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Discount Amount';
                            ToolTip = 'Specifies the amount of discount being applied for the contract.';
                        }
                        field("TotalCost[4]"; TotalCost[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost Amount';
                            ToolTip = 'Specifies the total amount of costs for all service item lines in the service contract.';
                        }
                        field("ProfitAmount[4]"; ProfitAmount[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit Amount';
                            ToolTip = 'Specifies the amount of profit, after the cost amount has been subtracted from the total amount.';
                        }
                        field("ProfitAmountPercent[4]"; ProfitAmountPercent[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the amount of profit as percentage of the invoiced amount.';
                        }
                        field(PrepaidIncome; PrepaidIncome)
                        {
                            ApplicationArea = Prepayments;
                            AutoFormatType = 1;
                            Caption = 'Prepaid Amount';
                            ToolTip = 'Specifies the sum of all amounts that have been prepaid.';
                        }
                        field(Placeholder10; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder11; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholderr12; Text000)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                    }
                    group(Total)
                    {
                        Caption = 'Total';
                        field("Income[5]"; Income[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Invoiced Amount';
                            ToolTip = 'Specifies the total amount of all invoiced service item lines in the service contract.';
                        }
                        field("TotalDiscount[5]"; TotalDiscount[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Discount Amount';
                            ToolTip = 'Specifies the total amount of discounts for all service item lines in the service contract.';
                        }
                        field("TotalCost[5]"; TotalCost[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Cost Amount';
                            ToolTip = 'Specifies the total amount of costs for all service item lines in the service contract.';
                        }
                        field("ProfitAmount[5]"; ProfitAmount[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Profit Amount';
                            ToolTip = 'Specifies the total amount of profit for all service item lines in the service contract.';
                        }
                        field("ProfitAmountPercent[5]"; ProfitAmountPercent[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the amount of profit as a percentage of the invoiced amount.';
                        }
                        field(PrepaidIncome2; PrepaidIncome)
                        {
                            ApplicationArea = Prepayments;
                            AutoFormatType = 1;
                            Caption = 'Total Prepaid Amount';
                            ToolTip = 'Specifies the sum of all amounts that have been prepaid.';
                        }
                        field(TotalIncome; TotalIncome)
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Amount';
                            ToolTip = 'Specifies the sum of the invoiced amount and the prepaid amount.';
                        }
                        field(TotalProfit; TotalProfit)
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit Amount';
                            ToolTip = 'Specifies the amount of profit, after the cost amount has been subtracted from the total amount.';
                        }
                        field(TotalProfitPct; TotalProfitPct)
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the amount of profit as percentage of the invoiced amount.';
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
    var
        ServLedgerEntry: Record "Service Ledger Entry";
    begin
        ClearAll();
        ServLedgerEntry.Reset();
        ServLedgerEntry.SetRange("Service Contract No.", Rec."Contract No.");
        ServLedgerEntry.SetRange("Entry Type", ServLedgerEntry."Entry Type"::Sale);
        Rec.SetRange("Type Filter", Rec."Type Filter"::"Service Contract");
        Rec.CalcFields(
          "Contract Invoice Amount", "Contract Prepaid Amount", "Contract Cost Amount",
          "Contract Discount Amount");

        Income[4] := Rec."Contract Invoice Amount";
        TotalDiscount[4] := Rec."Contract Discount Amount";
        TotalCost[4] := Rec."Contract Cost Amount";
        ProfitAmount[4] := Income[4] - TotalCost[4];
        ProfitAmountPercent[4] := CalcPercentage(ProfitAmount[4], Income[4]);

        Income[5] := Income[5] + Income[4];
        PrepaidIncome := Rec."Contract Prepaid Amount";

        TotalCost[5] := TotalCost[5] + TotalCost[4];
        TotalDiscount[5] := TotalDiscount[5] + TotalDiscount[4];
        for i := 1 to 3 do begin
            if i = 3 then
                Rec.SetFilter("Type Filter", '%1|%2', Rec."Type Filter"::"Service Cost", Rec."Type Filter"::"G/L Account")
            else
                Rec.SetRange("Type Filter", i);
            ServLedgerEntry.SetRange(Type, i);
            if ServLedgerEntry.FindSet() then
                repeat
                    OnAfterGetRecordOnBeforeCalcTotalDiscount(ServLedgerEntry);
                    TotalDiscount[i] := TotalDiscount[i] - ServLedgerEntry."Discount Amount";
                until ServLedgerEntry.Next() = 0;
            Rec.CalcFields("Contract Invoice Amount", "Contract Discount Amount", "Contract Cost Amount");

            Income[i] := Rec."Contract Invoice Amount";
            Income[5] := Income[5] + Rec."Contract Invoice Amount";

            TotalCost[i] := Rec."Contract Cost Amount";
            TotalCost[5] := TotalCost[5] + TotalCost[i];

            TotalDiscount[5] := TotalDiscount[5] + TotalDiscount[i];
            ProfitAmount[i] := Income[i] - TotalCost[i];
            ProfitAmount[i] := MakeNegativeZero(ProfitAmount[i]);

            ProfitAmountPercent[i] := CalcPercentage(ProfitAmount[i], Income[i]);
        end;

        TotalIncome := Income[5] + PrepaidIncome;

        ProfitAmount[5] := Income[5] - TotalCost[5];
        ProfitAmountPercent[5] := CalcPercentage(ProfitAmount[5], Income[5]);
        ProfitAmountPercent[5] := MakeNegativeZero(ProfitAmountPercent[5]);
        ProfitAmount[5] := MakeNegativeZero(ProfitAmount[5]);

        TotalProfit := TotalIncome - TotalCost[5];
        TotalProfit := MakeNegativeZero(TotalProfit);

        TotalProfitPct := CalcPercentage(TotalProfit, TotalIncome);

        Rec.SetRange("Type Filter");
    end;

    var
        i: Integer;
        PrepaidIncome: Decimal;
        TotalIncome: Decimal;
        Income: array[5] of Decimal;
        TotalCost: array[5] of Decimal;
        TotalDiscount: array[5] of Decimal;
        ProfitAmount: array[5] of Decimal;
        ProfitAmountPercent: array[5] of Decimal;
        TotalProfit: Decimal;
        TotalProfitPct: Decimal;
#pragma warning disable AA0074
        Text000: Label 'Placeholder';
#pragma warning restore AA0074

    local procedure CalcPercentage(PartAmount: Decimal; Base: Decimal): Decimal
    begin
        if Base <> 0 then
            exit(100 * PartAmount / Base);

        exit(0);
    end;

    local procedure MakeNegativeZero(Amount: Decimal): Decimal
    begin
        if Amount < 0 then
            exit(0);
        exit(Amount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnBeforeCalcTotalDiscount(var ServLedgerEntry: Record "Service Ledger Entry")
    begin
    end;
}

