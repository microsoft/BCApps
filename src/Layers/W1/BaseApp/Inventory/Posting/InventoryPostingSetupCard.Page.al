// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Posting;

using Microsoft.Inventory.Item;

page 5831 "Inventory Posting Setup Card"
{
    Caption = 'Inventory Posting Setup Card';
    PageType = Card;
    SourceTable = "Inventory Posting Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location of the inventory posting.';
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
                    ToolTip = 'Specifies a description of a combination of inventory posting groups and locations.';
                }
                field("Inventory Account"; Rec."Inventory Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account to which to post transactions with the expected cost for items in this combination.';
                }
                field("Inventory Account (Interim)"; Rec."Inventory Account (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the general ledger account to which to post transactions with the expected cost for items in this combination.';
                }
                group(Manufacturing)
                {
                    Caption = 'Manufacturing';

                    field("WIP Account"; Rec."WIP Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to which to post transactions for items in WIP inventory in this combination.';
                    }
                    field("Material Variance Account"; Rec."Material Variance Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the general ledger account to which to post material variance transactions for items in this combination.';
                    }
                    field("Capacity Variance Account"; Rec."Capacity Variance Account")
                    {
                        ApplicationArea = Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the general ledger account to which to post capacity variance transactions for items in this combination.';
                    }
                    field("Mfg. Overhead Variance Account"; Rec."Mfg. Overhead Variance Account")
                    {
                        ApplicationArea = Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to which to post manufacturing overhead variance transactions for items in this combination.';
                    }
                    field("Cap. Overhead Variance Account"; Rec."Cap. Overhead Variance Account")
                    {
                        ApplicationArea = Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to which to post capacity overhead variance transactions for items in this combination.';
                    }
                    field("Subcontracted Variance Account"; Rec."Subcontracted Variance Account")
                    {
                        ApplicationArea = Manufacturing;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to which to post subcontracted variance transactions for items in this combination.';
                    }
                }
                group(Usage)
                {
                    Caption = 'Usage';
                }
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
                ToolTip = 'Suggest G/L Accounts for the selected setup. Suggestions will be based on similar setups and provide a quick setup that you can adjust to your business needs. If no similar setups exists no suggestion will be provided.';

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

