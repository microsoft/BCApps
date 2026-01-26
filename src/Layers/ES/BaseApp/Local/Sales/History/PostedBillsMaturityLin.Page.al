// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

page 7000070 "Posted Bills Maturity Lin."
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
                field(DocAmtLCY; DocAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount for the posted bills for the period.';

                    trigger OnDrillDown()
                    begin
                        ShowDocs();
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
        PostedDoc.SetCurrentKey("Bank Account No.", "Bill Gr./Pmt. Order No.", Status,
          "Category Code", Redrawn, "Due Date", "Document Type");
        if PostedDoc.Type = PostedDoc.Type::Receivable then
            PostedDoc.SetRange(Type, PostedDoc.Type::Receivable)
        else
            PostedDoc.SetRange(Type, PostedDoc.Type::Payable);
        PostedDoc.SetRange("Document Type", PostedDoc."Document Type"::Bill);
        PostedDoc.CalcSums("Remaining Amt. (LCY)");
        DocAmtLCY := PostedDoc."Remaining Amt. (LCY)";
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
        PostedDoc: Record "Posted Cartera Doc.";
        PostedDoc2: Record "Posted Cartera Doc.";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        PeriodLength: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        DocAmtLCY: Decimal;
        DocType: Option Receivable,Payable;

    [Scope('OnPrem')]
    procedure Set(var NewPostedDoc: Record "Posted Cartera Doc."; NewPeriodLength: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        PostedDoc.Copy(NewPostedDoc);
        PeriodLength := "Analysis Period Type".FromInteger(NewPeriodLength);
        AmountType := "Analysis Amount Type".FromInteger(NewAmountType);
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            PostedDoc.SetRange("Due Date", Rec."Period Start", Rec."Period End")
        else
            PostedDoc.SetRange("Due Date", 0D, Rec."Period End");
    end;

    local procedure ShowDocs()
    begin
        SetDateFilter();
        if PostedDoc.Type = PostedDoc.Type::Receivable then
            PostedDoc2.SetRange(Type, PostedDoc.Type::Receivable)
        else
            PostedDoc2.SetRange(Type, PostedDoc.Type::Payable);
        PostedDoc2.SetRange("Document Type", PostedDoc."Document Type"::Bill);
        PostedDoc2.SetFilter(Type, PostedDoc.GetFilter(Type));
        PostedDoc2.SetFilter("Due Date", PostedDoc.GetFilter("Due Date"));
        PostedDoc2.SetFilter("Global Dimension 1 Code", PostedDoc.GetFilter("Global Dimension 1 Code"));
        PostedDoc2.SetFilter("Global Dimension 2 Code", PostedDoc.GetFilter("Global Dimension 2 Code"));
        PostedDoc2.SetFilter("Category Code", PostedDoc.GetFilter("Category Code"));
        PostedDoc2.SetFilter("Remaining Amt. (LCY)", '<>0');
        PAGE.RunModal(0, PostedDoc2);
    end;

    [Scope('OnPrem')]
    procedure SetType(DocType2: Option Receivable,Payable)
    begin
        DocType := DocType2;
    end;
}

