// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Reports;
using Microsoft.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Privacy;

page 392 "Phys. Inventory Journal"
{
    AdditionalSearchTerms = 'physical count journal,inventory cycle journal';
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Physical Inventory Journals';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    AboutTitle = 'About Physical Inventory Journals';
    AboutText = 'Record and adjust physical inventory counts, reconcile calculated and actual stock quantities, and post updates to ensure inventory records accurately reflect on-hand items, including support for cycle counting and periodic inventory checks.';
    SaveValues = true;
    SourceTable = "Item Journal Line";
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        ItemJnlMgt.LookupName(CurrentJnlBatchName, Rec);
                        SetControlAppearanceFromBatch();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        ItemJnlMgt.CheckName(CurrentJnlBatchName, Rec);
                        CurrentJnlBatchNameOnAfterValidate();
                    end;
                }
                field(ItemJnlBatchApprovalStatus; ItemJnlBatchApprovalStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approval Status';
                    Editable = false;
                    Visible = EnabledItemJnlBatchWorkflowsExist;
                    ToolTip = 'Specifies the approval status for physical inventory journal.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Entry Type"; EntryType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Type';
                    ToolTip = 'Specifies the type of transaction that will be posted from the item journal line.';

                    trigger OnValidate()
                    begin
                        CheckEntryType();

                        Rec.Validate("Entry Type", EntryType);
                    end;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        ItemNoOnAfterValidate();
                    end;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    QuickEntry = false;
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemReferenceManagement: Codeunit "Item Reference Management";
                    begin
                        ItemReferenceManagement.ItemJournalReferenceNoLookup(Rec);
                        ItemNoOnAfterValidate();
                        OnReferenceNoOnAfterLookup(Rec);
                    end;

                    trigger OnValidate()
                    begin
                        ItemNoOnAfterValidate();
                    end;
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = true;

                    trigger OnValidate()
                    var
                        WMSManagement: Codeunit "WMS Management";
                    begin
                        WMSManagement.CheckItemJnlLineLocation(Rec, xRec);
                    end;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Suite;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Qty. (Calculated)"; Rec."Qty. (Calculated)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity on hand of the item.';
                }
                field("Qty. (Phys. Inventory)"; Rec."Qty. (Phys. Inventory)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity on hand of the item as determined from a physical count.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Unit Amount"; Rec."Unit Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Applies-to Entry"; Rec."Applies-to Entry")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 3);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 4);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 5);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 6);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 7);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 8);
                    end;
                }
            }
            group(Control22)
            {
                ShowCaption = false;
                fixed(Control1900669001)
                {
                    ShowCaption = false;
                    group("Item Description")
                    {
                        Caption = 'Item Description';
                        field(ItemDescription; ItemDescription)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies a description of the item.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(JournalErrorsFactBox; "Item Journal Errors FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = BackgroundErrorCheck;
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Journal Batch Name" = field("Journal Batch Name"),
                              "Line No." = field("Line No.");
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
                        Rec.OpenItemTrackingLines(false);
                    end;
                }
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = field("Location Code"),
                                  "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code");
                    RunPageView = sorting("Location Code", "Item No.", "Variant Code");
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
                }
            }
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Item No." = field("Item No.");
                    RunPageView = sorting("Item No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Phys. In&ventory Ledger Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Phys. In&ventory Ledger Entries';
                    Image = PhysicalInventoryLedger;
                    RunObject = Page "Phys. Inventory Ledger Entries";
                    RunPageLink = "Item No." = field("Item No.");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'Show the ledger entries for the current journal line.';
                }
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItemJnlLine(Rec, "Item Availability Type"::"Event")
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItemJnlLine(Rec, "Item Availability Type"::Period)
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
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItemJnlLine(Rec, "Item Availability Type"::Variant)
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
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItemJnlLine(Rec, "Item Availability Type"::Location)
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("Item No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItemJnlLine(Rec, "Item Availability Type"::BOM)
                        end;
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
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ShowJournalApprovalEntries(Rec);
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
                action(CalculateInventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate &Inventory';
                    Ellipsis = true;
                    Image = CalculateInventory;
                    ToolTip = 'Start the process of counting inventory by filling the journal with known quantities.';

                    trigger OnAction()
                    begin
                        CalcQtyOnHand.SetItemJnlLine(Rec);
                        CalcQtyOnHand.RunModal();
                        Clear(CalcQtyOnHand);
                    end;
                }
                action(CalculateCountingPeriod)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Calculate Counting Period';
                    Ellipsis = true;
                    Image = CalculateCalendar;
                    ToolTip = 'Show all items that a counting period has been assigned to, according to the counting period, the last counting period update, and the current work date.';

                    trigger OnAction()
                    var
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        PhysInvtCountMgt.InitFromItemJnl(Rec);
                        PhysInvtCountMgt.Run();
                        Clear(PhysInvtCountMgt);
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
                    action(SendApprovalRequestJournalBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
                        Enabled = not OpenApprovalEntriesOnJnlBatchExist and CanRequestFlowApprovalForBatch and EnabledItemJnlBatchWorkflowsExist;
                        Image = SendApprovalRequest;
                        ToolTip = 'Send all journal lines for approval, also those that you may not see because of filters.';

                        trigger OnAction()
                        var
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            ApprovalsMgmt.TrySendJournalBatchApprovalRequest(Rec);
                            SetControlAppearanceFromBatch();
                        end;
                    }
                }
                group(CancelApprovalRequest)
                {
                    Caption = 'Cancel Approval Request';
                    Image = Cancel;
                    action(CancelApprovalRequestJournalBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
                        Enabled = CanCancelApprovalForJnlBatch or CanCancelFlowApprovalForBatch;
                        Image = CancelApprovalRequest;
                        ToolTip = 'Cancel sending all journal lines for approval, also those that you may not see because of filters.';

                        trigger OnAction()
                        var
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            ApprovalsMgmt.TryCancelJournalBatchApprovalRequest(Rec);
                            SetControlAppearanceFromBatch();
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
                        FlowTemplateCategoryName = 'd365bc_approval_itemJournal';
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
                        ApprovalsMgmt.ApproveItemJournalRequest(Rec);
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
                        ApprovalsMgmt.RejectItemJournalRequest(Rec);
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
                        ApprovalsMgmt.DelegateItemJournalRequest(Rec);
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
                        ItemJournalBatch: Record "Item Journal Batch";
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if OpenApprovalEntriesOnJnlBatchExist then
                            if ItemJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                                ApprovalsMgmt.GetApprovalComment(ItemJournalBatch);
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
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                    begin
                        ODataUtility.EditJournalWorksheetInExcel(Text.CopyStr(CurrPage.Caption, 1, 240), CurrPage.ObjectId(false), Rec."Journal Batch Name", Rec."Journal Template Name");
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    ItemJournalBatch: Record "Item Journal Batch";
                begin
                    ItemJournalBatch.SetRange("Journal Template Name", Rec."Journal Template Name");
                    ItemJournalBatch.SetRange(Name, Rec."Journal Batch Name");
                    REPORT.RunModal(REPORT::"Phys. Inventory List", true, false, ItemJournalBatch);
                end;
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintItemJnlLine(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview();
                        CurrPage.Update(false);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post+Print", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Errors)
            {
                Caption = 'Issues';
                Image = ErrorLog;
                Visible = BackgroundErrorCheck;
                action(ShowLinesWithErrors)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Lines with Issues';
                    Image = Error;
                    Visible = BackgroundErrorCheck;
                    Enabled = not ShowAllLinesEnabled;
                    ToolTip = 'View a list of journal lines that have issues before you post the journal.';

                    trigger OnAction()
                    begin
                        Rec.SwitchLinesWithErrorsFilter(ShowAllLinesEnabled);
                    end;
                }
                action(ShowAllLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All Lines';
                    Image = ExpandAll;
                    Visible = BackgroundErrorCheck;
                    Enabled = ShowAllLinesEnabled;
                    ToolTip = 'View all journal lines, including lines with and without issues.';

                    trigger OnAction()
                    begin
                        Rec.SwitchLinesWithErrorsFilter(ShowAllLinesEnabled);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category4)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref("P&ost_Promoted"; "P&ost")
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                }
                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Category10)
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

                    actionref(SendApprovalRequestJournalBatch_Promoted; SendApprovalRequestJournalBatch)
                    {
                    }
                }
                group("Category_Cancel Approval Request")
                {
                    Caption = 'Cancel Approval Request';

                    actionref(CancelApprovalRequestJournalBatch_Promoted; CancelApprovalRequestJournalBatch)
                    {
                    }
                }
            }
            group(Category_Category5)
            {
                Caption = 'Prepare', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(CalculateInventory_Promoted; CalculateInventory)
                {
                }
                actionref(CalculateCountingPeriod_Promoted; CalculateCountingPeriod)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Card_Promoted; Card)
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref("Phys. In&ventory Ledger Entries_Promoted"; "Phys. In&ventory Ledger Entries")
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Item Availability by', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(Location_Promoted; Location)
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
                actionref(Lot_Promoted; Lot)
                {
                }
            }
            group(Category_Category9)
            {
                Caption = 'Page', Comment = 'Generated from the PromotedActionCategories property index 8.';

                actionref(ShowLinesWithErrors_Promoted; ShowLinesWithErrors)
                {
                }
                actionref(ShowAllLines_Promoted; ShowAllLines)
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
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJnlMgt.GetItem(Rec."Item No.", ItemDescription);
        EntryType := Rec."Entry Type";
        if ItemJournalBatch.Get(Rec.GetRangeMax("Journal Template Name"), CurrentJnlBatchName) then begin
            ItemJournalBatch.SetApprovalStateForBatch(ItemJournalBatch, Rec, OpenApprovalEntriesExistForCurrUser, OpenApprovalEntriesOnJnlBatchExist, CanCancelApprovalForJnlBatch, CanRequestFlowApprovalForBatch, CanCancelFlowApprovalForBatch, ApprovalEntriesExistSentByCurrentUser, EnabledItemJnlBatchWorkflowsExist);
            ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.Page.SetFilterOnWorkflowRecord(ItemJournalBatch.RecordId());
        end;

        ApprovalMgmt.GetItemJnlBatchApprovalStatus(Rec, ItemJnlBatchApprovalStatus, EnabledItemJnlBatchWorkflowsExist);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        EntryType := Rec."Entry Type";
    end;

    trigger OnInit()
    begin
        IsPowerAutomatePrivacyNoticeApproved := PrivacyNotice.GetPrivacyNoticeApprovalState(FlowServiceManagement.GetPowerAutomatePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteRecord(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Commit();
        if not ItemJnlLineReserve.DeleteLineConfirm(Rec) then
            exit(false);
        ItemJnlLineReserve.DeleteLine(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CheckEntryType();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ApprovalMgmt.CleanItemJournalApprovalStatus(Rec, ItemJnlBatchApprovalStatus);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine(xRec);
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
        // if called from API (such as edit-in-excel), do not filter 
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;

        IsSaaS := EnvironmentInfo.IsSaaS();
        SetDimensionsVisibility();
        if Rec.IsOpenedFromBatch() then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            ItemJnlMgt.OpenJnl(CurrentJnlBatchName, Rec);
            SetControlAppearanceFromBatch();
            exit;
        end;
        ItemJnlMgt.TemplateSelection(PAGE::"Phys. Inventory Journal", 2, false, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        ItemJnlMgt.OpenJnl(CurrentJnlBatchName, Rec);
        SetControlAppearanceFromBatch();
    end;

    var
        CalcQtyOnHand: Report "Calculate Inventory";
        ItemJnlMgt: Codeunit ItemJnlManagement;
        ReportPrint: Codeunit "Test Report-Print";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ItemJournalErrorsMgt: Codeunit "Item Journal Errors Mgt.";
        ApprovalMgmt: Codeunit "Approvals Mgmt.";
        PrivacyNotice: Codeunit "Privacy Notice";
        FlowServiceManagement: Codeunit "Flow Service Management";
        ItemDescription: Text[100];
        ItemJnlBatchApprovalStatus: Text[20];
        BackgroundErrorCheck: Boolean;
        ShowAllLinesEnabled: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;
        ApprovalEntriesExistSentByCurrentUser: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesOnJnlBatchExist: Boolean;
        EnabledItemJnlBatchWorkflowsExist: Boolean;
        ShowWorkflowStatusOnBatch: Boolean;
        CanCancelApprovalForJnlBatch: Boolean;
        CanRequestFlowApprovalForBatch: Boolean;
        CanCancelFlowApprovalForBatch: Boolean;
        IsPowerAutomatePrivacyNoticeApproved: Boolean;
        IsSaaS: Boolean;
        EntryTypeErr: Label 'You cannot use entry type %1 in this journal.', Comment = '%1 - Entry Type';

    protected var
        CurrentJnlBatchName: Code[10];
        EntryType: Enum "Item Journal Entry Type";
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    local procedure CurrentJnlBatchNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        ItemJnlMgt.SetName(CurrentJnlBatchName, Rec);
        SetControlAppearanceFromBatch();
        CurrPage.Update(false);
    end;

    procedure ItemNoOnAfterValidate()
    begin
        ItemJnlMgt.GetItem(Rec."Item No.", ItemDescription);
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    local procedure CheckEntryType()
    begin
        if Rec."Entry Type".AsInteger() > Rec."Entry Type"::"Negative Adjmt.".AsInteger() then
            Error(EntryTypeErr, Rec."Entry Type");
    end;

    local procedure SetControlAppearanceFromBatch()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
    begin
        if not ItemJournalBatch.Get(Rec.GetRangeMax("Journal Template Name"), CurrentJnlBatchName) then
            exit;

        BackgroundErrorCheck := BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled();
        ShowAllLinesEnabled := true;

        ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.Page.SetFilterOnWorkflowRecord(ItemJournalBatch.RecordId());
        ItemJournalBatch.SetApprovalStateForBatch(ItemJournalBatch, Rec, OpenApprovalEntriesExistForCurrUser, OpenApprovalEntriesOnJnlBatchExist, CanCancelApprovalForJnlBatch, CanRequestFlowApprovalForBatch, CanCancelFlowApprovalForBatch, ApprovalEntriesExistSentByCurrentUser, EnabledItemJnlBatchWorkflowsExist);

        Rec.SwitchLinesWithErrorsFilter(ShowAllLinesEnabled);
        ItemJournalErrorsMgt.SetFullBatchCheck(true);

        OnAfterSetControlAppearanceFromBatch(ItemJournalBatch);
    end;

    local procedure ShowPreview()
    var
        ItemJnlPost: Codeunit "Item Jnl.-Post";
    begin
        ItemJnlPost.Preview(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ItemJournalLine: Record "Item Journal Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReferenceNoOnAfterLookup(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetControlAppearanceFromBatch(ItemJournalBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRecord(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

