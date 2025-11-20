// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Costing.ActionMessage;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using System.Environment;
using System.Text;

page 5801 "Cost Adjustment Overview"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = ReportsAndAnalysis;
    SourceTable = Item;
    Caption = 'Inventory Cost Adjustment';
    Editable = false;
    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = r,
                  tabledata "Inventory Adjmt. Entry (Order)" = r;

    layout
    {
        area(Content)
        {
            group(Summary)
            {
                Caption = 'Summary';

                field("Non-Adjusted Items"; NonAdjustedItems)
                {
                    Caption = 'Non-adjusted items';
                    ToolTip = 'Specifies the number of items for which the cost has not been adjusted.';
                    Editable = false;
                }
                field("Last Run Status"; LastCostAdjustmentRunStatus)
                {
                    Caption = 'Last run status';
                    ToolTip = 'Specifies the status of the last cost adjustment run.';
                    StyleExpr = StatusRunStyleExpr;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        ViewLog(false);
                    end;
                }
                field("Last Successful Run Date/Time"; LastSuccessfulRunDateTime)
                {
                    Caption = 'Last successful run date/time';
                    ToolTip = 'Specifies the date and time of the last cost adjustment run.';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        ViewLog(true);
                    end;
                }
                field("Item Batches"; ItemBatches)
                {
                    Caption = 'Item batches';
                    ToolTip = 'Specifies the total number of item batches that have been created for the cost adjustment.';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Page.RunModal(Page::"Cost Adjustment Runners");
                    end;
                }
            }
            repeater(Item)
            {
                ShowCaption = false;

                field("No."; Rec."No.")
                {
                    Caption = 'No.';
                    TableRelation = Item;
                    ToolTip = 'Specifies the item number.';
                    Editable = false;
                }
                field("Description"; Rec."Description")
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the item.';
                    Editable = false;
                }
                field("Description 2"; Rec."Description 2")
                {
                    Caption = 'Description 2';
                    ToolTip = 'Specifies information in addition to the description.';
                    Editable = false;
                    Visible = false;
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of supply order created by the planning system when the item needs to be replenished.';
                }
                field("Low-Level Code"; Rec."Low-Level Code")
                {
                    Caption = 'Low-Level Code';
                    ToolTip = 'Specifies the item''s level in a bill of material if the item is a component in a production BOM or an assembly BOM.';
                    Editable = false;
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost';
                    ToolTip = 'Specifies the cost of one unit of the item.';

                    trigger OnDrillDown()
                    var
                        ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                    begin
                        ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Rec)
                    end;
                }
                field("Standard Cost"; Rec."Standard Cost")
                {
                    Caption = 'Standard Cost';
                    ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later.';
                }
                field("Last Direct Cost"; Rec."Last Direct Cost")
                {
                    Caption = 'Last Direct Cost';
                    ToolTip = 'Specifies the most recent direct unit cost of the item.';
                }
                field("Costing Method"; Rec."Costing Method")
                {
                    Caption = 'Costing Method';
                    ToolTip = 'Specifies the method that is used to calculate the unit cost of the item.';
                }
                field("Cost is Adjusted"; Rec."Cost is Adjusted")
                {
                    Caption = 'Cost is Adjusted';
                    ToolTip = 'Specifies whether the cost of the item has been adjusted.';
                }
                field("Excluded from Cost Adjustment"; Rec."Excluded from Cost Adjustment")
                {
                    Caption = 'Excluded from Cost Adjustment';
                    ToolTip = 'Specifies whether the item is excluded from the cost adjustment process.';
                }
                field("Cost is Posted to G/L"; Rec."Cost is Posted to G/L")
                {
                    Caption = 'Cost is Posted to G/L';
                    ToolTip = 'Specifies whether the cost of the item has been posted to the general ledger.';
                }
                field("Last Cost Adjustment DateTime"; LastCostAdjustmentItemDateTime)
                {
                    Caption = 'Last Cost Adjustment Date/Time';
                    ToolTip = 'Specifies the date and time of the last cost adjustment run.';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        ViewDetailedLog();
                    end;
                }
                field("Last Cost Adjustment Status"; LastCostAdjustmentItemStatus)
                {
                    Caption = 'Last Cost Adjustment Status';
                    ToolTip = 'Specifies the status of the last cost adjustment run.';
                    StyleExpr = StatusItemStyleExpr;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        ViewDetailedLog();
                    end;
                }
                field("Average Cost Calc. Type"; AverageCostCalcType)
                {
                    Caption = 'Average Cost Calc. Type';
                    ToolTip = 'Specifies how costs are calculated for items using the Average costing method. Item: One average cost per item in the company is calculated. Item & Location & Variant: An average cost per item for each location and for each variant of the item in the company is calculated. This means that the average cost of this item depends on where it is stored and which variant, such as color, of the item you have selected.';
                    Visible = false;
                    Editable = false;
                }
                field("Average Cost Calc. Period"; AverageCostPeriod)
                {
                    Caption = 'Average Cost Calc. Period';
                    ToolTip = 'Specifies the period of time used to calculate the weighted average cost of items that apply the average costing method. All inventory decreases that were posted within an average cost period will receive the average cost calculated for that period. If you change the average cost period, only open fiscal years will be affected.';
                    Visible = false;
                    Editable = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(Statistics; "Cost Adj. Statistics Factbox")
            {
                SubPageLink = "No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Filters)
            {
                Caption = 'Show/hide';
                Image = FilterLines;

                action("Show Non-Adjusted")
                {
                    Caption = 'Show non-adjusted';
                    ToolTip = 'Show only items for which the cost has not been adjusted.';
                    Image = Line;

                    trigger OnAction();
                    begin
                        Rec.Reset();
                        Rec.SetRange("Cost is Adjusted", false);
                        CurrPage.Update(false);
                    end;
                }
                action("Show Included")
                {
                    Caption = 'Show included';
                    ToolTip = 'Show only items that are included in the cost adjustment process.';
                    Image = CompleteLine;

                    trigger OnAction();
                    begin
                        Rec.Reset();
                        Rec.SetRange("Excluded from Cost Adjustment", false);
                        CurrPage.Update(false);
                    end;
                }
                action("Show Excluded")
                {
                    Caption = 'Show excluded';
                    ToolTip = 'Show only items that are excluded from the cost adjustment process.';
                    Image = CancelLine;

                    trigger OnAction();
                    begin
                        Rec.Reset();
                        Rec.SetRange("Excluded from Cost Adjustment", true);
                        CurrPage.Update(false);
                    end;
                }
                action("Show All")
                {
                    Caption = 'Show all';
                    ToolTip = 'Show all items regardless of whether the cost has been adjusted.';
                    Image = AllLines;

                    trigger OnAction();
                    begin
                        Rec.Reset();
                        CurrPage.Update(false);
                    end;
                }
            }
            group("Adjust Cost")
            {
                Caption = 'Adjust';

                action("Run")
                {
                    Caption = 'Run cost adjustment';
                    ToolTip = 'Run the cost adjustment for the selected items.';
                    Image = Start;

                    trigger OnAction()
                    var
                        Item: Record Item;
                        Choice: Integer;
                    begin
                        Choice := Dialog.StrMenu(StrMenuOptionsTxt, 0, RunInstructionTxt);
                        if Choice = 0 then
                            exit;

                        if Choice = 1 then
                            CurrPage.SetSelectionFilter(Item);
                        RunAdjustCostItemEntries(Item);
                    end;
                }
                action("Add Batch & Run")
                {
                    Caption = 'Add batch and Run';
                    ToolTip = 'Add the selected items to a new cost adjustment batch and run the cost adjustment.';
                    Image = GoTo;

                    trigger OnAction()
                    var
                        Item: Record Item;
                        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
                        Choice: Integer;
                    begin
                        Choice := Dialog.StrMenu(StrMenuOptionsTxt, 0, RunInstructionTxt);
                        if Choice = 0 then
                            exit;

                        if Choice = 1 then
                            CurrPage.SetSelectionFilter(Item);
                        CostAdjItemBucket.AddItemsToBucket(Item);
                        CostAdjItemBucket.FindLast();
                        CostAdjItemBucket.SetRecFilter();
                        Report.Run(Report::"Adjust Cost - Item Buckets", false, false, CostAdjItemBucket);
                    end;
                }
                action("Add Batch")
                {
                    Caption = 'Add batch';
                    ToolTip = 'Add the selected items to a new cost adjustment batch.';
                    Image = Add;

                    trigger OnAction()
                    var
                        Item: Record Item;
                        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
                        Choice: Integer;
                    begin
                        Choice := Dialog.StrMenu(StrMenuOptionsTxt, 0, ScheduleInstructionTxt);
                        if Choice = 0 then
                            exit;

                        if Choice = 1 then
                            CurrPage.SetSelectionFilter(Item);
                        CostAdjItemBucket.AddItemsToBucket(Item);
                    end;
                }
                action("View Batches")
                {
                    Caption = 'Item batches';
                    ToolTip = 'View the cost adjustment item batches.';
                    Image = ItemGroup;

                    trigger OnAction()
                    begin
                        Page.RunModal(Page::"Cost Adjustment Runners");
                    end;

                }
            }
            group(Logs)
            {
                Caption = 'Log per';

                action("Log Per Run")
                {
                    Caption = 'Run';
                    ToolTip = 'View the history of cost adjustment runs.';
                    Image = Log;
                    RunObject = page "Cost Adjustment Logs";
                }
                action("Log Per Item")
                {
                    Caption = 'Item';
                    ToolTip = 'View the history of cost adjustment runs for the selected item.';
                    Image = Item;

                    trigger OnAction()
                    begin
                        ViewDetailedLog();
                    end;
                }
            }
            group(History)
            {
                Caption = 'Item';
                Image = Item;

                action("Item Ledger Entries")
                {
                    Caption = 'Item Ledger Entries';
                    Image = ItemLedger;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    var
                        ItemLedgerEntry: Record "Item Ledger Entry";
                        ItemLedgerEntries: Page "Item Ledger Entries";
                    begin
                        ItemLedgerEntry.SetCurrentKey("Item No.");
                        ItemLedgerEntry.Ascending(false);
                        ItemLedgerEntry.SetRange("Item No.", Rec."No.");

                        ItemLedgerEntries.SetTableView(ItemLedgerEntry);
                        ItemLedgerEntries.ShowCostAdjustmentActions();
                        ItemLedgerEntries.Run();
                    end;
                }
                action("Value Entries")
                {
                    Caption = 'Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Item No." = field("No.");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                }
                action("Item Application Entries")
                {
                    Caption = 'Item Application Entries';
                    Image = EntriesList;
                    RunObject = Page "Item Application Entries";
                    ToolTip = 'View the history of item application entries that are created when you post inventory transactions.';
                }
                action("Cost Adjmt. Entry Points")
                {
                    Caption = 'Cost Adjmt. Entry Points';
                    Image = EntriesList;
                    RunObject = Page "Avg. Cost Adjmt. Entry Points";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'View the combinations of item, location, variant, and date for which the cost adjustment has been or must be run.';
                }
                action("Cost Adjmt. Orders")
                {
                    Caption = 'Cost Adjmt. Orders';
                    Image = OrderList;
                    RunObject = Page "Inventory Adjmt. Entry Orders";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'View production and assembly orders for which the cost adjustment has been or must be run.';
                }
            }
            group("Functions")
            {
                Caption = 'Functions';
                Image = Action;

                action("Exclude From Adjustment")
                {
                    Caption = 'Exclude item from adjustment';
                    ToolTip = 'Exclude the selected items from the cost adjustment process.';
                    Image = DeleteRow;

                    trigger OnAction()
                    begin
                        SetExcludedFromCostAdjustment(true);
                    end;
                }
                action("Include In Adjustment")
                {
                    Caption = 'Include item in adjustment';
                    ToolTip = 'Include the selected items in the cost adjustment process.';
                    Image = CompleteLine;

                    trigger OnAction()
                    begin
                        SetExcludedFromCostAdjustment(false);
                    end;
                }
                action("Post Inventory Cost to G/L")
                {
                    Caption = 'Post inventory cost to G/L';
                    Image = PostInventoryToGL;
                    RunObject = Report "Post Inventory Cost to G/L";
                    ToolTip = 'Post the quantity and value changes to the inventory in the item ledger entries and the value entries when you post inventory transactions, such as sales shipments or purchase receipts.';
                }
            }
            group(Diagnostics)
            {
                Caption = 'Diagnostics';

                action("Action Messages")
                {
                    Caption = 'Action Messages';
                    ToolTip = 'View the action messages that are generated by the cost adjustment process.';
                    Image = Action;

                    RunObject = Page "Cost Adjmt. Action Messages";
                }
                action("Export Item Data")
                {
                    Caption = 'Export item data';
                    ToolTip = 'Use this function to export item related data to text file (you can attach this file to support requests in case you may have issues with costing calculation).';
                    Image = Export;

                    trigger OnAction()
                    var
                        Item: Record Item;
                    begin
                        Item.SetRange("No.", Rec."No.");
                        Xmlport.Run(XmlPort::"Export Item Data", false, false, Item);
                    end;
                }
                action("Import Item Data")
                {
                    Caption = 'Import item data';
                    ToolTip = 'Use this function to import item related data from text file.';
                    Image = Import;
                    Visible = SandboxActionsVisible;

                    trigger OnAction()
                    begin
                        if not SandboxActionsVisible then
                            Error(NotTestEnvironmentErr);
                        Xmlport.Run(XmlPort::"Export Item Data", false, true);
                    end;
                }
                action("Reset Cost Is Adjusted")
                {
                    Caption = 'Reset Cost Is Adjusted';
                    ToolTip = 'Mark that the cost of the item must be adjusted.';
                    Image = MoveToNextPeriod;

                    RunObject = report "Reset Cost Is Adjusted";
                }
                action("Costing Issues Detection")
                {
                    Caption = 'Costing Issues Detection report';
                    ToolTip = 'Run the diagnostic report to detect issues in item related data that may cause costing calculation errors.';
                    Image = ShowWarning;

                    RunObject = report "Costing Errors Detection";
                }
                action("Clear Data")
                {
                    Caption = 'Delete item data';
                    ToolTip = 'Delete all item ledger entries, value entries, item application entries, and cost adjustment related entries in the database.';
                    Image = ClearLog;
                    Visible = SandboxActionsVisible;

                    trigger OnAction()
                    begin
                        if not SandboxActionsVisible then
                            Error(NotTestEnvironmentErr);
                        Report.Run(Report::"Delete Item Data", false, false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group("Show/Hide_Promoted")
            {
                Caption = 'Show/hide';

                actionref("Show Non-Adjusted_Promoted"; "Show Non-Adjusted") { }
                actionref("Show Included_Promoted"; "Show Included") { }
                actionref("Show Excluded_Promoted"; "Show Excluded") { }
                actionref("Show All_Promoted"; "Show All") { }
            }
            group("Adjust Cost_Promoted")
            {
                Caption = 'Adjust';

                ShowAs = SplitButton;
                actionref("Run_Promoted"; "Run") { }
                actionref("Add Batch & Run_Promoted"; "Add Batch & Run") { }
                actionref("Add Batch_Promoted"; "Add Batch") { }
                actionref("View Batches_Promoted"; "View Batches") { }
            }
            group(Item_Promoted)
            {
                Caption = 'Item';

                actionref("Item Ledger Entries_Promoted"; "Item Ledger Entries") { }
                actionref("Value Entries_Promoted"; "Value Entries") { }
                actionref("Item Application Entries_Promoted"; "Item Application Entries") { }
                actionref("Cost Adjmt. Entry Points_Promoted"; "Cost Adjmt. Entry Points") { }
                actionref("Cost Adjmt. Orders_Promoted"; "Cost Adjmt. Orders") { }
            }
            group(Logs_Promoted)
            {
                Caption = 'Log per';

                actionref("Log Per Run_Promoted"; "Log Per Run") { }
                actionref("Log Per Item_Promoted"; "Log Per Item") { }
            }
            group("Functions_Promoted")
            {
                Caption = 'Functions';

                actionref("Exclude From Adjustment_Promoted"; "Exclude From Adjustment") { }
                actionref("Include In Adjustment_Promoted"; "Include In Adjustment") { }
                actionref("Post Inventory Cost to G/L_Promoted"; "Post Inventory Cost to G/L") { }

            }
            group("Diagnostics_Promoted")
            {
                Caption = 'Diagnostics';

                actionref("Action Messages_Promoted"; "Action Messages") { }
                actionref("Export Item Data_Promoted"; "Export Item Data") { }
                actionref("Import Item Data_Promoted"; "Import Item Data") { }
                actionref("Reset Cost Is Adjusted_Promoted"; "Reset Cost Is Adjusted") { }
                actionref("Costing Issues Detection_Promoted"; "Costing Issues Detection") { }
                actionref("Clear Data_Promoted"; "Clear Data") { }
            }
        }
    }

    var
        InventorySetup: Record "Inventory Setup";
        LastCostAdjustmentRunStatus, LastCostAdjustmentItemStatus : Enum "Cost Adjustment Run Status";
        LastCostAdjustmentItemDateTime, LastSuccessfulRunDateTime : DateTime;
        NonAdjustedItems: Integer;
        ItemBatches: Integer;
        AverageCostCalcType, AverageCostPeriod : Text;
        StatusRunStyleExpr, StatusItemStyleExpr : Text;
        SandboxActionsVisible: Boolean;
        StrMenuOptionsTxt: Label 'Selected,All', Comment = 'Comma separated phrases must be translated separately.';
        ScheduleInstructionTxt: Label 'For which items do you want to schedule the cost adjustment?';
        RunInstructionTxt: Label 'For which items do you want to run the cost adjustment?';
        NotTestEnvironmentErr: Label 'This function is only available in the demo company or in a sandbox environment.';
        ActionMessagesExistTxt: Label 'The system has detected potential issues in data or settings that may affect the cost adjustment.';
        ReviewActionMessagesTxt: Label 'Review action messages';

    trigger OnOpenPage()
    var
    begin
        SandboxActionsVisible := IsSandBoxActionsVisible();

        CheckActionMessages();
    end;

    trigger OnAfterGetRecord()
    var
        CostAdjustmentLog: Record "Cost Adjustment Log";
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
    begin
        UpdateSummary();

        AverageCostCalcType := '';
        AverageCostPeriod := '';
        if Rec."Costing Method" = Rec."Costing Method"::Average then begin
            AverageCostCalcType := Format(InventorySetup."Average Cost Calc. Type");
            AverageCostPeriod := Format(InventorySetup."Average Cost Period");
        end;

        Clear(LastCostAdjustmentItemDateTime);
        Clear(LastCostAdjustmentItemStatus);
        CostAdjustmentDetailedLog.SetCurrentKey("Item No.", "Ending Date-Time");
        CostAdjustmentDetailedLog.SetRange("Item No.", Rec."No.");
        if CostAdjustmentDetailedLog.FindLast() then begin
            LastCostAdjustmentItemDateTime := CostAdjustmentDetailedLog."Ending Date-Time";
            CostAdjustmentLog.SetCurrentKey("Cost Adjustment Run Guid");
            CostAdjustmentLog.SetRange("Cost Adjustment Run Guid", CostAdjustmentDetailedLog."Cost Adjustment Run Guid");
            CostAdjustmentLog.FindFirst();
            LastCostAdjustmentItemStatus := CostAdjustmentLog.Status;
        end;

        case LastCostAdjustmentItemStatus of
            LastCostAdjustmentItemStatus::Success:
                StatusItemStyleExpr := 'Favorable';
            LastCostAdjustmentItemStatus::Failed, LastCostAdjustmentItemStatus::"Timed out":
                StatusItemStyleExpr := 'Unfavorable';
            else
                StatusItemStyleExpr := 'Standard';
        end;
    end;

    protected procedure IsSandboxActionsVisible(): Boolean
    var
        CompanyInformation: Record "Company Information";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        InventorySetup.Get();
        CompanyInformation.Get();
        exit(EnvironmentInformation.IsSandbox() or CompanyInformation."Demo Company");
    end;

    local procedure UpdateSummary()
    var
        NonAdjustedItem: Record Item;
        CostAdjustmentLog: Record "Cost Adjustment Log";
        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
    begin
        NonAdjustedItem.SetRange("Cost is Adjusted", false);
        NonAdjustedItems := NonAdjustedItem.Count();

        LastCostAdjustmentRunStatus := LastCostAdjustmentRunStatus::"Not started";
        LastSuccessfulRunDateTime := 0DT;

        if CostAdjustmentLog.FindLast() then begin
            LastCostAdjustmentRunStatus := CostAdjustmentLog.Status;
            LastSuccessfulRunDateTime := CostAdjustmentLog."Ending Date-Time";
        end;

        case LastCostAdjustmentRunStatus of
            LastCostAdjustmentRunStatus::Success:
                StatusRunStyleExpr := 'Favorable';
            LastCostAdjustmentRunStatus::Failed, LastCostAdjustmentRunStatus::"Timed out":
                StatusRunStyleExpr := 'Unfavorable';
            else
                StatusRunStyleExpr := 'Standard';
        end;

        ItemBatches := CostAdjItemBucket.Count();
    end;

    procedure RunAdjustCostItemEntries(var SelectedItem: Record Item)
    var
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        SelectedItemFilter: Text;
        ReportItemFilter: Text[250];
    begin
        Commit();
        if SelectedItem.GetFilters() = '' then
            SelectedItemFilter := '*'
        else
            SelectedItemFilter := SelectionFilterManagement.GetSelectionFilterForItem(SelectedItem);

        SelectedItem.SetRange("Cost is Adjusted", false);
        if SelectedItem.IsEmpty() then
            exit;

        ReportItemFilter := CopyStr(SelectedItemFilter, 1, MaxStrLen(ReportItemFilter));
        AdjustCostItemEntries.InitializeRequest(ReportItemFilter, '');
        AdjustCostItemEntries.SetPostToGL(InventorySetup."Automatic Cost Posting");
        AdjustCostItemEntries.Run();
    end;

    local procedure ViewLog(Success: Boolean)
    var
        CostAdjustmentLog: Record "Cost Adjustment Log";
    begin
        if Success then
            CostAdjustmentLog.SetRange(Status, CostAdjustmentLog.Status::Success);
        if CostAdjustmentLog.FindLast() then;
        Page.RunModal(0, CostAdjustmentLog);
    end;

    local procedure ViewDetailedLog()
    var
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
    begin
        CostAdjustmentDetailedLog.SetRange("Item No.", Rec."No.");
        Page.RunModal(0, CostAdjustmentDetailedLog);
    end;

    local procedure SetExcludedFromCostAdjustment(Excluded: Boolean)
    var
        ItemToModify: Record Item;
    begin
        CurrPage.SetSelectionFilter(ItemToModify);
        ItemToModify.ModifyAll("Excluded from Cost Adjustment", Excluded);
        CurrPage.Update(false);
    end;

    local procedure CheckActionMessages()
    var
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
        ActionMessagesExistNotification: Notification;
    begin
        CostAdjmtActionMessage.SetFilter("Next Check Date/Time", '>=%1', CurrentDateTime());
        CostAdjmtActionMessage.SetRange(Active, true);
        if CostAdjmtActionMessage.IsEmpty() then
            exit;

        ActionMessagesExistNotification.Message := ActionMessagesExistTxt;
        ActionMessagesExistNotification.Scope := NotificationScope::LocalScope;
        ActionMessagesExistNotification.AddAction(ReviewActionMessagesTxt, Codeunit::"Cost Adjmt. Signals", 'ShowActionMessages');
        ActionMessagesExistNotification.Send();
    end;

    protected procedure GetNotTestEnvironmentErr(): Text
    begin
        exit(NotTestEnvironmentErr);
    end;
}
