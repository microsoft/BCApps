// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

page 351 "Customer Sales Lines"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Customer Sales Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period that you want to view.';
                }
                field(BalanceDueLCY; Rec."Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance Due (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the balance due, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowCustEntriesDue();
                    end;
                }
#pragma warning disable AA0100
                field("Cust.""Sales (LCY)"""; Rec."Sales (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the sales related to the customer, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowCustEntries();
                    end;
                }
#pragma warning disable AA0100
                field("Cust.""Profit (LCY)"""; Rec."Profit (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the profit related to the customer, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowCustEntries();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get(Rec."Period Type", Rec."Period Start") then;
        CalcLine();
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";

    protected var
        Cust: Record Customer;
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    procedure SetLines(var NewCust: Record Customer; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    begin
        Cust.Copy(NewCust);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);

        OnAfterSet(Cust, PeriodType.AsInteger(), AmountType);
    end;

    local procedure ShowCustEntries()
    begin
        SetDateFilter();
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        CustLedgEntry.SetFilter("Posting Date", Cust.GetFilter("Date Filter"));
        CustLedgEntry.SetFilter("Global Dimension 1 Code", Cust.GetFilter("Global Dimension 1 Filter"));
        CustLedgEntry.SetFilter("Global Dimension 2 Code", Cust.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, CustLedgEntry);
    end;

    local procedure ShowCustEntriesDue()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        SetDateFilter();
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Due Date", "Posting Date", "Currency Code");
        DtldCustLedgEntry.SetRange("Customer No.", Cust."No.");
        DtldCustLedgEntry.SetFilter("Initial Entry Due Date", Cust.GetFilter("Date Filter"));
        DtldCustLedgEntry.SetFilter("Posting Date", '..%1', Cust.GetRangeMax("Date Filter"));
        DtldCustLedgEntry.SetFilter("Initial Entry Global Dim. 1", Cust.GetFilter("Global Dimension 1 Filter"));
        DtldCustLedgEntry.SetFilter("Initial Entry Global Dim. 2", Cust.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, DtldCustLedgEntry)
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        Cust.CalcFields("Balance Due (LCY)", "Sales (LCY)", "Profit (LCY)");
        Rec."Balance Due (LCY)" := Cust."Balance Due (LCY)";
        Rec."Sales (LCY)" := Cust."Sales (LCY)";
        Rec."Profit (LCY)" := Cust."Profit (LCY)";

        OnAfterCalcLine(Cust, Rec);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Cust.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            Cust.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var Customer: Record Customer; var CustomerSalesBuffer: Record "Customer Sales Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(var NewCust: Record Customer; NewPeriodType: Integer; NewAmountType: Enum "Analysis Amount Type")
    begin
    end;
}

