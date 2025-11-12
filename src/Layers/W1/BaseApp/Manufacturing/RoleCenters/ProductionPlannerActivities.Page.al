// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.RoleCenters;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Purchases.Document;
using System.Environment;
using System.Visualization;

page 9038 "Production Planner Activities"
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
                field("Simulated Prod. Orders"; Rec."Simulated Prod. Orders")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Simulated Production Orders";
                    ToolTip = 'Specifies the number of simulated production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
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
                    action("New Production Order")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'New Production Order';
                        RunObject = Page "Planned Production Order";
                        RunPageMode = Create;
                        ToolTip = 'Prepare to produce an end item. ';
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
            cuegroup("Planning - Operations")
            {
                Caption = 'Planning - Operations';
                field("Purchase Orders"; Rec."Purchase Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'My Purchase Orders';
                    DrillDown = true;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of purchase orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Purchase Order")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'New Purchase Order';
                        RunObject = Page "Purchase Order";
                        RunPageMode = Create;
                        ToolTip = 'Purchase goods or services from a vendor.';
                    }
                    action("Edit Planning Worksheet")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Edit Planning Worksheet';
                        RunObject = Page "Planning Worksheet";
                        ToolTip = 'Plan supply orders automatically to fulfill new demand.';
                    }
                    action("Edit Subcontracting Worksheet")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Edit Subcontracting Worksheet';
                        RunObject = Page "Subcontracting Worksheet";
                        ToolTip = 'Plan outsourcing of operation on released production orders.';
                    }
                }
            }
            cuegroup(Design)
            {
                Caption = 'Design';
                field("Prod. BOMs under Development"; Rec."Prod. BOMs under Development")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Production BOM List";
                    ToolTip = 'Specifies the number of production BOMs that are under development that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Routings under Development"; Rec."Routings under Development")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Routing List";
                    ToolTip = 'Specifies the routings under development that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Item")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'New Item';
                        RunObject = Page "Item Card";
                        RunPageMode = Create;
                        ToolTip = 'Create an item card based on the stockkeeping unit.';
                    }
                    action("New Production BOM")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'New Production BOM';
                        RunObject = Page "Production BOM";
                        RunPageMode = Create;
                        ToolTip = 'Create a bill of material that defines the components in a produced item.';
                    }
                    action("New Routing")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'New Routing';
                        RunObject = Page Routing;
                        RunPageMode = Create;
                        ToolTip = 'Create a routing that defines the operations required to produce an end item.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
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

        Rec.SetRange("User ID Filter", UserId());

        ShowIntelligentCloud := not EnvironmentInfo.IsSaaS();
    end;

    var
        CuesAndKpis: Codeunit "Cues And KPIs";
        EnvironmentInfo: Codeunit "Environment Information";
        ShowIntelligentCloud: Boolean;
}

