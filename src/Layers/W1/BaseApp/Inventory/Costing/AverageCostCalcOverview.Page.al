// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

page 5847 "Average Cost Calc. Overview"
{
    Caption = 'Average Cost Calc. Overview';
    DataCaptionExpression = ItemName;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Average Cost Calc. Overview";
    SourceTableTemporary = true;
    SourceTableView = sorting("Attached to Valuation Date", "Attached to Entry No.", Type);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = TypeIndent;
                IndentationControls = Type;
                ShowAsTree = true;
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies either that the entry is a summary entry, Closing Entry, or the type that was used in the calculation of the average cost of the item.';
                }
                field("Valuation Date"; Rec."Valuation Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the valuation date associated with the average cost calculation.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the item associated with the entry.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the location code associated with the entry.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(AverageCostCntrl; Rec.CalculateAverageCost())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 2;
                    Caption = 'Unit Cost';
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the average cost for this entry.';
                }
                field("Cost is Adjusted"; Rec."Cost is Adjusted")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the cost is adjusted for the entry.';
                }
                field("Item Ledger Entry No."; Rec."Item Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    HideValue = ItemLedgerEntryNoHideValue;
                    ToolTip = 'Specifies the number of the item ledger entry that this entry is linked to.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
                    Visible = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    HideValue = EntryTypeHideValue;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that the average cost applies to.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number for the entry.';
                    Visible = false;
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    HideValue = DocumentLineNoHideValue;
                    ToolTip = 'Specifies the document line that the comment applies to.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the quantity associated with the entry.';
                }
                field("Cost Amount (Expected)"; Rec."Cost Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the expected cost in LCY of the quantity posting.';
                }
                field("Cost Amount (Actual)"; Rec."Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the adjusted cost in LCY of the quantity posting.';
                }
            }
        }
    }

    actions
    {
        area(processing)
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
                        if ItemLedgEntry.Get(Rec."Entry No.") then
                            ItemLedgEntry.ShowDimensions();
                    end;
                }
                action("&Value Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Item Ledger Entry No." = field("Item Ledger Entry No."),
                                  "Valuation Date" = field("Valuation Date");
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
                    var
                        ItemLedgEntry: Record "Item Ledger Entry";
                    begin
                        if ItemLedgEntry.Get(Rec."Item Ledger Entry No.") then
                            CODEUNIT.Run(CODEUNIT::"Show Applied Entries", ItemLedgEntry);
                    end;
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    var
                        ItemLedgEntry: Record "Item Ledger Entry";
                    begin
                        ItemLedgEntry.Get(Rec."Item Ledger Entry No.");
                        ItemLedgEntry.ShowReservationEntries(true);
                    end;
                }
            }
        }
        area(navigation)
        {
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
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group(Category_Application)
                {
                    Caption = 'Application';

                    actionref("Applied E&ntries_Promoted"; "Applied E&ntries")
                    {
                    }
                    actionref("Reservation Entries_Promoted"; "Reservation Entries")
                    {
                    }
                }
                group(Category_Line)
                {
                    Caption = 'Line';

                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                    actionref("&Value Entries_Promoted"; "&Value Entries")
                    {
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentLineNoHideValue := false;
        EntryTypeHideValue := false;
        ItemLedgerEntryNoHideValue := false;
        TypeIndent := 0;
        SetExpansionStatus();

        // For synthetic summary (Closing Entry) rows compute dynamic roll‑up values on demand
        if Rec.Type = Rec.Type::"Closing Entry" then begin
            Rec.Quantity := Rec.CalculateRemainingQty();            // Remaining quantity at valuation point
            Rec."Cost Amount (Expected)" := Rec.CalculateCostAmt(false); // Summed expected cost
            Rec."Cost Amount (Actual)" := Rec.CalculateCostAmt(true);   // Summed adjusted/actual cost
        end;
        TypeOnFormat();
        ItemLedgerEntryNoOnFormat();
        EntryTypeOnFormat();
        DocumentLineNoOnFormat();
    end;

    trigger OnOpenPage()
    var
        ProgressDialog: Dialog;
    begin
        ProgressDialog.Open(LoadingAvgCalcLbl);
        InitTempTable();                // Load level 0 nodes (root Closing Entry summaries)
        ExpandAll(TempAvgCostCalcOverview); // Pre-expand tree so user immediately sees detail
        ProgressDialog.Close();

        SetRecFilters();
        CurrPage.Update(false);

        ItemName := StrSubstNo('%1  %2', Item."No.", Item.Description);
    end;

    var
        Item: Record Item;
        TempAvgCostCalcOverview: Record "Average Cost Calc. Overview" temporary;
        ItemLedgEntry: Record "Item Ledger Entry";
        GetAvgCostCalcOverview: Codeunit "Get Average Cost Calc Overview";
        Navigate: Page Navigate;
        ActualExpansionStatus: Integer;  // 0 = collapsed, 1 = expanded, 2 = leaf
        ItemName: Text[250];
        TypeIndent: Integer;
        ItemLedgerEntryNoHideValue: Boolean;
        EntryTypeHideValue: Boolean;
        DocumentLineNoHideValue: Boolean;
        LoadingAvgCalcLbl: Label 'Loading average cost calculations...';

    procedure SetExpansionStatus()
    begin
        case true of
            IsExpanded(Rec):
                ActualExpansionStatus := 1; // expanded
            HasChildren(Rec):
                ActualExpansionStatus := 0 // collapsible (has children but not expanded in current iteration)
            else
                ActualExpansionStatus := 2; // leaf
        end;
    end;

    procedure InitTempTable()
    var
        AvgCostCalcOverviewFilters: Record "Average Cost Calc. Overview";
    begin
        TempAvgCostCalcOverview."Item No." := Item."No.";
        TempAvgCostCalcOverview.SetFilter("Valuation Date", Item.GetFilter("Date Filter"));
        TempAvgCostCalcOverview.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        TempAvgCostCalcOverview.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        OnInitTempTableOnAfterAvgCostCalcOverviewSetFilters(TempAvgCostCalcOverview, Item);

        GetAvgCostCalcOverview.Run(TempAvgCostCalcOverview);
        TempAvgCostCalcOverview.Reset();
        AvgCostCalcOverviewFilters.CopyFilters(Rec);
        Rec.Reset();
        Rec.DeleteAll();
        TempAvgCostCalcOverview.SetRange(Level, 0);
        if TempAvgCostCalcOverview.FindSet() then
            repeat
                Rec := TempAvgCostCalcOverview;
                Rec.Insert();
            until TempAvgCostCalcOverview.Next() = 0;
        TempAvgCostCalcOverview.SetRange(Level);
        Rec.CopyFilters(AvgCostCalcOverviewFilters);
    end;

    local procedure ExpandAll(var AvgCostCalcOverview: Record "Average Cost Calc. Overview")
    var
        AvgCostCalcOverviewFilters: Record "Average Cost Calc. Overview";
    begin
        TempAvgCostCalcOverview."Item No." := Item."No.";
        TempAvgCostCalcOverview.SetFilter("Valuation Date", Item.GetFilter("Date Filter"));
        TempAvgCostCalcOverview.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        TempAvgCostCalcOverview.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        OnExpandAllOnAfterAvgCostCalcOverviewSetFilters(AvgCostCalcOverview, Item);

        GetAvgCostCalcOverview.Run(AvgCostCalcOverview);
        AvgCostCalcOverviewFilters.CopyFilters(Rec);
        Rec.Reset();
        Rec.DeleteAll();

        // Pass 1 (descending): compute aggregates by calling Calculate on each (some routines rely on reverse order)
        if TempAvgCostCalcOverview.Find('+') then
            repeat
                Rec := AvgCostCalcOverview;
                GetAvgCostCalcOverview.Calculate(AvgCostCalcOverview);
                TempAvgCostCalcOverview.Reset();
                AvgCostCalcOverview := Rec; // restore record after Calculate changed it
            until TempAvgCostCalcOverview.Next(-1) = 0;

        // Pass 2 (ascending): insert all nodes to visible temp (Rec) maintaining hierarchy visual order
        if TempAvgCostCalcOverview.Find('+') then
            repeat
                Rec := AvgCostCalcOverview;
                Rec.Insert();
            until TempAvgCostCalcOverview.Next(-1) = 0;

        Rec.CopyFilters(AvgCostCalcOverviewFilters);
    end;

    local procedure IsExpanded(ActualAvgCostCalcOverview: Record "Average Cost Calc. Overview"): Boolean
    var
        AvgCostCalcOverview: Record "Average Cost Calc. Overview";
        Found: Boolean;
    begin
        AvgCostCalcOverview := Rec;
        Rec.SetCurrentKey("Attached to Valuation Date", "Attached to Entry No.", Type);
        Rec := ActualAvgCostCalcOverview;
        Found := (Rec.Next(GetDirection()) <> 0);
        if Found then
            Found := (Rec.Level > ActualAvgCostCalcOverview.Level);
        Rec := AvgCostCalcOverview;
        exit(Found);
    end;

    local procedure HasChildren(var ActualAvgCostCalcOverview: Record "Average Cost Calc. Overview"): Boolean
    begin
        TempAvgCostCalcOverview := ActualAvgCostCalcOverview;
        if Rec.Type = Rec.Type::"Closing Entry" then
            exit(GetAvgCostCalcOverview.EntriesExist(TempAvgCostCalcOverview));
        exit(false);
    end;

    local procedure GetDirection(): Integer
    begin
        if Rec.Ascending then
            exit(1);
        exit(-1);
    end;

    procedure SetRecFilters()
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Attached to Valuation Date", "Attached to Entry No.", Type);
        CurrPage.Update(false);
    end;

    procedure SetItem(var Item2: Record Item)
    begin
        Item.Copy(Item2);
    end;

    local procedure TypeOnFormat()
    begin
        if Rec.Type <> Rec.Type::"Closing Entry" then
            TypeIndent := 1;
    end;

    local procedure ItemLedgerEntryNoOnFormat()
    begin
        if Rec.Type = Rec.Type::"Closing Entry" then
            ItemLedgerEntryNoHideValue := true;
    end;

    local procedure EntryTypeOnFormat()
    begin
        if Rec.Type = Rec.Type::"Closing Entry" then
            EntryTypeHideValue := true;
    end;

    local procedure DocumentLineNoOnFormat()
    begin
        if Rec.Type = Rec.Type::"Closing Entry" then
            DocumentLineNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExpandAllOnAfterAvgCostCalcOverviewSetFilters(var AvgCostCalcOverview: Record "Average Cost Calc. Overview" temporary; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTempTableOnAfterAvgCostCalcOverviewSetFilters(var AvgCostCalcOverview: Record "Average Cost Calc. Overview" temporary; var Item: Record Item)
    begin
    end;
}

