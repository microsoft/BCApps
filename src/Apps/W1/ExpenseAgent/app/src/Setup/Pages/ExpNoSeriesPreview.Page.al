// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;

page 6972 "Exp. No. Series Preview"
{
    Caption = 'Number series';
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "No. Series";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = true;
    Extensible = false;
    InstructionalText = 'Lists existing expense-related number series together with the defaults that will be created when you apply the setup.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the number series code.';
                    StyleExpr = StyleExpr;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a short description of the number series.';
                }
                field(Status; StatusText)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the row is a new default that will be added or already exists.';
                    StyleExpr = StyleExpr;
                }
            }
            part(NoSeriesLines; "Exp. No. Series Lines Preview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'No. Series Lines';
                SubPageLink = "Series Code" = field(Code);
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReloadPreview();
    end;

    trigger OnAfterGetRecord()
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(Rec."Code") then begin
            StatusText := ExistingLbl;
            StyleExpr := '';
        end else begin
            StatusText := NewLbl;
            StyleExpr := 'Favorable';
        end;
    end;

    local procedure ReloadPreview()
    var
        TempNoSeries: Record "No. Series" temporary;
        TempNoSeriesLine: Record "No. Series Line" temporary;
        CreateExpenseNoSeries: Codeunit "Create Expense No. Series";
    begin
        CreateExpenseNoSeries.LoadNoSeriesPreview(TempNoSeries, TempNoSeriesLine);

        Rec.Reset();
        Rec.DeleteAll();

        if TempNoSeries.FindSet() then
            repeat
                Rec := TempNoSeries;
                Rec.Insert();
            until TempNoSeries.Next() = 0;

        if Rec.FindFirst() then;

        CurrPage.NoSeriesLines.Page.Load(TempNoSeriesLine);
    end;

    var
        StatusText: Text;
        StyleExpr: Text;
        NewLbl: Label 'New';
        ExistingLbl: Label 'Existing';
}