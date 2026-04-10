// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Foundation.Navigate;
using System.Security.User;

page 5238 "Detailed Empl. Ledger Entries"
{
    ApplicationArea = BasicHR;
    Caption = 'Detailed Employee Ledger Entries';
    DataCaptionFields = "Employee Ledger Entry No.", "Employee No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Detailed Employee Ledger Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = BasicHR;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = BasicHR;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = BasicHR;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = BasicHR;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = BasicHR;
                }
                field("Initial Entry Global Dim. 1"; Rec."Initial Entry Global Dim. 1")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Initial Entry Global Dim. 2"; Rec."Initial Entry Global Dim. 2")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = BasicHR;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = BasicHR;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Debit Amount (LCY)"; Rec."Debit Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Credit Amount (LCY)"; Rec."Credit Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in the local currency.';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field(Unapplied; Rec.Unapplied)
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Unapplied by Entry No."; Rec."Unapplied by Entry No.")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Employee Ledger Entry No."; Rec."Employee Ledger Entry No.")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = BasicHR;
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
                action("Unapply Entries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Unapply Entries';
                    Ellipsis = true;
                    Image = UnApply;
                    ToolTip = 'Unselect one or more ledger entries that you want to unapply this record.';

                    trigger OnAction()
                    var
                        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
                    begin
                        EmplEntryApplyPostedEntries.UnApplyDtldEmplLedgEntry(Rec);
                    end;
                }
            }
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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Unapply Entries_Promoted"; "Unapply Entries")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    var
        Navigate: Page Navigate;
}

