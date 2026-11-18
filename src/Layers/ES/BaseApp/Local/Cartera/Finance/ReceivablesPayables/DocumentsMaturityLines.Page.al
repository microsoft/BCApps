// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

page 7000030 "Documents Maturity Lines"
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
                // Preserve the published control name for compatibility.
#pragma warning disable AA0100
                field("Doc.""Remaining Amt. (LCY)"""; Doc."Remaining Amt. (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Amount (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the sum of amounts on the matured documents.';

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
        Doc.CalcSums("Remaining Amt. (LCY)");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
#pragma warning disable AA0139
        exit(PeriodPageManagement.FindDate(Which, Rec, PeriodLength));
#pragma warning restore AA0139
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PeriodPageManagement.NextDate(Steps, Rec, PeriodLength));
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        Doc.SetCurrentKey(
          Type, "Bill Gr./Pmt. Order No.", "Category Code", "Currency Code", Accepted, "Due Date");
    end;

    var
        Doc: Record "Cartera Doc.";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        PeriodLength: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    [Scope('OnPrem')]
    procedure Set(var NewDoc: Record "Cartera Doc."; NewPeriodLength: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        NewDoc.CopyFilter(Type, Doc.Type);
        NewDoc.CopyFilter("Bill Gr./Pmt. Order No.", Doc."Bill Gr./Pmt. Order No.");
        NewDoc.CopyFilter("Category Code", Doc."Category Code");
        NewDoc.CopyFilter("Currency Code", Doc."Currency Code");
        PeriodLength := "Analysis Period Type".FromInteger(NewPeriodLength);
        AmountType := "Analysis Amount Type".FromInteger(NewAmountType);
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Doc.SetRange("Due Date", Rec."Period Start", Rec."Period End")
        else
            Doc.SetRange("Due Date", 0D, Rec."Period End");
    end;

    local procedure ShowDocEntries()
    begin
        SetDateFilter();
        PAGE.RunModal(0, Doc);
    end;
}

