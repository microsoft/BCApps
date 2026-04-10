// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Foundation.ExtendedText;

/// <summary>
/// Displays and manages line items for finance charge memos as a subpage with support for extended text insertion.
/// </summary>
page 447 "Finance Charge Memo Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Finance Charge Memo Line";

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
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        TypeOnAfterValidate();
                        NoOnAfterValidate();
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = Rec.Type = Rec.Type::"G/L Account";

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate();
                    end;
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
                    ShowMandatory = Rec.Type = Rec.Type::"Customer Ledger Entry";

                    trigger OnValidate()
                    begin
                        DocumentTypeOnAfterValidate();
                    end;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = Rec.Type = Rec.Type::"Customer Ledger Entry";

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupDocNo();
                        CurrPage.Update();
                    end;

                    trigger OnValidate()
                    begin
                        DocumentNoOnAfterValidate();
                    end;
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Insert &Ext. Texts")
                {
                    AccessByPermission = TableData "Extended Text Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
        RemainingAmountOnFormat();
        AmountOnFormat();
    end;

    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;
        RemainingAmountEmphasize: Boolean;
        AmountEmphasize: Boolean;

    /// <summary>
    /// Inserts extended text for the current finance charge memo line.
    /// </summary>
    /// <param name="Unconditionally">Specifies whether to insert extended text unconditionally.</param>
    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        OnBeforeInsertExtendedText(Rec);

        if TransferExtendedText.FinChrgMemoCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            TransferExtendedText.InsertFinChrgMemoExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate() then
            CurrPage.Update();
    end;

    local procedure FormUpdateAttachedLines()
    begin
        if Rec.CheckAttachedLines() then begin
            CurrPage.SaveRecord();
            Rec.UpdateAttachedLines();
            CurrPage.Update(false);
        end;
    end;

    local procedure TypeOnAfterValidate()
    begin
        InsertExtendedText(false);
        FormUpdateAttachedLines();
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
    end;

    local procedure DocumentTypeOnAfterValidate()
    begin
        FormUpdateAttachedLines();
    end;

    local procedure DocumentNoOnAfterValidate()
    begin
        FormUpdateAttachedLines();
        CurrPage.Update();
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var FinanceChargeMemoLine: Record "Finance Charge Memo Line")
    begin
    end;
}

