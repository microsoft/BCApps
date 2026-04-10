// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Displays line items for posted finance charge memos as a read-only subpage.
/// </summary>
page 451 "Issued Fin. Charge Memo Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Issued Fin. Charge Memo Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = RemainingAmountEmphasize;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = AmountEmphasize;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
        RemainingAmountOnFormat();
        AmountOnFormat();
    end;

    var
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;
        RemainingAmountEmphasize: Boolean;
        AmountEmphasize: Boolean;

    local procedure DescriptionOnFormat()
    begin
        if Rec."Detailed Interest Rates Entry" then
            DescriptionIndent := 2;
        DescriptionEmphasize := not Rec."Detailed Interest Rates Entry";
    end;

    local procedure RemainingAmountOnFormat()
    begin
        RemainingAmountEmphasize := not Rec."Detailed Interest Rates Entry";
    end;

    local procedure AmountOnFormat()
    begin
        AmountEmphasize := not Rec."Detailed Interest Rates Entry";
    end;
}

