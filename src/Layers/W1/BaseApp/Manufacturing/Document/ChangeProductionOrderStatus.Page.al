// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using System.Utilities;

page 99000914 "Change Production Order Status"
{
    ApplicationArea = Manufacturing;
    Caption = 'Change Production Order Status';
    PageType = Worksheet;
    SourceTable = "Production Order";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ProdOrderStatus; ProdOrderStatus)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Status Filter';
                    OptionCaption = 'Simulated,Planned,Firm Planned,Released';
                    ToolTip = 'Specifies the status of the production orders to define a filter on the lines.';

                    trigger OnValidate()
                    begin
                        ProdOrderStatusOnAfterValidate();
                    end;
                }
                field(StartingDate; StartingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Must Start Before';
                    ToolTip = 'Specifies a date to define a filter on the lines.';

                    trigger OnValidate()
                    begin
                        StartingDateOnAfterValidate();
                    end;
                }
                field(EndingDate; EndingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ends Before';
                    ToolTip = 'Specifies a date to define a filter on the lines.';

                    trigger OnValidate()
                    begin
                        EndingDateOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the production order.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date on which you created the production order.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the source type of the production order.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting time of the production order.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date of the production order.';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending time of the production order.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending date of the production order.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the due date of the production order.';
                }
                field("Finished Date"; Rec."Finished Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the actual finishing date of a finished production order.';
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
            group("Pro&d. Order")
            {
                Caption = 'Pro&d. Order';
                Image = "Order";
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Item Ledger E&ntries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Item Ledger E&ntries';
                        Image = ItemLedger;
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';

                        trigger OnAction()
                        var
                            ItemLedgEntry: Record "Item Ledger Entry";
                        begin
                            if Rec.Status <> Rec.Status::Released then
                                exit;

                            ItemLedgEntry.Reset();
                            ItemLedgEntry.SetCurrentKey("Order Type", "Order No.");
                            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
                            ItemLedgEntry.SetRange("Order No.", Rec."No.");
                            PAGE.RunModal(0, ItemLedgEntry);
                        end;
                    }
                    action("Capacity Ledger Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Ledger Entries';
                        Image = CapacityLedger;
                        ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';

                        trigger OnAction()
                        var
                            CapLedgEntry: Record "Capacity Ledger Entry";
                        begin
                            if Rec.Status <> Rec.Status::Released then
                                exit;

                            CapLedgEntry.Reset();
                            CapLedgEntry.SetCurrentKey("Order Type", "Order No.");
                            CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
                            CapLedgEntry.SetRange("Order No.", Rec."No.");
                            PAGE.RunModal(0, CapLedgEntry);
                        end;
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Value Entries';
                        Image = ValueLedger;
                        ToolTip = 'View the value entries of the item on the document or journal line.';

                        trigger OnAction()
                        var
                            ValueEntry: Record "Value Entry";
                        begin
                            if Rec.Status <> Rec.Status::Released then
                                exit;

                            ValueEntry.Reset();
                            ValueEntry.SetCurrentKey("Order Type", "Order No.");
                            ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
                            ValueEntry.SetRange("Order No.", Rec."No.");
                            PAGE.RunModal(0, ValueEntry);
                        end;
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Prod. Order Comment Sheet";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
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
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Production Order Statistics";
                    RunPageLink = Status = field(Status),
                                  "No." = field("No."),
                                  "Date Filter" = field("Date Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Change &Status")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Change &Status';
                    Ellipsis = true;
                    Image = ChangeStatus;
                    ToolTip = 'Change the status of the selected production orders to a new one.';

                    trigger OnAction()
                    begin
                        ChangeStatusWithSelectionFilter();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Change &Status_Promoted"; "Change &Status")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Prod. Order', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Item Ledger E&ntries_Promoted"; "Item Ledger E&ntries")
                {
                }
                actionref("Capacity Ledger Entries_Promoted"; "Capacity Ledger Entries")
                {
                }
                actionref("Value Entries_Promoted"; "Value Entries")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        BuildPage();
    end;

    var
        ProdOrderStatus: Option Simulated,Planned,"Firm Planned",Released;
        StartingDate: Date;
        EndingDate: Date;
        ChangingStatusInfoLbl: Label 'Changing status to %1...\\', Comment = '%1 - New Status';
        ProcessingProgressTxt: Label 'Prod. Order #1###### @2@@@@@@@@@@@@@', Comment = '%1 - Production Order No.; %2 - Progress Percentage';

    protected procedure BuildPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Status, ProdOrderStatus);
        Rec.FilterGroup(0);

        if StartingDate <> 0D then
            Rec.SetFilter("Starting Date", '..%1', StartingDate)
        else
            Rec.SetRange("Starting Date");

        if EndingDate <> 0D then
            Rec.SetFilter("Ending Date", '..%1', EndingDate)
        else
            Rec.SetRange("Ending Date");

        CurrPage.Update(false);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure ChangeStatusWithSelectionFilter()
    var
        ProductionOrder: Record "Production Order";
        TempErrors: Record "Error Message" temporary;
        ProdOrderChangeStatusBulk: Codeunit ProdOrderChangeStatusBulk;
        ChangeStatusOnProdOrder: Page "Change Status on Prod. Order";
        NewProductionOrderStatus: Enum "Production Order Status";
        Error: ErrorInfo;
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
        ProgressDialog: Dialog;
        NoOfProductionOrdersToProcess: Integer;
        ProcessedProductionOrdersCounter: Integer;
        IsHandled: Boolean;
        FinishOrderWithoutOutput: Boolean;
    begin
        CurrPage.SetSelectionFilter(ProductionOrder);

        if ProductionOrder.FindSet() then begin
            ChangeStatusOnProdOrder.Set(ProductionOrder);
            if ChangeStatusOnProdOrder.RunModal() <> Action::Yes then
                exit;
            ChangeStatusOnProdOrder.ReturnPostingInfo(NewProductionOrderStatus, NewPostingDate, NewUpdateUnitCost, FinishOrderWithoutOutput);

            NoOfProductionOrdersToProcess := ProductionOrder.Count();
            ProcessedProductionOrdersCounter := 0;
            ProgressDialog.Open(StrSubstNo(ChangingStatusInfoLbl, NewProductionOrderStatus) + ProcessingProgressTxt);
            repeat
                ProcessedProductionOrdersCounter += 1;
                ProgressDialog.Update(1, ProductionOrder."No.");
                ProgressDialog.Update(2, Round(ProcessedProductionOrdersCounter / NoOfProductionOrdersToProcess * 10000, 1));

                IsHandled := false;
                OnBeforeChangeProdOrderStatus(ProductionOrder, NewProductionOrderStatus, NewPostingDate, NewUpdateUnitCost, IsHandled);
                if not IsHandled then begin
                    ProdOrderChangeStatusBulk.SetParameters(NewProductionOrderStatus, NewPostingDate, NewUpdateUnitCost, FinishOrderWithoutOutput);
                    if not ProdOrderChangeStatusBulk.Run(ProductionOrder) then begin
                        TempErrors.ID := TempErrors.ID + 1;
                        TempErrors.Message := GetLastErrorText();
                        TempErrors.Insert();
                    end;
                end;
                if System.HasCollectedErrors() then
                    foreach Error in System.GetCollectedErrors() do begin
                        TempErrors.ID := TempErrors.ID + 1;
                        TempErrors.Message := Error.Message;
                        TempErrors.Validate("Record ID", Error.RecordId);
                        TempErrors.Insert();
                    end;

            until ProductionOrder.Next() = 0;
            ClearCollectedErrors();
            if TempErrors.Count > 0 then
                Page.Run(Page::"Error Messages", TempErrors);
        end;
    end;

    local procedure ProdOrderStatusOnAfterValidate()
    begin
        BuildPage();
    end;

    local procedure StartingDateOnAfterValidate()
    begin
        BuildPage();
    end;

    local procedure EndingDateOnAfterValidate()
    begin
        BuildPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeProdOrderStatus(Rec: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean; var IsHandled: Boolean)
    begin
    end;
}

