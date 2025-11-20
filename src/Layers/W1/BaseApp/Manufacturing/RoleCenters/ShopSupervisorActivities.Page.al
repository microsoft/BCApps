// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.RoleCenters;

using Microsoft.Foundation.Navigate;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Warehouse.Activity;

page 9041 "Shop Supervisor Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Manufacturing Cue";

    layout
    {
        area(content)
        {
            cuegroup("Production Orders")
            {
                Caption = 'Production Orders';
                field("Planned Prod. Orders - All"; Rec."Planned Prod. Orders - All")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Planned Production Orders";
                    ToolTip = 'Specifies the number of planned production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Firm Plan. Prod. Orders - All"; Rec."Firm Plan. Prod. Orders - All")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Firm Planned Prod. Orders";
                    ToolTip = 'Specifies the number of firm planned production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Released Prod. Orders - All"; Rec."Released Prod. Orders - All")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Released Production Orders";
                    ToolTip = 'Specifies the number of released production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Change Production Order Status")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Change Production Order Status';
                        RunObject = Page "Change Production Order Status";
                        ToolTip = 'Change the production order to another status, such as Released.';
                    }
                    action("Update Unit Cost")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Update Unit Cost';
                        RunObject = Report "Update Unit Cost";
                        ToolTip = 'Recalculate the unit cost of production items on production orders. The value in the Unit Cost field on the production order line is updated according to the selected options.';
                    }
                    action(Navigate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Find entries...';
                        RunObject = Page Navigate;
                        ShortCutKey = 'Ctrl+Alt+Q';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    }
                }
            }
            cuegroup(Operations)
            {
                Caption = 'Operations';
                field("Prod. Orders Routings-in Queue"; Rec."Prod. Orders Routings-in Queue")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Prod. Order Routing";
                    ToolTip = 'Specifies the number of production order routings in queue that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Prod. Orders Routings-in Prog."; Rec."Prod. Orders Routings-in Prog.")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Prod. Order Routing";
                    ToolTip = 'Specifies the number of inactive service orders that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Consumption Journal")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Consumption Journal';
                        RunObject = Page "Consumption Journal";
                        ToolTip = 'Post the consumption of material as operations are performed.';
                    }
                    action("Output Journal")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Output Journal';
                        RunObject = Page "Output Journal";
                        ToolTip = 'Post finished end items and time spent in production. ';
                    }
                }
            }
            cuegroup("Warehouse Documents")
            {
                Caption = 'Warehouse Documents';
                field("Invt. Picks to Production"; Rec."Invt. Picks to Production")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Inventory Picks";
                    ToolTip = 'Specifies the number of inventory picks that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Invt. Put-aways from Prod."; Rec."Invt. Put-aways from Prod.")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Inventory Put-aways";
                    ToolTip = 'Specifies the number of inventory put-always from production that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        Rec.SetRange("User ID Filter", UserId);
    end;
}

