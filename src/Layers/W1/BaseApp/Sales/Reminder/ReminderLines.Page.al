// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Foundation.ExtendedText;

/// <summary>
/// Displays the line items of a reminder document as an editable subpage part.
/// </summary>
page 435 "Reminder Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Reminder Line";

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
                        SetShowMandatoryConditions();
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = TypeIsGLAccount;

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
                    ShowMandatory = TypeIsCustomerLedgerEntry;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = TypeIsCustomerLedgerEntry;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupDocNo();
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
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
                    Style = Strong;
                    StyleExpr = OriginalAmountEmphasize;
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
                field("No. of Reminders"; Rec."No. of Reminders")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Reminder Level';
                    Visible = false;
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Applies-to Document Type"; Rec."Applies-to Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Applies-to Document No."; Rec."Applies-to Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
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

    trigger OnAfterGetCurrRecord()
    begin
        SetShowMandatoryConditions();
    end;

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
        OriginalAmountOnFormat();
        RemainingAmountOnFormat();
        AmountOnFormat();
    end;

    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;
        OriginalAmountEmphasize: Boolean;
        RemainingAmountEmphasize: Boolean;
        AmountEmphasize: Boolean;
        TypeIsGLAccount: Boolean;
        TypeIsCustomerLedgerEntry: Boolean;

    /// <summary>
    /// Inserts extended text for the current reminder line if available.
    /// </summary>
    /// <param name="Unconditionally">True to insert extended text without conditions.</param>
    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        OnBeforeInsertExtendedText(Rec);

        if TransferExtendedText.ReminderCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            TransferExtendedText.InsertReminderExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate() then
            CurrPage.Update();
    end;

    local procedure TypeOnAfterValidate()
    begin
        InsertExtendedText(false);
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        if Rec."Detailed Interest Rates Entry" then
            DescriptionIndent := 2;
        DescriptionEmphasize := not Rec."Detailed Interest Rates Entry";
    end;

    local procedure OriginalAmountOnFormat()
    begin
        OriginalAmountEmphasize := not Rec."Detailed Interest Rates Entry";
    end;

    local procedure RemainingAmountOnFormat()
    begin
        RemainingAmountEmphasize := not Rec."Detailed Interest Rates Entry";
    end;

    local procedure AmountOnFormat()
    begin
        AmountEmphasize := not Rec."Detailed Interest Rates Entry";
    end;

    local procedure SetShowMandatoryConditions()
    begin
        TypeIsGLAccount := Rec.Type = Rec.Type::"G/L Account";
        TypeIsCustomerLedgerEntry := Rec.Type = Rec.Type::"Customer Ledger Entry"
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var ReminderLine: Record "Reminder Line")
    begin
    end;
}

