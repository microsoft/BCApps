// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

page 550 "VAT Rate Change Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Rate Change Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "VAT Rate Change Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("VAT Rate Change Tool Completed"; Rec."VAT Rate Change Tool Completed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT rate change conversion is complete.';
                }
                field("Perform Conversion"; Rec."Perform Conversion")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the VAT rate conversion is performed on existing data.';
                }
            }
            group("Master Data")
            {
                Caption = 'Master Data';
                field("Update G/L Accounts"; Rec."Update G/L Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for general ledger accounts.';
                }
                field("Account Filter"; Rec."Account Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which accounts will be updated by setting appropriate filters.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpGLAccountFilter(Text));
                    end;
                }
                field("Update Items"; Rec."Update Items")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for items.';
                }
                field("Item Filter"; Rec."Item Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which items will be updated by setting appropriate filters.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpItemFilter(Text));
                    end;
                }
                field("Update Resources"; Rec."Update Resources")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for resources.';
                }
                field("Resource Filter"; Rec."Resource Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which resources will be updated by setting appropriate filters.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpResourceFilter(Text));
                    end;
                }
                field("Update Item Templates"; Rec."Update Item Templates")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that VAT rate changes are updated for item categories.';
                }
                field("Update Item Charges"; Rec."Update Item Charges")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the VAT rate change for item charges.';
                }
                field("Update Gen. Prod. Post. Groups"; Rec."Update Gen. Prod. Post. Groups")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the VAT rate change for general product posting groups.';
                }
            }
            group(Journals)
            {
                Caption = 'Journals';
                field("Update Gen. Journal Lines"; Rec."Update Gen. Journal Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for general journal lines.';
                }
                field("Update Gen. Journal Allocation"; Rec."Update Gen. Journal Allocation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for general journal allocation.';
                }
                field("Update Std. Gen. Jnl. Lines"; Rec."Update Std. Gen. Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for standard general journal lines.';
                }
                field("Update Res. Journal Lines"; Rec."Update Res. Journal Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for resource journal lines.';
                }
                field("Update Job Journal Lines"; Rec."Update Job Journal Lines")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the VAT rate change for job journal lines.';
                }
                field("Update Requisition Lines"; Rec."Update Requisition Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for requisition lines.';
                }
                field("Update Std. Item Jnl. Lines"; Rec."Update Std. Item Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for standard item journal lines.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                field("Update Sales Documents"; Rec."Update Sales Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for sales documents.';
                }
                field("Ignore Status on Sales Docs."; Rec."Ignore Status on Sales Docs.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that all existing sales documents regardless of status, including documents with a status of released, are updated.';
                }
                field("Update Purchase Documents"; Rec."Update Purchase Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for purchase documents.';
                }
                field("Ignore Status on Purch. Docs."; Rec."Ignore Status on Purch. Docs.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies all existing purchase documents regardless of status, including documents with a status of released, are updated.';
                }
                field("Update Reminders"; Rec."Update Reminders")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the VAT rate change for reminders.';
                }
                field("Update Finance Charge Memos"; Rec."Update Finance Charge Memos")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the VAT rate change for finance charge memos.';
                }
            }
            group("Unit Price Incl. VAT")
            {
                Caption = 'Unit Price Incl. VAT';
                field("Update Unit Price For G/L Acc."; Rec."Update Unit Price For G/L Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the unit price must be updated for document lines that have the type G/L Account.';
                }
                field("Upd. Unit Price For Item Chrg."; Rec."Upd. Unit Price For Item Chrg.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the unit price must be updated for document lines that have the type Charge (Item).';
                }
                field("Upd. Unit Price For FA"; Rec."Upd. Unit Price For FA")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the unit price must be updated for document lines that have the type Fixed Asset.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("S&etup")
            {
                Caption = 'S&etup';
                Image = Setup;
                action("VAT Prod. Posting Group Conv.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Prod. Posting Group Conv.';
                    Image = Registered;
                    RunObject = Page "VAT Prod. Posting Group Conv.";
                    ToolTip = 'View or edit the VAT product posting groups for VAT rate change conversion. The VAT product group codes determine calculation and posting of VAT according to the type of item or resource being purchased or the type of item or resource being sold. For each VAT product posting group conversion, the window contains a line where you specify if the current posting group will be updated by the new posting group.';
                }
                action("Gen. Prod. Posting Group Conv.")
                {
                    ApplicationArea = Suite;
                    Caption = 'Gen. Prod. Posting Group Conv.';
                    Image = GeneralPostingSetup;
                    RunObject = Page "Gen. Prod. Posting Group Conv.";
                    ToolTip = 'View or edit the general product posting groups for VAT rate change conversion. The general product posting group codes determine posting according to the type of item and resource being purchased or sold. For each general product posting group conversion, the window contains a line where you specify the current posting group that will be updated by the new posting group.';
                }
            }
            group("F&unction")
            {
                Caption = 'F&unction';
                Image = "Action";
                action("&Convert")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Convert';
                    Image = PostOrder;
                    RunObject = Codeunit "VAT Rate Change Conversion";
                    ToolTip = 'Convert the selected VAT rate.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("VAT Rate Change Log Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Rate Change Log Entries';
                    Image = ChangeLog;
                    RunObject = Page "VAT Rate Change Log Entries";
                    ToolTip = 'The general product posting group codes determine posting according to the type of item and resource being purchased or sold. For each general product posting group conversion, the window contains a line where you specify the current posting group that will be updated by the new posting group.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("VAT Prod. Posting Group Conv._Promoted"; "VAT Prod. Posting Group Conv.")
                {
                }
                actionref("Gen. Prod. Posting Group Conv._Promoted"; "Gen. Prod. Posting Group Conv.")
                {
                }
                actionref("&Convert_Promoted"; "&Convert")
                {
                }
                actionref("VAT Rate Change Log Entries_Promoted"; "VAT Rate Change Log Entries")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

