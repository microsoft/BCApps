// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Globalization;

page 38 "Item Ledger Entries"
{
    AdditionalSearchTerms = 'inventory transactions';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Ledger Entries';
    DataCaptionExpression = GetCaption();
    DataCaptionFields = "Item No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Item Ledger Entries';
    AboutText = 'Track inventory transactions and quantity changes for items, review detailed posting and cost information.';
    SourceTable = "Item Ledger Entry";
    SourceTableView = sorting("Entry No.")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim2Visible;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", Enum::"Item Tracking Type"::"Serial No.", Rec."Serial No.");
                    end;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Lot No.", Rec."Lot No.");
                    end;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Package No.", Rec."Package No.");
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(RunningBalance; CalcRunningInvBalance.GetItemBalance(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Inventory';
                    ToolTip = 'Specifies the inventory at date including this entry.';
                    DecimalPlaces = 0 : 5;
                    Visible = false;
                }
                field(RunningBalanceLoc; CalcRunningInvBalance.GetItemBalanceLoc(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Inventory by Location';
                    ToolTip = 'Specifies the inventory at date including this entry, for this location.';
                    DecimalPlaces = 0 : 5;
                    Visible = false;
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                }
                field("Remaining Qty. by Date"; Rec."Remaining Qty. by Date")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Visible = false;
                }
                field("Shipped Qty. Not Returned"; Rec."Shipped Qty. Not Returned")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Sales Amount (Expected)"; Rec."Sales Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected sales amount, in LCY.';
                    Visible = false;
                }
                field("Sales Amount (Actual)"; Rec."Sales Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales amount, in LCY.';
                }
                field("Cost Amount (Expected)"; Rec."Cost Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected cost, in LCY, of the quantity posting.';
                    Visible = false;
                }
                field("Cost Amount (Actual)"; Rec."Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted cost, in LCY, of the quantity posting.';
                }
                field("Cost Amount (Non-Invtbl.)"; Rec."Cost Amount (Non-Invtbl.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted non-inventoriable cost, that is an item charge assigned to an outbound entry.';
                }
                field("Cost Amount (Expected) (ACY)"; Rec."Cost Amount (Expected) (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected cost, in ACY, of the quantity posting.';
                    Visible = false;
                }
                field("Cost Amount (Actual) (ACY)"; Rec."Cost Amount (Actual) (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted cost of the entry, in the additional reporting currency.';
                    Visible = false;
                }
                field("Cost Amount (Non-Invtbl.)(ACY)"; Rec."Cost Amount (Non-Invtbl.)(ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted non-inventoriable cost, that is, an item charge assigned to an outbound entry in the additional reporting currency.';
                    Visible = false;
                }
                field("Completely Invoiced"; Rec."Completely Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Drop Shipment"; Rec."Drop Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Assemble to Order"; Rec."Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Applied Entry to Adjust"; Rec."Applied Entry to Adjust")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AdjustCostActionsVisible;
                }
                field("Order Type"; Rec."Order Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Prod. Order Comp. Line No."; Rec."Prod. Order Comp. Line No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim8Visible;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Shows the source type that applies to the source number that is shown in the Source No. field. If the entry was posted from an item journal line, the field is blank. If posted from a sales line, the source type is Customer. If posted from a purchase line, the source type is Vendor. If the entry resulted from the production of a BOM (bill of materials), the source type is Item.';
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Shows where the entry originated. If the entry was posted from an item journal line, the field will be empty. If the entry was posted from an purchase order, purchase invoice or purchase credit memo, the field displays the buy-from vendor number. If it is posted from sales the sell-to customer number will be displayed.';
                    Visible = false;
                }
                field("Source Description"; InventoryLedgerSourceMgt.GetSourceDescription(Rec."Source Type", Rec."Source No."))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Description';
                    ToolTip = 'Specifies the name or description of the source. Analysis mode must be used for sorting and filtering on this field.';
                    Visible = false;
                }
                field("Source Order No."; InventoryLedgerSourceMgt.GetSourceOrderNo(Rec."Document Type", Rec."Document No."))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Order No.';
                    ToolTip = 'Specifies the order number of the source document this entry is associated with. Analysis mode must be used for sorting and filtering on this field.';
                    Visible = false;
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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        Rec.SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter());
                    end;
                }
                action("&Value Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Item Ledger Entry No." = field("Entry No.");
                    RunPageView = sorting("Item Ledger Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    ToolTip = 'View the ledger entries that have been applied to this record.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Show Applied Entries", Rec);
                    end;
                }
                action("Reservation Entries")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                action("Application Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Application Worksheet';
                    Image = ApplicationWorksheet;
                    ToolTip = 'View item applications that are automatically created between item ledger entries during item transactions.';

                    trigger OnAction()
                    var
                        ApplicationWorksheet: Page "Application Worksheet";
                    begin
                        Clear(ApplicationWorksheet);
                        ApplicationWorksheet.SetRecordToShow(Rec);
                        ApplicationWorksheet.Run();
                    end;
                }
                action("Item Application Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Application Entries';
                    Image = EntriesList;
                    Visible = AdjustCostActionsVisible;
                    ToolTip = 'View the item application entries that are created when you post item transactions.';

                    trigger OnAction()
                    var
                        ItemApplicationEntry: Record "Item Application Entry";
                    begin
                        if Rec.Positive then begin
                            ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.");
                            ItemApplicationEntry.SetRange("Inbound Item Entry No.", Rec."Entry No.");
                        end else begin
                            ItemApplicationEntry.SetCurrentKey("Outbound Item Entry No.");
                            ItemApplicationEntry.SetRange("Outbound Item Entry No.", Rec."Entry No.");
                        end;

                        Page.Run(0, ItemApplicationEntry);
                    end;
                }
                action("Mark For Adjustment")
                {
                    Caption = 'Mark for adjustment';
                    Image = SelectEntries;
                    Visible = AdjustCostActionsVisible;
                    ToolTip = 'Mark that it is necessary to run the cost adjustment for the selected item ledger entries.';

                    trigger OnAction()
                    begin
                        SetAppliedEntriesToAdjust();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Order &Tracking")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        OrderTracking: Page "Order Tracking";
                    begin
                        OrderTracking.SetItemLedgEntry(Rec);
                        OrderTracking.RunModal();
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
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 3.';

                    actionref("Applied E&ntries_Promoted"; "Applied E&ntries")
                    {
                    }
                    actionref("Reservation Entries_Promoted"; "Reservation Entries")
                    {
                    }
                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                    actionref(SetDimensionFilter_Promoted; SetDimensionFilter)
                    {
                    }
                    actionref("&Value Entries_Promoted"; "&Value Entries")
                    {
                    }
                }
                actionref("Order &Tracking_Promoted"; "Order &Tracking")
                {
                }
                actionref("Application Worksheet_Promoted"; "Application Worksheet")
                {
                }
                actionref("Item Application Entries_Promoted"; "Item Application Entries")
                {
                }
                actionref("Mark For Adjustment_Promoted"; "Mark For Adjustment")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    analysisviews
    {
        analysisview("Inventory on hand")
        {
            Caption = 'Inventory on hand';
            DefinitionFile = './Inventory/Ledger/Inventory on hand.analysis.json';
            ToolTip = 'Get an overview of items that are available in your inventory.';
        }
        analysisview("Inventory throughput")
        {
            Caption = 'Inventory throughput';
            DefinitionFile = './Inventory/Ledger/Inventory throughput.analysis.json';
            ToolTip = 'Get an overview of purchases and sales in your inventory by month.';
        }
        analysisview("Inventory movements")
        {
            Caption = 'Inventory movements';
            DefinitionFile = './Inventory/Ledger/Inventory movements.analysis.json';
            ToolTip = 'Get an overview of how goods in your inventory move between locations.';
        }
        analysisview("Returned items by return reason")
        {
            Caption = 'Returned items by return reason';
            DefinitionFile = './Inventory/Ledger/Returned items by return reason.analysis.json';
            ToolTip = 'Get an overview of goods that customers return, categorised by the return reason. Use this for analysis for quality control.';
        }
    }

    trigger OnOpenPage()
    begin
        OnBeforeOpenPage();

        if (Rec.GetFilters() <> '') and not Rec.Find() then
            if Rec.FindFirst() then;

        SetDimVisibility();
    end;

    var
        CalcRunningInvBalance: Codeunit "Calc. Running Inv. Balance";
        InventoryLedgerSourceMgt: Codeunit "Invt. Ledger Source Mgt.";
        Navigate: Page Navigate;
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        AdjustCostActionsVisible: Boolean;
        AppliedEntriesMarkedToAdjustMsg: Label 'The applied entries have been marked to be adjusted. You can run the cost adjustment from the Adjust Cost - Item Entries batch job.';

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

    local procedure GetCaption() Result: Text
    var
        GLSetup: Record "General Ledger Setup";
        ObjTransl: Record "Object Translation";
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        SourceTableName: Text;
        SourceFilter: Text;
        SourceDescription: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCaption(Rec, Result, IsHandled);
        if IsHandled then
            exit;

        SourceDescription := '';

        case true of
            Rec.GetFilter("Item No.") <> '':
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 27);
                    SourceFilter := Rec.GetFilter("Item No.");
                    if MaxStrLen(Item."No.") >= StrLen(SourceFilter) then
                        if Item.Get(SourceFilter) then
                            SourceDescription := Item.Description;
                end;
            Rec.GetFilter("Source No.") <> '':
                case Rec."Source Type" of
                    Rec."Source Type"::Customer:
                        begin
                            SourceTableName :=
                              ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 18);
                            SourceFilter := Rec.GetFilter("Source No.");
                            if MaxStrLen(Cust."No.") >= StrLen(SourceFilter) then
                                if Cust.Get(SourceFilter) then
                                    SourceDescription := Cust.Name;
                        end;
                    Rec."Source Type"::Vendor:
                        begin
                            SourceTableName :=
                              ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 23);
                            SourceFilter := Rec.GetFilter("Source No.");
                            if MaxStrLen(Vend."No.") >= StrLen(SourceFilter) then
                                if Vend.Get(SourceFilter) then
                                    SourceDescription := Vend.Name;
                        end;
                end;
            Rec.GetFilter("Global Dimension 1 Code") <> '':
                begin
                    GLSetup.Get();
                    Dimension.Code := GLSetup."Global Dimension 1 Code";
                    SourceFilter := Rec.GetFilter("Global Dimension 1 Code");
                    SourceTableName := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(GLSetup."Global Dimension 1 Code", SourceFilter) then
                            SourceDescription := DimValue.Name;
                end;
            Rec.GetFilter("Global Dimension 2 Code") <> '':
                begin
                    GLSetup.Get();
                    Dimension.Code := GLSetup."Global Dimension 2 Code";
                    SourceFilter := Rec.GetFilter("Global Dimension 2 Code");
                    SourceTableName := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(GLSetup."Global Dimension 2 Code", SourceFilter) then
                            SourceDescription := DimValue.Name;
                end;
            Rec.GetFilter("Document Type") <> '':
                begin
                    SourceTableName := Rec.GetFilter("Document Type");
                    SourceFilter := Rec.GetFilter("Document No.");
                    SourceDescription := Rec.GetFilter("Document Line No.");
                end;
        end;
        exit(StrSubstNo('%1 %2 %3', SourceTableName, SourceFilter, SourceDescription));
    end;

    local procedure SetAppliedEntriesToAdjust()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntryEdit: Codeunit "Item Ledger Entry-Edit";
    begin
        CurrPage.SetSelectionFilter(ItemLedgerEntry);
        ItemLedgerEntryEdit.SetAppliedEntriesToAdjust(ItemLedgerEntry);
        Message(AppliedEntriesMarkedToAdjustMsg);
    end;

    procedure ShowCostAdjustmentActions()
    begin
        AdjustCostActionsVisible := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaption(var ItemLedgerEntry: Record "Item Ledger Entry"; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOpenPage()
    begin
    end;
}

