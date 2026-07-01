// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

page 10144 "Posted Deposit Subform"
{
    AutoSplitKey = true;
    Caption = 'Posted Deposit Subform';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Posted Deposit Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type from which the deposit was received.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number from which the deposit was received.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the transaction on the deposit line.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the deposit document.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the document (usually a check) that was deposited.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document (usually a check) that was deposited.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the item, such as a check, that was deposited.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit line.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit line.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number from the general ledger account entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(AccountCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account &Card';
                    Image = Account;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the account on the deposit line.';

                    trigger OnAction()
                    begin
                        ShowAccountCard();
                    end;
                }
                action(AccountLedgerEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Ledger E&ntries';
                    Image = LedgerEntries;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View ledger entries that are posted for the account on the deposit line.';

                    trigger OnAction()
                    begin
                        ShowAccountLedgerEntries();
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
    }

    procedure ShowDimensions()
    begin
        Rec.ShowDimensions();
    end;

    procedure ShowAccountCard()
    begin
        ShowAccountCard();
    end;

    procedure ShowAccountLedgerEntries()
    begin
        ShowAccountLedgerEntries();
    end;
}

