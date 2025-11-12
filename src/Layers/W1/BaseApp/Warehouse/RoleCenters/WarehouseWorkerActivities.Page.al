// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Worksheet;

page 9056 "Warehouse Worker Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Warehouse Worker WMS Cue";

    layout
    {
        area(content)
        {
            cuegroup(Outbound)
            {
                Caption = 'Outbound';
                field("Unassigned Picks"; Rec."Unassigned Picks")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Picks";
                    ToolTip = 'Specifies the number of unassigned picks that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("My Picks"; Rec."My Picks")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Picks";
                    ToolTip = 'Specifies the number of picks that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Edit Pick Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Pick Worksheet';
                        RunObject = Page "Pick Worksheet";
                        ToolTip = 'Plan and organize different kinds of picks, including picks with lines from several orders or assignment of picks to particular employees.';
                    }
                }
            }
            cuegroup(Inbound)
            {
                Caption = 'Inbound';
                field("Unassigned Put-aways"; Rec."Unassigned Put-aways")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Put-aways";
                    ToolTip = 'Specifies the number of unassigned put-always that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("My Put-aways"; Rec."My Put-aways")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Put-aways";
                    ToolTip = 'Specifies the number of put-always that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Edit Put-away Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Put-away Worksheet';
                        RunObject = Page "Put-away Worksheet";
                        ToolTip = 'Plan and organize different kinds of put-aways, including put-aways with lines from several orders. You can also assign the planned put-aways to particular warehouse employees.';
                    }
                }
            }
            cuegroup(Internal)
            {
                Caption = 'Internal';
                field("Unassigned Movements"; Rec."Unassigned Movements")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Movements";
                    ToolTip = 'Specifies the number of unassigned movements that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("My Movements"; Rec."My Movements")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Movements";
                    ToolTip = 'Specifies the number of movements that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Edit Movement Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Movement Worksheet';
                        RunObject = Page "Movement Worksheet";
                        ToolTip = 'Prepare to move items between bins within the warehouse.';
                    }
                    action("Edit Warehouse Item Journal")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Warehouse Item Journal';
                        RunObject = Page "Whse. Item Journal";
                        ToolTip = 'Adjust the quantity of an item in a particular bin or bins. For instance, you might find some items in a bin that are not registered in the system, or you might not be able to pick the quantity needed because there are fewer items in a bin than was calculated by the program. The bin is then updated to correspond to the actual quantity in the bin. In addition, it creates a balancing quantity in the adjustment bin, for synchronization with item ledger entries, which you can then post with an item journal.';
                    }
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

        Rec.SetRange("User ID Filter", UserId());

        LocationCode := WhseWMSCue.GetEmployeeLocation(UserId());
        Rec.SetFilter("Location Filter", LocationCode);
    end;

    var
        WhseWMSCue: Record "Warehouse WMS Cue";
        LocationCode: Text[1024];
}

