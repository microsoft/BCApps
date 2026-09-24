// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Automation;
using System.Security.User;

page 296 "Recurring Req. Worksheet"
{
    ApplicationArea = Planning;
    AutoSplitKey = true;
    Caption = 'Recurring Requisition Worksheets';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Requisition Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
             group(Control120)
            {
                ShowCaption = false;
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Planning;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the record.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    ReqJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    SetControlAppearanceFromWkshBatch();
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    ReqJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            field(RequisitionWkshBatchApprovalStatus; RequisitionWkshBatchApprovalStatus)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Approval Status';
                Editable = false;
                Visible = EnabledWkshBatchWorkflowsExist;
                ToolTip = 'Specifies the approval status for requisition worksheet batch.';
            }
        }

            repeater(Control1)
            {
                ShowCaption = false;
                field("Recurring Method"; Rec."Recurring Method")
                {
                    ApplicationArea = Planning;
                }
                field("Recurring Frequency"; Rec."Recurring Frequency")
                {
                    ApplicationArea = Planning;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Planning;

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Planning;

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Action Message"; Rec."Action Message")
                {
                    ApplicationArea = Planning;
                }
                field("Accept Action Message"; Rec."Accept Action Message")
                {
                    ApplicationArea = Planning;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of units of the item or resource specified on the line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Planning;

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Planning;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
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
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Planning;
                    AssistEdit = true;
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", WorkDate());
                        if ChangeExchangeRate.RunModal() = ACTION::OK then
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());

                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Planning;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Planning;
                }
                field("Requester ID"; Rec."Requester ID")
                {
                    ApplicationArea = Planning;
                    LookupPageID = "User Lookup";
                    Visible = false;
                }
                field(Confirmed; Rec.Confirmed)
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = Planning;
                }
            }
            group(Control28)
            {
                ShowCaption = false;
                fixed(Control1902205001)
                {
                    ShowCaption = false;
                    group(Control1903866901)
                    {
                        Caption = 'Description';
                        field(Description2; Description2)
                        {
                            ApplicationArea = Planning;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies an additional part of the worksheet description.';
                        }
                    }
                    group("Buy-from Vendor Name")
                    {
                        Caption = 'Buy-from Vendor Name';
                        field(BuyFromVendorName; BuyFromVendorName)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Buy-from Vendor Name';
                            Editable = false;
                            ToolTip = 'Specifies the vendor according to the values in the Document No. and Document Type fields.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(WorkflowStatusBatch; "Workflow Status FactBox")
            {
                ApplicationArea = Suite;
                Caption = 'Batch Workflows';
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatusOnBatch;
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
                action(Card)
                {
                    ApplicationArea = Planning;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Codeunit "Req. Wksh.-Show Card";
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the item or resource.';
                }
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
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
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';

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
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
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
                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ShowWorksheetApprovalEntries(Rec);
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
                action("Calculate Plan")
                {
                    ApplicationArea = Planning;
                    Caption = 'Calculate Plan';
                    Ellipsis = true;
                    Image = CalculatePlan;
                    ToolTip = 'Use a batch job to help you calculate a supply plan for items and stockkeeping units that have the Replenishment System field set to Purchase or Transfer.';

                    trigger OnAction()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeCalculateLines(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        ReorderItems.SetTemplAndWorksheet(Rec."Worksheet Template Name", Rec."Journal Batch Name");
                        ReorderItems.RunModal();
                        Clear(ReorderItems);
                    end;
                }
                action("Carry &Out Action Message")
                {
                    ApplicationArea = Planning;
                    Caption = 'Carry &Out Action Message';
                    Ellipsis = true;
                    Image = CarryOutActionMessage;
                    ToolTip = 'Use a batch job to help you create actual supply orders from the order proposals.';

                    trigger OnAction()
                    begin
                        MakePurchaseOrder();
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action("&Reserve")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Ellipsis = true;
                    Image = Reserve;
                    ToolTip = 'Reserve one or more units of the item on the project planning line, either from inventory or from incoming supply.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowReservation();
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
                        ApprovalsMgmt.ApproveRequisitionWkshRequest(Rec);
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
                        ApprovalsMgmt.RejectRequisitionWkshRequest(Rec);
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
                        ApprovalsMgmt.DelegateRequisitionWkshRequest(Rec);
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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Calculate Plan_Promoted"; "Calculate Plan")
                {
                }
                actionref("Carry &Out Action Message_Promoted"; "Carry &Out Action Message")
                {
                }
            }
            group(Category_Line)
            {
                Caption = 'Line';

                actionref(Card_Promoted; Card)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref("Reservation Entries_Promoted"; "Reservation Entries")
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
            group("Category_Item Availability by")
            {
                Caption = 'Item Availability by';

                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
                actionref(Location_Promoted; Location)
                {
                }
                actionref(Lot_Promoted; Lot)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);

        if Rec.GetFilter("Worksheet Template Name") <> '' then
            if RequisitionWkshName.Get(Rec.GetRangeMax("Worksheet Template Name"), CurrentJnlBatchName) then begin
                RequisitionWkshName.SetApprovalStateForWkshBatch(RequisitionWkshName, Rec, OpenApprovalEntriesExistForCurrUser, OpenApprovalEntriesOnWkshBatchExist, CanCancelApprovalForWkshBatch, CanRequestFlowApprovalForWkshBatch, CanCancelFlowApprovalForWkshBatch, ApprovalEntriesExistSentByCurrentUser, EnabledWkshBatchWorkflowsExist);
                ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.Page.SetFilterOnWorkflowRecord(RequisitionWkshName.RecordId());
            end;

        ApprovalMgmt.GetRequisitionWkshBatchApprovalStatus(Rec, RequisitionWkshBatchApprovalStatus, EnabledWkshBatchWorkflowsExist);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ReqJnlManagement.SetUpNewLine(Rec, xRec);
        Clear(ShortcutDimCode);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ApprovalMgmt.CleanRequisitionWkshApprovalStatus(Rec, RequisitionWkshBatchApprovalStatus);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        OpenedFromBatch := (Rec."Journal Batch Name" <> '') and (Rec."Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            ReqJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            SetControlAppearanceFromWkshBatch();
            exit;
        end;
        ReqJnlManagement.WkshTemplateSelection(
            PAGE::"Recurring Req. Worksheet", true, Enum::"Req. Worksheet Template Type"::"Req.", Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        ReqJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
        SetControlAppearanceFromWkshBatch();
    end;

    var
        ReorderItems: Report "Calculate Plan - Req. Wksh.";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        ReqLineAvailabilityMgt: Codeunit "Req. Line Availability Mgt.";
        ApprovalMgmt: Codeunit "Approvals Mgmt.";
        ChangeExchangeRate: Page "Change Exchange Rate";
        RequisitionWkshBatchApprovalStatus: Text[20];
        ApprovalEntriesExistSentByCurrentUser: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesOnWkshBatchExist: Boolean;
        EnabledWkshBatchWorkflowsExist: Boolean;
        ShowWorkflowStatusOnBatch: Boolean;
        CanCancelApprovalForWkshBatch: Boolean;
        CanRequestFlowApprovalForWkshBatch: Boolean;
        CanCancelFlowApprovalForWkshBatch: Boolean;

    protected var
        ShortcutDimCode: array[8] of Code[20];
        Description2: Text[100];
        BuyFromVendorName: Text[100];
        CurrentJnlBatchName: Code[10];
        OpenedFromBatch: Boolean;

    local procedure MakePurchaseOrder()
    var
        MakePurchOrder: Report "Carry Out Action Msg. - Req.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakePurchaseOrder(Rec, IsHandled);
        if IsHandled then
            exit;

        MakePurchOrder.SetReqWkshLine(Rec);
        MakePurchOrder.RunModal();
        MakePurchOrder.GetReqWkshLine(Rec);
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        ReqJnlManagement.SetName(CurrentJnlBatchName, Rec);
        SetControlAppearanceFromWkshBatch();
        CurrPage.Update(false);
    end;

    local procedure SetControlAppearanceFromWkshBatch()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        if not RequisitionWkshName.Get(Rec.GetRangeMax("Worksheet Template Name"), CurrentJnlBatchName) then
            exit;

        ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.Page.SetFilterOnWorkflowRecord(RequisitionWkshName.RecordId());
        RequisitionWkshName.SetApprovalStateForWkshBatch(RequisitionWkshName, Rec, OpenApprovalEntriesExistForCurrUser, OpenApprovalEntriesOnWkshBatchExist, CanCancelApprovalForWkshBatch, CanRequestFlowApprovalForWkshBatch, CanCancelFlowApprovalForWkshBatch, ApprovalEntriesExistSentByCurrentUser, EnabledWkshBatchWorkflowsExist);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakePurchaseOrder(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateLines(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;
}

