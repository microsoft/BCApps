// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Displays G/L transactions with navigation to related ledger entries and reporting capabilities.
/// Provides drill-down access to G/L entries, VAT entries, and other related ledger records by transaction.
/// </summary>
/// <remarks>
/// Primary data source: G/L Transaction table. Read-only list showing posted general ledger transactions.
/// </remarks>
page 811 "G/L Transactions"
{
    AdditionalSearchTerms = 'general ledger transactions';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Transactions';
    Editable = false;
    PageType = List;
    AboutTitle = 'About G/L Transactions';
    AboutText = 'Review posted general ledger transactions.';
    SourceTable = "G/L Transaction";
    SourceTableView = sorting("No.")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Register No."; Rec."G/L Register No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. of G/L Entries"; Rec."No. of G/L Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. of VAT Entries"; Rec."No. of VAT Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. of Customer Ledger Entries"; Rec."No. of Customer Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. of Vendor Ledger Entries"; Rec."No. of Vendor Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. of Employee Ledger Entries"; Rec."No. of Employee Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Action1)
            {
                Caption = 'Set G/L Register No.';
                ApplicationArea = Basic, Suite;
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Set the G/L Register No. for this G/L transaction.';

                trigger OnAction()
                var
                    GLEntry: Record "G/L Entry";
                    GLTransaction: Record "G/L Transaction";
                begin
                    CurrPage.SetSelectionFilter(GLTransaction);
                    if GLTransaction.FindSet() then
                        repeat
                            if GLTransaction."G/L Register No." = 0 then begin
                                GLEntry.SetRange("Transaction No.", GLTransaction."No.");
                                if GLEntry.FindFirst() then begin
                                    GLTransaction."G/L Register No." := GLEntry."G/L Register No.";
                                    GLTransaction.Modify();
                                end;
                            end;
                        until GLTransaction.Next() = 0;
                end;
            }
        }
    }

}

