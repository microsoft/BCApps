// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Structure;
using System.Text;

page 15 "Location List"
{
    AdditionalSearchTerms = 'warehouse setup,inventory setup';
    ApplicationArea = Location;
    Caption = 'Locations';
    CardPageID = "Location Card";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Locations';
    AboutText = 'Set up and manage warehouses and other storage locations, configure inventory policies and bin settings, and track item availability and transfers between locations.';
    SourceTable = Location;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a location code for the warehouse or distribution center where your items are handled and stored before being sold.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name or address of the location.';
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
            group("&Location")
            {
                Caption = '&Location';
                Image = Warehouse;
                action("&Zones")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Zones';
                    Image = Zones;
                    RunObject = Page Zones;
                    RunPageLink = "Location Code" = field(Code);
                    ToolTip = 'View or edit information about zones that you use in your warehouse to structure your bins under zones.';
                }
                action("&Bins")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bins';
                    Image = Bins;
                    RunObject = Page Bins;
                    RunPageLink = "Location Code" = field(Code);
                    ToolTip = 'View or edit information about zones that you use in your warehouse to hold items.';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                Image = Dimensions;
                action(DimensionsSingle)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions-Single';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(14),
                                  "No." = field(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                }
                action(DimensionsMultiple)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions-&Multiple';
                    Image = DimensionSets;
                    ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                    trigger OnAction()
                    var
                        Location: Record Location;
                        DefaultDimMultiple: Page "Default Dimensions-Multiple";
                    begin
                        CurrPage.SetSelectionFilter(Location);
                        DefaultDimMultiple.SetMultiRecord(Location, Rec.FieldNo(Code));
                        DefaultDimMultiple.RunModal();
                    end;
                }
            }
        }
        area(creation)
        {
            action("Transfer Order")
            {
                ApplicationArea = Location;
                Caption = 'Transfer Order';
                Image = Document;
                RunObject = Page "Transfer Order";
                RunPageMode = Create;
                ToolTip = 'Prepare to transfer items to another location.';
            }
        }
        area(processing)
        {
            action("Create Warehouse location")
            {
                ApplicationArea = Warehouse;
                Caption = 'Convert to Warehouse location';
                Image = NewWarehouse;
                RunObject = Report "Create Warehouse Location";
                ToolTip = 'Enable the inventory location to use zones and bins to operate as a warehouse location. The batch job creates initial warehouse entries for the warehouse adjustment bin for all items that have inventory in the location. It is necessary to perform a physical inventory after this batch job is finished so that these initial entries can be balanced by posting warehouse physical inventory entries.';
            }
        }
        area(reporting)
        {
            action("Inventory - Inbound Transfer")
            {
                ApplicationArea = Location;
                Caption = 'Inventory - Inbound Transfer';
                Image = "Report";
                RunObject = Report "Inventory - Inbound Transfer";
                ToolTip = 'View the list of inbound transfers to the location.';
            }
            action(Action1907283206)
            {
                ApplicationArea = Location;
                Caption = 'Transfer Order';
                Image = Document;
                RunObject = Report "Transfer Order";
                ToolTip = 'Prepare to transfer items to another location.';
            }
            action("Transfer Shipment")
            {
                ApplicationArea = Location;
                Caption = 'Transfer Shipment';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Transfer Shipment";
                ToolTip = 'View the list of posted outbound transfers from the location.';
            }
            action("Transfer Receipt")
            {
                ApplicationArea = Location;
                Caption = 'Transfer Receipt';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Transfer Receipt";
                ToolTip = 'View the list of posted inbound transfers to the location.';
            }
            action("Items with Negative Inventory")
            {
                ApplicationArea = Location;
                Caption = 'Items with Negative Inventory';
                Image = "Report";

                ToolTip = 'View a list of items with negative inventory.';

                trigger OnAction()
                var
                    ItemsWithNegativeInventory: Report "Items with Negative Inventory";
                begin
                    ItemsWithNegativeInventory.InitializeRequest(Rec.Code);
                    ItemsWithNegativeInventory.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';
            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Create Warehouse location_Promoted"; "Create Warehouse location")
                {
                }
            }
            group(Category_Location)
            {
                Caption = 'Location';

                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref(DimensionsMultiple_Promoted; DimensionsMultiple)
                    {
                    }
                    actionref(DimensionsSingle_Promoted; DimensionsSingle)
                    {
                    }
                }
                actionref("&Zones_Promoted"; "&Zones")
                {
                }
                actionref("&Bins_Promoted"; "&Bins")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Items with Negative Inventory_Promoted"; "Items with Negative Inventory")
                {
                }
                actionref("Inventory - Inbound Transfer_Promoted"; "Inventory - Inbound Transfer")
                {
                }
                actionref(Action1907283206_Promoted; Action1907283206)
                {
                }
            }
        }
    }

    procedure GetSelectionFilter(): Text
    var
        Loc: Record Location;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Loc);
        exit(SelectionFilterManagement.GetSelectionFilterForLocation(Loc));
    end;
}

