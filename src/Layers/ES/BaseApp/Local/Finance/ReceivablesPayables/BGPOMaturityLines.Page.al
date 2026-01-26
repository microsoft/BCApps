// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

page 7000032 "BG/PO Maturity Lines"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = Date;

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
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the period shown on the line.';
                }
                field(DocAmount; DocAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrCode;
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount for the bill group or payment order for the period.';

                    trigger OnDrillDown()
                    begin
                        ShowDocEntries();
                    end;
                }
                field(DocAmountLCY; DocAmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Amount (LCY)';
                    ToolTip = 'Specifies the amount for the bill group or payment order for the period.';

                    trigger OnDrillDown()
                    begin
                        ShowDocEntries();
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
        SetDateFilter();
        if Type = Type::Receivable then begin
            BillGr.CalcFields(Amount, "Amount (LCY)");
            DocAmount := BillGr.Amount;
            DocAmountLCY := BillGr."Amount (LCY)";
        end;
        if Type = Type::Payable then begin
            PmtOrd.CalcFields(Amount, "Amount (LCY)");
            DocAmount := PmtOrd.Amount;
            DocAmountLCY := PmtOrd."Amount (LCY)";
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(PeriodPageManagement.FindDate(Which, Rec, PeriodLength));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PeriodPageManagement.NextDate(Steps, Rec, PeriodLength));
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
    end;

    var
        BillGr: Record "Bill Group";
        PmtOrd: Record "Payment Order";
        Doc: Record "Cartera Doc.";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        PeriodLength: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        DocAmount: Decimal;
        DocAmountLCY: Decimal;
        Type: Option Receivable,Payable;
        CurrCode: Code[10];

    [Scope('OnPrem')]
    procedure SetReceivable(var NewBillGr: Record "Bill Group"; NewPeriodLength: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        BillGr.Copy(NewBillGr);
        PeriodLength := "Analysis Period Type".FromInteger(NewPeriodLength);
        AmountType := "Analysis Amount Type".FromInteger(NewAmountType);
        Type := Type::Receivable;
        CurrCode := BillGr."Currency Code";
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetPayable(var NewPmtOrd: Record "Payment Order"; NewPeriodLength: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        PmtOrd.Copy(NewPmtOrd);
        PeriodLength := "Analysis Period Type".FromInteger(NewPeriodLength);
        AmountType := "Analysis Amount Type".FromInteger(NewAmountType);
        Type := Type::Payable;
        CurrCode := PmtOrd."Currency Code";
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetDateFilter()
    begin
        if Type = Type::Receivable then
            if AmountType = AmountType::"Net Change" then
                BillGr.SetRange("Due Date Filter", Rec."Period Start", Rec."Period End")
            else
                BillGr.SetRange("Due Date Filter", 0D, Rec."Period End");
        if Type = Type::Payable then
            if AmountType = AmountType::"Net Change" then
                PmtOrd.SetRange("Due Date Filter", Rec."Period Start", Rec."Period End")
            else
                PmtOrd.SetRange("Due Date Filter", 0D, Rec."Period End");
    end;

    local procedure ShowDocEntries()
    begin
        SetDateFilter();
        if Type = Type::Receivable then begin
            Doc.SetRange(Type, Type::Receivable);
            Doc.SetRange("Bill Gr./Pmt. Order No.", BillGr."No.");
            Doc.SetRange("Collection Agent", Doc."Collection Agent"::Bank);
            Doc.SetFilter("Due Date", BillGr.GetFilter("Due Date Filter"));
            Doc.SetFilter("Global Dimension 1 Code", BillGr.GetFilter("Global Dimension 1 Filter"));
            Doc.SetFilter("Global Dimension 2 Code", BillGr.GetFilter("Global Dimension 2 Filter"));
            Doc.SetFilter("Category Code", BillGr.GetFilter("Category Filter"));
        end;
        if Type = Type::Payable then begin
            Doc.SetRange(Type, Type::Payable);
            Doc.SetRange("Bill Gr./Pmt. Order No.", PmtOrd."No.");
            Doc.SetRange("Collection Agent", Doc."Collection Agent"::Bank);
            Doc.SetFilter("Due Date", PmtOrd.GetFilter("Due Date Filter"));
            Doc.SetFilter("Global Dimension 1 Code", PmtOrd.GetFilter("Global Dimension 1 Filter"));
            Doc.SetFilter("Global Dimension 2 Code", PmtOrd.GetFilter("Global Dimension 2 Filter"));
            Doc.SetFilter("Category Code", PmtOrd.GetFilter("Category Filter"));
        end;

        PAGE.RunModal(0, Doc);
    end;
}

