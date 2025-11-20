// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Posting;

page 5826 "Inventory Posting Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Posting Setup';
    CardPageID = "Inventory Posting Setup Card";
    PageType = List;
    SourceTable = "Inventory Posting Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code for setting up posting groups of inventory to general ledger.';
                }
                field("Invt. Posting Group Code"; Rec."Invt. Posting Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code for the inventory posting group, in the combination of location and inventory posting group, that you are setting up.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the combination of inventory posting groups and locations.';
                }
                field("View All Accounts on Lookup"; Rec."View All Accounts on Lookup")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that all possible accounts are shown when you look up from a field. If the check box is not selected, then only accounts related to the involved account category are shown.';
                }
                field("Inventory Account"; Rec."Inventory Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the G/L account that item transactions with this combination of location and inventory posting group are posted to.';
                }
                field("Inventory Account (Interim)"; Rec."Inventory Account (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to which to post transactions with the expected cost for items in this combination.';
                }
                field("WIP Account"; Rec."WIP Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post transactions for items in WIP inventory in this combination.';
                }
                field("Material Variance Account"; Rec."Material Variance Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to which to post material variance transactions for items in this combination.';
                }
                field("Capacity Variance Account"; Rec."Capacity Variance Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the general ledger account to which to post capacity variance transactions for items in this combination.';
                }
                field("Subcontracted Variance Account"; Rec."Subcontracted Variance Account")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the general ledger account number to which to post subcontracted variance transactions for items in this combination.';
                }
                field("Cap. Overhead Variance Account"; Rec."Cap. Overhead Variance Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post capacity overhead variance transactions for items in this combination.';
                }
                field("Mfg. Overhead Variance Account"; Rec."Mfg. Overhead Variance Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post manufacturing overhead variance transactions for items in this combination.';
                }
                field("Mat. Non-Inv. Variance Acc."; Rec."Mat. Non-Inv. Variance Acc.")
                {
                    ApplicationArea = Suite;
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
        area(processing)
        {
            action(SuggestAccounts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Suggest Accounts';
                Image = Default;
                ToolTip = 'Set accounts based on most used accounts for same posting group in other locations.';

                trigger OnAction()
                begin
                    Rec.SuggestSetupAccounts();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SuggestAccounts_Promoted; SuggestAccounts)
                {
                }
            }
        }
    }
}

