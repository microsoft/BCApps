// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Foundation.Navigate;

/// <summary>
/// Displays comprehensive list of check ledger entries with filtering and navigation capabilities.
/// Provides read-only view of check transactions for analysis and lookup purposes.
/// </summary>
/// <remarks>
/// Source Table: Check Ledger Entry (272). Supports drill-down navigation and document lookup.
/// Sorted by bank account and check date in descending order for optimal user experience.
/// </remarks>
page 374 "Check Ledger Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Check Ledger Entries';
    DataCaptionFields = "Bank Account No.";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    AboutTitle = 'About Check Ledger Entries';
    AboutText = 'View, manage, and void check payments for bank accounts, including tracking check details, amounts, statuses, and related transactions within the check ledger.';
    SourceTable = "Check Ledger Entry";
    SourceTableView = sorting("Bank Account No.", "Check Date")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Check Date"; Rec."Check Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Check No."; Rec."Check No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Entry Status"; Rec."Entry Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Original Entry Status"; Rec."Original Entry Status")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
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
            group("Chec&k")
            {
                Caption = 'Chec&k';
                Image = Check;
                action("Void Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void Check';
                    Image = VoidCheck;
                    ToolTip = 'Void the check if, for example, the check is not cashed by the bank.';

                    trigger OnAction()
                    var
                        CheckManagement: Codeunit CheckManagement;
                    begin
                        CheckManagement.FinancialVoidCheck(Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
            action("Delete Entries")
            {
                ApplicationArea = All;
                Caption = 'Delete Entries';
                Image = Delete;
                RunObject = Report "Delete Check Ledger Entries";
                ToolTip = 'Find and delete check ledger entries.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Void Check_Promoted"; "Void Check")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Delete Entries_Promoted"; "Delete Entries")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        OnBeforeOnOpenPage();
        if (Rec.GetFilters() <> '') and not Rec.Find() then
            if Rec.FindFirst() then;
    end;

    var
        Navigate: Page Navigate;

    /// <summary>
    /// Integration event raised before opening the Check Ledger Entries page.
    /// Enables custom initialization or setup before page display.
    /// </summary>
    /// <remarks>
    /// Raised during page OnOpenPage trigger before standard page initialization.
    /// </remarks>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage()
    begin
    end;
}

