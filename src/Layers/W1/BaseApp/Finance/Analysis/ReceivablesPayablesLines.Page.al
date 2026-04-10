// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

/// <summary>
/// List part displaying receivables and payables period analysis by customer and vendor ledger data.
/// Provides period-by-period breakdown of outstanding receivables and payables balances for cash flow analysis.
/// </summary>
page 355 "Receivables-Payables Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Receivables-Payables Buffer";
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
                    ApplicationArea = Suite;
                    Caption = 'Period Start';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Period Name';
                }
                field(CustBalancesDue; Rec."Cust. Balances Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Cust. Balances Due';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        ShowCustEntriesDue();
                    end;
                }
                field(VendorBalancesDue; Rec."Vendor Balances Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Vendor Balances Due';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        ShowVendEntriesDue();
                    end;
                }
                field(ReceivablesPayables; Rec."Receivables-Payables")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Receivables-Payables';
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
        VendLedgEntry: Record "Vendor Ledger Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    protected var
        GLSetup: Record "General Ledger Setup";

    /// <summary>
    /// Configures the page with general ledger setup and display parameters for receivables-payables analysis.
    /// Initializes period type, amount type, and general ledger setup for outstanding balance analysis.
    /// </summary>
    /// <param name="NewGLSetup">General Ledger Setup record containing configuration</param>
    /// <param name="NewPeriodType">Period type for data organization (Month, Quarter, Year, etc.)</param>
    /// <param name="NewAmountType">Amount type for display (Net Change, Balance at Date, etc.)</param>
    procedure SetLines(var NewGLSetup: Record "General Ledger Setup"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    begin
        GLSetup.Copy(NewGLSetup);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure ShowCustEntriesDue()
    begin
        SetDateFilter();
        CustLedgEntry.Reset();
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Due Date", GLSetup.GetFilter("Date Filter"));
        CustLedgEntry.SetFilter("Global Dimension 1 Code", GLSetup.GetFilter("Global Dimension 1 Filter"));
        CustLedgEntry.SetFilter("Global Dimension 2 Code", GLSetup.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, CustLedgEntry)
    end;

    local procedure ShowVendEntriesDue()
    begin
        SetDateFilter();
        VendLedgEntry.Reset();
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetFilter("Due Date", GLSetup.GetFilter("Date Filter"));
        VendLedgEntry.SetFilter("Global Dimension 1 Code", GLSetup.GetFilter("Global Dimension 1 Filter"));
        VendLedgEntry.SetFilter("Global Dimension 2 Code", GLSetup.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, VendLedgEntry);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            GLSetup.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            GLSetup.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        GLSetup.CalcFields("Cust. Balances Due", "Vendor Balances Due");
        Rec."Cust. Balances Due" := GLSetup."Cust. Balances Due";
        Rec."Vendor Balances Due" := GLSetup."Vendor Balances Due";
        Rec."Receivables-Payables" := GLSetup."Cust. Balances Due" - GLSetup."Vendor Balances Due";

        OnAfterCalcLine(GLSetup, Rec);
    end;

    /// <summary>
    /// Integration event raised after calculating line values for receivables-payables analysis.
    /// Enables custom calculation logic for additional balance analysis and reporting fields.
    /// </summary>
    /// <param name="GLSetup">General Ledger Setup record with calculated balances</param>
    /// <param name="ReceivablesPayablesBuffer">Buffer record containing calculated values available for modification</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var GLSetup: Record "General Ledger Setup"; var ReceivablesPayablesBuffer: Record "Receivables-Payables Buffer")
    begin
    end;
}

