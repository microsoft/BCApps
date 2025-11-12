// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Setup;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.Excel;
using System.Privacy;

page 99000852 "Planning Worksheet"
{
    AdditionalSearchTerms = 'supply planning,mrp,mps';
    ApplicationArea = Planning;
    AutoSplitKey = true;
    Caption = 'Planning Worksheets';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = Worksheet;
    AboutTitle = 'About Planning Worksheets';
    AboutText = 'Plan and manage supply orders for purchasing, assembly, or production by reviewing, adjusting, and prioritizing demand, then generating purchase, production, assembly, or transfer orders directly from proposed planning lines.';
    SaveValues = true;
    SourceTable = "Requisition Line";
    SourceTableView = where(Type = const(Item));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control120)
            {
                ShowCaption = false;
                field(CurrentWkshBatchName; CurrentWkshBatchName)
                {
                    ApplicationArea = Planning;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the journal batch of the planning worksheet.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        ReqJnlManagement.LookupName(CurrentWkshBatchName, Rec);
                        SetControlAppearanceFromWkshBatch();
                        CurrPage.Update(false);

                        OnAfterLookupCurrentJnlBatchName(Rec, CurrentWkshBatchName);
                    end;

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.CheckName(CurrentWkshBatchName, Rec);
                        CurrentWkshBatchNameOnAfterVal();
                    end;
                }
                field(RequisitionWkshBatchApprovalStatus; RequisitionWkshBatchApprovalStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approval Status';
                    Editable = false;
                    Visible = EnabledWkshBatchWorkflowsExist;
                    ToolTip = 'Specifies the approval status for planning worksheet batch.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Warning; Warning)
                {
                    ApplicationArea = Planning;
                    Caption = 'Warning';
                    Editable = false;
                    OptionCaption = ' ,Emergency,Exception,Attention';
                    ToolTip = 'Specifies a warning text for any planning line that is created for an unusual situation.';

                    trigger OnDrillDown()
                    begin
                        PlanningTransparency.SetCurrReqLine(Rec);
                        PlanningTransparency.DrillDownUntrackedQty('');
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the type of requisition worksheet line you are creating.';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field("Planning Level"; Rec."Planning Level")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Indicates the planning level of the item in multi-level production orders. The planning level is calculated only for items that have Make-to-Order specified in the Manufacturing Policy field.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the bin of the item on the line.';
                    Visible = false;
                }
                field("Action Message"; Rec."Action Message")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies an action to take to rebalance the demand-supply situation.';
                }
                field("Accept Action Message"; Rec."Accept Action Message")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether to accept the action message proposed for the line.';
                }
                field("Original Due Date"; Rec."Original Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the due date stated on the production or purchase order, when an action message proposes to reschedule an order.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when the related order was created.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Transfer Shipment Date"; Rec."Transfer Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the shipment date of the transfer order proposal.';
                    Visible = false;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting date and the starting time, which are combined in a format called "starting date-time".';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting time of the manufacturing process.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the starting date of the manufacturing process, if the planned supply is a production order.';
                    Visible = false;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending date and the ending time, which are combined in a format called "ending date-time".';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending time for the manufacturing process.';
                    Visible = false;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the ending date of the manufacturing process, if the planned supply is a production order.';
                    Visible = false;
                }
                field("Low-Level Code"; Rec."Low-Level Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the planning level of this item entry in the planning worksheet.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies additional text describing the entry, or a remark about the requisition worksheet line.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 3.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 4.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 5.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 6.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 7.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the code for Shortcut Dimension 8.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                    Visible = false;
                }
                field("Original Quantity"; Rec."Original Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity stated on the production or purchase order, when an action message proposes to change the quantity on an order.';
                }
                field("MPS Order"; Rec."MPS Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the requisition worksheet line is an MPS order, that is, whether it is linked to a demand forecast or a sales order.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of units of the item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies which kind of order to use to create replenishment orders and order proposals.';
                    Visible = false;
                }
                field("Supply From"; Rec."Supply From")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                    ToolTip = 'Specifies a value, according to the selected replenishment system, before a supply order can be created for the line.';
                }
                field("Ref. Order Type"; Rec."Ref. Order Type")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the order is a purchase order, a production order, or a transfer order.';
                }
                field("Ref. Order No."; Rec."Ref. Order No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the relevant production or purchase order.';
                }
                field("Ref. Order Status"; Rec."Ref. Order Status")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the status of the production order.';
                }
                field("Ref. Line No."; Rec."Ref. Line No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the purchase or production order line.';
                    Visible = false;
                }
                field("Planning Flexibility"; Rec."Planning Flexibility")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the supply, represented by the requisition worksheet line, is considered by the planning system, when calculating action messages.';
                    Visible = false;
                }
                field("Blanket Purch. Order Exists"; Rec."Blanket Purch. Order Exists")
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    ToolTip = 'Specifies if a blanket purchase order exists for the item on the requisition line.';
                    Visible = false;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of this item have been reserved.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Gen. Business Posting Group"; Rec."Gen. Business Posting Group")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code of the general business posting group to be used for the item when you post the planning worksheet.';
                    Visible = false;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the total costs for the requisition worksheet line.';
                    Visible = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the vendor who will ship the items in the purchase order.';
                    Visible = false;
                }
            }
            group(Control56)
            {
                ShowCaption = false;
                fixed(Control1902454301)
                {
                    ShowCaption = false;
                    group("Item Description")
                    {
                        Caption = 'Item Description';
                        field(ItemDescription; ItemDescription)
                        {
                            ApplicationArea = Planning;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group("Routing Description")
                    {
                        Caption = 'Routing Description';
                        field(RoutingDescription; RoutingDescription)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Routing Description';
                            Editable = false;
                            ToolTip = 'Specifies a description of the routing for the item that is entered on the line.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control9; "Item Replenishment FactBox")
            {
                ApplicationArea = Planning;
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
            part(WorkflowStatusBatch; "Workflow Status FactBox")
            {
                ApplicationArea = Suite;
                Caption = 'Batch Workflows';
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatusOnBatch;
            }
            part(Control11; "Item Planning FactBox")
            {
                ApplicationArea = Planning;
                SubPageLink = "No." = field("No.");
            }
            part(Control15; "Untracked Plng. Elements Part")
            {
                ApplicationArea = Planning;
                SubPageLink = "Worksheet Template Name" = field("Worksheet Template Name"),
                              "Worksheet Batch Name" = field("Journal Batch Name"),
                              "Worksheet Line No." = field("Line No.");
            }
            part(Control13; "Item Warehouse FactBox")
            {
                ApplicationArea = Planning;
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
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
                        CurrPage.SaveRecord();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Components)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Components';
                    Image = Components;
                    RunObject = Page "Planning Components";
                    RunPageLink = "Worksheet Template Name" = field("Worksheet Template Name"),
                                  "Worksheet Batch Name" = field("Journal Batch Name"),
                                  "Worksheet Line No." = field("Line No.");
                    ToolTip = 'View or edit the production order components of the parent item on the line.';
                    ShortCutKey = 'Ctrl+Alt+C';
                }
                group("&Item Availability by")
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ReqLineAvailabilityMgt.ShowItemAvailabilityFromReqLine(Rec, "Item Availability Type"::"Event")
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ReqLineAvailabilityMgt.ShowItemAvailabilityFromReqLine(Rec, "Item Availability Type"::Period)
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ReqLineAvailabilityMgt.ShowItemAvailabilityFromReqLine(Rec, "Item Availability Type"::Variant)
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ReqLineAvailabilityMgt.ShowItemAvailabilityFromReqLine(Rec, "Item Availability Type"::Location)
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ReqLineAvailabilityMgt.ShowItemAvailabilityFromReqLine(Rec, "Item Availability Type"::BOM)
                        end;
                    }
                }
            }
            action(Approvals)
            {
                AccessByPermission = TableData "Approval Entry" = R;
                ApplicationArea = Suite;
                Caption = 'Approvals';
                Image = Approvals;
                ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                trigger OnAction()
                var
                    [SecurityFiltering(SecurityFilter::Filtered)]
                    RequisitionLine: Record "Requisition Line";
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    GetCurrentlySelectedLines(RequisitionLine);
                    ApprovalsMgmt.ShowWorksheetApprovalEntries(RequisitionLine);
                end;
            }
        }
        area(processing)
        {
            action("Delete All")
            {
                ApplicationArea = Planning;
                Caption = 'Delete all lines in worksheet';
                Image = Delete;
                Tooltip = 'Delete all lines in the current worksheet, disregarding any filters.';

                trigger OnAction()
                begin
                    Rec.ClearPlanningWorksheet(false);
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";

                separator(Action109)
                {
                }
                action("Calculate &Net Change Plan")
                {
                    ApplicationArea = Planning;
                    Caption = 'Calculate &Net Change Plan';
                    Ellipsis = true;
                    Image = CalculatePlanChange;
                    ToolTip = 'Plan only for items that had the following types of changes to their demand-supply pattern since the last planning run: 1) Change in demand for the item, such as forecast, sales, or component lines. 2) Change in the master data or in the planned supply for the item, such as changes to the BOM or routing, changes to planning parameters, or unplanned inventory differences.';

                    trigger OnAction()
                    var
                        CalcPlan: Report Microsoft.Manufacturing.Planning."Calculate Plan - Plan. Wksh.";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeCalculateNetChangePlan(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        CalcPlan.SetTemplAndWorksheet(Rec."Worksheet Template Name", Rec."Journal Batch Name", false);
                        CalcPlan.RunModal();

                        if not Rec.Find('-') then
                            Rec.SetUpNewLine(Rec);

                        Clear(CalcPlan);
                    end;
                }
                action(CalculateRegenerativePlan)
                {
                    ApplicationArea = Planning;
                    Caption = 'Calculate Regenerative Plan';
                    Ellipsis = true;
                    Image = CalculateRegenerativePlan;
                    ToolTip = 'Plan for all items, regardless of changes since the previous planning run. You calculate a regenerative plan when there are changes to master data or capacity, such as shop calendars, that affect all items and therefore the whole supply plan.';

                    trigger OnAction()
                    var
                        CalcPlan: Report Microsoft.Manufacturing.Planning."Calculate Plan - Plan. Wksh.";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeCalculateRegenerativePlan(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        CalcPlan.SetTemplAndWorksheet(Rec."Worksheet Template Name", Rec."Journal Batch Name", true);
                        CalcPlan.RunModal();

                        if not Rec.Find('-') then
                            Rec.SetUpNewLine(Rec);

                        Clear(CalcPlan);
                    end;
                }
                action("Get &Action Messages")
                {
                    ApplicationArea = Planning;
                    Caption = 'Get &Action Messages';
                    Ellipsis = true;
                    Image = GetActionMessages;
                    ToolTip = 'Obtain an immediate view of the effect of schedule changes, without running a regenerative or net change planning process. This function serves as a short-term planning tool by issuing action messages to alert the user of any modifications made since the last regenerative or net change plan was calculated.';

                    trigger OnAction()
                    begin
                        Rec.GetActionMessages();

                        if not Rec.Find('-') then
                            Rec.SetUpNewLine(Rec);
                    end;
                }
                group("Drop Shipment")
                {
                    Caption = 'Drop Shipment';
                    Image = Delivery;
                    action("Get Sales Orders")
                    {
                        AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
                        ApplicationArea = Planning;
                        Caption = 'Get Sales Orders';
                        Ellipsis = true;
                        Image = "Order";
                        ToolTip = 'Copy sales lines to the planning worksheet. You can use the batch job to create planning worksheet proposal lines from sales lines for drop shipments or special orders.';

                        trigger OnAction()
                        var
                            GetSalesOrder: Report "Get Sales Orders";
                        begin
                            GetSalesOrder.SetReqWkshLine(Rec, 0);
                            GetSalesOrder.RunModal();
                            Clear(GetSalesOrder);
                        end;
                    }
                    action("Sales Order")
                    {
                        AccessByPermission = TableData "Sales Header" = R;
                        ApplicationArea = Planning;
                        Caption = 'Sales Order';
                        Image = Document;
                        Enabled = Rec."Sales Order No." <> '';
                        ToolTip = 'View the sales order that is the source of the line. This applies only to drop shipments and special orders.';

                        trigger OnAction()
                        var
                            SalesHeader: Record "Sales Header";
                            SalesOrder: Page "Sales Order";
                        begin
                            SalesHeader.SetRange("No.", Rec."Sales Order No.");
                            SalesOrder.SetTableView(SalesHeader);
                            SalesOrder.Editable := false;
                            SalesOrder.Run();
                        end;
                    }
                }
                separator(Action32)
                {
                }
                action("Re&fresh Planning Line")
                {
                    ApplicationArea = Planning;
                    Caption = 'Re&fresh Planning Line';
                    Ellipsis = true;
                    Image = RefreshPlanningLine;
                    ToolTip = 'Update the selected planning line with any changes that are made to planning components and routing lines since the planning line was created.';

                    trigger OnAction()
                    var
                        ReqLine: Record "Requisition Line";
                    begin
                        ReqLine.SetRange("Worksheet Template Name", Rec."Worksheet Template Name");
                        ReqLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        ReqLine.SetRange("Line No.", Rec."Line No.");

                        REPORT.RunModal(REPORT::"Refresh Planning Demand", true, false, ReqLine);
                    end;
                }
                separator(Action42)
                {
                }
                action("&Get Error Log")
                {
                    ApplicationArea = Planning;
                    Caption = '&Get Error Log';
                    Image = ErrorLog;
                    RunObject = Page "Planning Error Log";
                    RunPageLink = "Worksheet Template Name" = field("Worksheet Template Name"),
                                  "Journal Batch Name" = field("Journal Batch Name");
                    ToolTip = 'View detailed information for planning lines with a value in the Warning field.';
                }
                separator(Action113)
                {
                }
                action(CarryOutActionMessage)
                {
                    ApplicationArea = Planning;
                    Caption = 'Carry &Out Action Message';
                    Ellipsis = true;
                    Image = CarryOutActionMessage;
                    ToolTip = 'Use a batch job to help you create actual supply orders from the order proposals.';

                    trigger OnAction()
                    begin
                        CarryOutActionMsg();
                        CurrPage.Update(true);
                    end;
                }
                separator(Action19)
                {
                }
                action("&Reserve")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowReservation();
                    end;
                }
                action(OrderTracking)
                {
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        TrackingForm: Page "Order Tracking";
                    begin
                        TrackingForm.SetReqLine(Rec);
                        TrackingForm.RunModal();
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                group(SendApprovalRequest)
                {
                    Caption = 'Send Approval Request';
                    Image = SendApprovalRequest;
                    action(SendApprovalRequestWkshBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Worksheet Batch';
                        Enabled = not OpenApprovalEntriesOnWkshBatchExist and CanRequestFlowApprovalForWkshBatch and EnabledWkshBatchWorkflowsExist;
                        Image = SendApprovalRequest;
                        ToolTip = 'Send all worksheet lines for approval, also those that you may not see because of filters.';

                        trigger OnAction()
                        var
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            ApprovalsMgmt.TrySendWorksheetBatchApprovalRequest(Rec);
                            SetControlAppearanceFromWkshBatch();
                        end;
                    }
                }
                group(CancelApprovalRequest)
                {
                    Caption = 'Cancel Approval Request';
                    Image = Cancel;
                    action(CancelApprovalRequestWkshBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Worksheet Batch';
                        Enabled = CanCancelApprovalForWkshBatch or CanCancelFlowApprovalForWkshBatch;
                        Image = CancelApprovalRequest;
                        ToolTip = 'Cancel sending all worksheet lines for approval, also those that you may not see because of filters.';

                        trigger OnAction()
                        var
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            ApprovalsMgmt.TryCancelWorksheetBatchApprovalRequest(Rec);
                            SetControlAppearanceFromWkshBatch();
                        end;
                    }
                }
                group(Flow)
                {
                    Caption = 'Power Automate';
                    Image = Flow;

                    customaction(CreateApprovalFlowFromTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create approval flow';
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS and IsPowerAutomatePrivacyNoticeApproved;
                        CustomActionType = FlowTemplateGallery;
                        FlowTemplateCategoryName = 'd365bc_approval_requisitionworksheet';
                    }
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRequisitionWkshLineRequest(Rec);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRequisitionWkshLineRequest(Rec);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRequisitionWkshLineRequest(Rec);
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistForCurrUser or ApprovalEntriesExistSentByCurrentUser;

                    trigger OnAction()
                    var
                        RequisitionWkshName: Record "Requisition Wksh. Name";
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if OpenApprovalEntriesOnWkshBatchExist then
                            if RequisitionWkshName.Get(Rec."Worksheet Template Name", Rec."Journal Batch Name") then
                                ApprovalsMgmt.GetApprovalComment(RequisitionWkshName);
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the worksheet to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                        EditinExcelFilters: Codeunit "Edit in Excel Filters";
                        ODataUtility: Codeunit "ODataUtility";
                    begin
                        // The parameter of ODataUtility.ExternalizeName() should be the field name of page, because ODataUnitility generates ODataFieldName based on the field name of page.
                        // If we use the field name from table, it is possible to return a wrong name when the name of page field is different from the name of table field.
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Journal Batch Name")), Enum::"Edit in Excel Filter Type"::Equal, CurrentWkshBatchName, Enum::"Edit in Excel Edm Type"::"Edm.String");
                        // But here the "Worksheet Template Name" is not a part of the page, so we have to get the ODataFieldName from the record.
                        // The reason why the "Worksheet Template Name" is still a part of the web service although not being a field on this page, is that it is a key in the underlying record.
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Worksheet Template Name")), Enum::"Edit in Excel Filter Type"::Equal, Rec."Worksheet Template Name", Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcel.EditPageInExcel(Text.CopyStr(CurrPage.Caption, 1, 240), Page::"Planning Worksheet", EditInExcelFilters, StrSubstNo(ExcelFileNameTxt, CurrentWkshBatchName, Rec."Worksheet Template Name"));
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CarryOutActionMessage_Promoted; CarryOutActionMessage)
                {
                }
                actionref("Re&fresh Planning Line_Promoted"; "Re&fresh Planning Line")
                {
                }
                actionref("&Reserve_Promoted"; "&Reserve")
                {
                }
            }
            group(Category_Category9)
            {
                Caption = 'Drop Shipment', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Get Sales Orders_Promoted"; "Get Sales Orders")
                {
                }
                actionref("Sales Order_Promoted"; "Sales Order")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Prepare', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(CalculateRegenerativePlan_Promoted; CalculateRegenerativePlan)
                {
                }
                actionref("Get &Action Messages_Promoted"; "Get &Action Messages")
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
            }
            group("Category_Request Approval")
            {
                Caption = 'Request Approval';

                group("Category_Send Approval Request")
                {
                    Caption = 'Send Approval Request';

                    actionref(SendApprovalRequestWkshBatch_Promoted; SendApprovalRequestWkshBatch)
                    {
                    }
                }
                group("Category_Cancel Approval Request")
                {
                    Caption = 'Cancel Approval Request';

                    actionref(CancelApprovalRequestWkshBatch_Promoted; CancelApprovalRequestWkshBatch)
                    {
                    }
                }
            }
            group(Category_Category5)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(OrderTracking_Promoted; OrderTracking)
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
                actionref(Components_Promoted; Components)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Category7)
            {
                Caption = 'Item Availability by', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
                actionref(Location_Promoted; Location)
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
                actionref(Lot_Promoted; Lot)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
        if RequisitionWkshName.Get(Rec.GetRangeMax("Worksheet Template Name"), CurrentWkshBatchName) then begin
            SetApprovalStateForWkshBatch(RequisitionWkshName, Rec, OpenApprovalEntriesExistForCurrUser, OpenApprovalEntriesOnWkshBatchExist, CanCancelApprovalForWkshBatch, CanRequestFlowApprovalForWkshBatch, CanCancelFlowApprovalForWkshBatch, ApprovalEntriesExistSentByCurrentUser, EnabledWkshBatchWorkflowsExist);
            ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.Page.SetFilterOnWorkflowRecord(RequisitionWkshName.RecordId());
        end;

        ApprovalMgmt.GetRequisitionWkshBatchApprovalStatus(Rec, RequisitionWkshBatchApprovalStatus, EnabledWkshBatchWorkflowsExist);
    end;

    trigger OnAfterGetRecord()
    var
        Item: Record "Item";
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        StartingDateTimeOnFormat();
        StartingDateOnFormat();
        RefOrderNoOnFormat();
        PlanningWarningLevel1OnFormat();
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnInit()
    begin
        IsPowerAutomatePrivacyNoticeApproved := PrivacyNotice.GetPrivacyNoticeApprovalState(FlowServiceManagement.GetPowerAutomatePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec."Accept Action Message" := false;
        Rec.DeleteMultiLevel();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ApprovalMgmt.CleanRequisitionWkshApprovalStatus(Rec, RequisitionWkshBatchApprovalStatus);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine(Rec);
        Rec.Type := Rec.Type::Item;
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        ServerSetting: Codeunit "Server Setting";
        EnvironmentInfo: Codeunit "Environment Information";
        JnlSelected: Boolean;
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        IsSaaS := EnvironmentInfo.IsSaaS();
        // if called from API (such as edit-in-excel), do not filter 
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;
        OpenedFromBatch := (Rec."Journal Batch Name" <> '') and (Rec."Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentWkshBatchName := Rec."Journal Batch Name";
            ReqJnlManagement.OpenJnl(CurrentWkshBatchName, Rec);
            SetControlAppearanceFromWkshBatch();
            exit;
        end;
        ReqJnlManagement.WkshTemplateSelection(
            PAGE::"Planning Worksheet", false, "Req. Worksheet Template Type"::Planning, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        if NewOpenFromItemAvailabilityByEvent then
            CurrentWkshBatchName := Rec."Journal Batch Name";
        ReqJnlManagement.OpenJnl(CurrentWkshBatchName, Rec);

        SetControlAppearanceFromWkshBatch();
    end;

    var
        PlanningTransparency: Codeunit "Planning Transparency";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        ReqLineAvailabilityMgt: Codeunit "Req. Line Availability Mgt.";
        ApprovalMgmt: Codeunit "Approvals Mgmt.";
        PrivacyNotice: Codeunit "Privacy Notice";
        FlowServiceManagement: Codeunit "Flow Service Management";
        RequisitionWkshBatchApprovalStatus: Text[20];
        CurrentWkshBatchName: Code[10];
        ExcelFileNameTxt: Label 'Planning Worksheet - JournalBatchName %1 - WorksheetTemplateName %2', Comment = '%1 = Journal Batch Name; %2 = Worksheet Template Name';
        OpenedFromBatch: Boolean;
        VariantCodeMandatory: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;
        NewOpenFromItemAvailabilityByEvent: Boolean;
        ApprovalEntriesExistSentByCurrentUser: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesOnWkshBatchExist: Boolean;
        EnabledWkshBatchWorkflowsExist: Boolean;
        ShowWorkflowStatusOnBatch: Boolean;
        CanCancelApprovalForWkshBatch: Boolean;
        CanRequestFlowApprovalForWkshBatch: Boolean;
        CanCancelFlowApprovalForWkshBatch: Boolean;
        IsPowerAutomatePrivacyNoticeApproved: Boolean;
        IsSaaS: Boolean;
        Warning: Option " ",Emergency,Exception,Attention;

    protected var
        PlanningWkshManagement: Codeunit PlanningWkshManagement;
        ItemDescription: Text[100];
        RoutingDescription: Text[100];
        ShortcutDimCode: array[8] of Code[20];

    local procedure PlanningWarningLevel()
    var
        Transparency: Codeunit "Planning Transparency";
    begin
        Warning := Transparency.ReqLineWarningLevel(Rec);
    end;

    local procedure CurrentWkshBatchNameOnAfterVal()
    begin
        CurrPage.SaveRecord();
        ReqJnlManagement.SetName(CurrentWkshBatchName, Rec);
        SetControlAppearanceFromWkshBatch();
        CurrPage.Update(false);
    end;

    local procedure StartingDateTimeOnFormat()
    begin
        if (Rec."Starting Date" < WorkDate()) and
           (Rec."Action Message" in [Rec."Action Message"::New, Rec."Action Message"::Reschedule, Rec."Action Message"::"Resched. & Chg. Qty."])
        then
            ;
    end;

    local procedure StartingDateOnFormat()
    begin
        if Rec."Starting Date" < WorkDate() then;
    end;

    local procedure RefOrderNoOnFormat()
    var
        PurchHeader: Record "Purchase Header";
        TransfHeader: Record "Transfer Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRefOrderNoOnFormat(Rec, IsHandled);
        if IsHandled then
            exit;

        case Rec."Ref. Order Type" of
            Rec."Ref. Order Type"::Purchase:
                if PurchHeader.Get(PurchHeader."Document Type"::Order, Rec."Ref. Order No.") and
                   (PurchHeader.Status = PurchHeader.Status::Released)
                then
                    ;
            Rec."Ref. Order Type"::"Prod. Order":
                ;
            Rec."Ref. Order Type"::Transfer:
                if TransfHeader.Get(Rec."Ref. Order No.") and
                   (TransfHeader.Status = TransfHeader.Status::Released)
                then
                    ;
        end;
    end;

    local procedure PlanningWarningLevel1OnFormat()
    begin
        PlanningWarningLevel();
    end;

    procedure OpenPlanningComponent(var PlanningComponent: Record "Planning Component")
    begin
        PlanningComponent.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", PlanningComponent."Worksheet Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", PlanningComponent."Worksheet Line No.");
        PAGE.RunModal(PAGE::"Planning Components", PlanningComponent);
    end;

    local procedure CarryOutActionMsg()
    var
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        Ishandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCarryOutActionMsg(Rec, IsHandled);
        if IsHandled then
            exit;

        CarryOutActionMsgPlan.SetReqWkshLine(Rec);
        CarryOutActionMsgPlan.RunModal();
    end;

    procedure CallFromItemAvailabilityByEvent(OpenFromItemAvailabilityByEvent: Boolean)
    begin
        NewOpenFromItemAvailabilityByEvent := OpenFromItemAvailabilityByEvent;
    end;

    internal procedure SetApprovalStateForWkshBatch(RequisitionWkshName: Record "Requisition Wksh. Name"; RequisitionLine: Record "Requisition Line"; var OpenApprovalEntriesExistForCurrentUser: Boolean; var OpenApprovalEntriesOnWorksheetBatchExist: Boolean; var CanCancelApprovalForWorksheetBatch: Boolean; var LocalCanRequestFlowApprovalForWkshBatch: Boolean; var LocalCanCancelFlowApprovalForWkshBatch: Boolean; var LocalApprovalEntriesExistSentByCurrentUser: Boolean; var EnabledWorksheetBatchWorkflowsExist: Boolean)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        OpenApprovalEntriesExistForCurrentUser := OpenApprovalEntriesExistForCurrentUser or ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RequisitionWkshName.RecordId());
        OpenApprovalEntriesOnWorksheetBatchExist := ApprovalsMgmt.HasOpenApprovalEntries(RequisitionWkshName.RecordId());
        CanCancelApprovalForWorksheetBatch := ApprovalsMgmt.CanCancelApprovalForRecord(RequisitionWkshName.RecordId());
        WorkflowWebhookManagement.GetCanRequestAndCanCancel(RequisitionWkshName.RecordId(), LocalCanRequestFlowApprovalForWkshBatch, LocalCanCancelFlowApprovalForWkshBatch);
        LocalApprovalEntriesExistSentByCurrentUser := ApprovalsMgmt.HasApprovalEntriesSentByCurrentUser(RequisitionWkshName.RecordId());
        EnabledWorksheetBatchWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(Database::"Requisition Wksh. Name", WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
    end;

    local procedure GetCurrentlySelectedLines(var RequisitionLine: Record "Requisition Line"): Boolean
    begin
        CurrPage.SetSelectionFilter(RequisitionLine);

        exit(RequisitionLine.FindSet());
    end;

    local procedure SetControlAppearanceFromWkshBatch()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        if not RequisitionWkshName.Get(Rec.GetRangeMax("Worksheet Template Name"), CurrentWkshBatchName) then
            exit;

        ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.Page.SetFilterOnWorkflowRecord(RequisitionWkshName.RecordId());
        SetApprovalStateForWkshBatch(RequisitionWkshName, Rec, OpenApprovalEntriesExistForCurrUser, OpenApprovalEntriesOnWkshBatchExist, CanCancelApprovalForWkshBatch, CanRequestFlowApprovalForWkshBatch, CanCancelFlowApprovalForWkshBatch, ApprovalEntriesExistSentByCurrentUser, EnabledWkshBatchWorkflowsExist);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupCurrentJnlBatchName(var RequisitionLine: Record "Requisition Line"; var CurrJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutActionMsg(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefOrderNoOnFormat(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalculateRegenerativePlan(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalculateNetChangePlan(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;
}

