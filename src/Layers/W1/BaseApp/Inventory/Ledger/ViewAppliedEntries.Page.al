// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Posting;

page 522 "View Applied Entries"
{
    Caption = 'View Applied Entries';
    DataCaptionExpression = CaptionExpr();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Worksheet;
    Permissions = TableData "Item Application Entry" = rimd;
    SaveValues = true;
    SourceTable = "Item Ledger Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what type of document was posted to create the item ledger entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the line on the posted document that corresponds to the item ledger entry.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item in the entry.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                    Visible = false;
                }
                field(ApplQty; ApplQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item ledger entry linked to an inventory decrease, or increase, as appropriate.';
                }
                field(Qty; Qty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item ledger entry.';
                }
                field("Cost Amount (Actual)"; Rec."Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted cost, in LCY, of the quantity posting.';
                }
                field(GetUnitCostLCY; Rec.GetUnitCostLCY())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit Cost(LCY)';
                    ToolTip = 'Specifies the unit cost of the item in the item ledger entry.';
                    Visible = false;
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the item on the line have been invoiced.';
                    Visible = true;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the item on the line have been reserved.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                    Visible = true;
                }
                field("CostAvailable(Rec)"; CostAvailable(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity Available for Cost Applications';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item ledger entry that can be cost applied.';
                }
                field("QuantityAvailable(Rec)"; QuantityAvailable(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available for Quantity Application';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item ledger entry that can be applied.';
                }
                field("Shipped Qty. Not Returned"; Rec."Shipped Qty. Not Returned")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this item ledger entry that was shipped and has not yet been returned.';
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry has been fully applied to.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity per item unit of measure.';
                    Visible = false;
                }
                field("Drop Shipment"; Rec."Drop Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
                    Visible = false;
                }
                field("Applies-to Entry"; Rec."Applies-to Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the quantity on the journal line must be applied to an already-posted entry. In that case, enter the entry number that the quantity will be applied to.';
                    Visible = false;
                }
                field("Applied Entry to Adjust"; Rec."Applied Entry to Adjust")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether there is one or more applied entries, which need to be adjusted.';
                    Visible = false;
                }
                field("Order Type"; Rec."Order Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of order that the entry was created in.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the order that created the entry.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
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
            }
        }
        area(processing)
        {
            action(RemoveAppButton)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Re&move Application';
                Image = Cancel;
                ToolTip = 'Remove item applications.';
                Visible = RemoveAppButtonVisible;

                trigger OnAction()
                begin
                    UnapplyRec();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RemoveAppButton_Promoted; RemoveAppButton)
                {
                }
            }
            group(Category_Entry)
            {
                Caption = 'Entry';

                actionref("Reservation Entries_Promoted"; "Reservation Entries")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("&Value Entries_Promoted"; "&Value Entries")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetApplQty();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Rec.Find(Which));
    end;

    trigger OnInit()
    begin
        RemoveAppButtonVisible := true;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.LookupMode := not ShowApplied;
        RemoveAppButtonVisible := ShowApplied;
        Show();
    end;

    var
        ItemLedgerEntryToShow: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ShowApplied: Boolean;
        ShowQuantity: Boolean;
        RemoveAppButtonVisible: Boolean;
        MaxToApply: Decimal;
        ApplQty: Decimal;
        Qty: Decimal;
        TotalApplied: Decimal;
        AppliedEntriesLbl: Label 'Applied Entries';
        UnappliedEntriesLbl: Label 'Unapplied Entries';

    procedure SetRecordToShow(var RecordToSet: Record "Item Ledger Entry"; var ApplyCodeunit: Codeunit "Item Jnl.-Post Line"; NewShowApplied: Boolean)
    begin
        ItemLedgerEntryToShow.Copy(RecordToSet);
        ItemJnlPostLine := ApplyCodeunit;
        ShowApplied := NewShowApplied;
    end;

    local procedure Show()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemLedgerEntry.Get(ItemLedgerEntryToShow."Entry No.");
        ShowQuantity := not ((ItemLedgerEntry."Entry Type" in [ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Entry Type"::Consumption, ItemLedgerEntry."Entry Type"::Output]) and ItemLedgerEntry.Positive);

        MaxToApply := 0;
        if not ShowQuantity then
            MaxToApply := ItemLedgerEntry.Quantity + ItemApplicationEntry.Returned(ItemLedgerEntry."Entry No.");
        SetMyView(ItemLedgerEntryToShow, ShowApplied, ShowQuantity, MaxToApply);
    end;

    local procedure SetMyView(ItemLedgerEntry: Record "Item Ledger Entry"; ShowApplied2: Boolean; ShowQuantity2: Boolean; MaxToApply2: Decimal)
    begin
        InitView();
        case ShowQuantity2 of
            true:
                case ShowApplied2 of
                    true:
                        ShowQuantityApplied(ItemLedgerEntry);
                    false:
                        begin
                            ShowQuantityOpen(ItemLedgerEntry);
                            ShowCostOpen(ItemLedgerEntry, MaxToApply2);
                        end;
                end;
            false:
                case ShowApplied2 of
                    true:
                        ShowCostApplied(ItemLedgerEntry);
                    false:
                        ShowCostOpen(ItemLedgerEntry, MaxToApply2);
                end;
        end;

        if TempItemLedgerEntry.FindSet() then
            repeat
                Rec := TempItemLedgerEntry;
                Rec.Insert();
            until TempItemLedgerEntry.Next() = 0;
    end;

    local procedure InitView()
    begin
        Rec.DeleteAll();

        TempItemLedgerEntry.Reset();
        TempItemLedgerEntry.DeleteAll();
    end;

    local procedure ShowQuantityApplied(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        InitApplied();

        if ItemLedgerEntry.Positive then begin
            ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>%1&<>%2', ItemLedgerEntry."Entry No.", 0);
            ItemApplicationEntry.SetLoadFields("Outbound Item Entry No.", Quantity);
            if ItemApplicationEntry.FindSet() then
                repeat
                    InsertTempEntry(ItemApplicationEntry."Outbound Item Entry No.", ItemApplicationEntry.Quantity, true);
                until ItemApplicationEntry.Next() = 0;
        end else begin
            ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetLoadFields("Inbound Item Entry No.", Quantity);
            if ItemApplicationEntry.FindSet() then
                repeat
                    InsertTempEntry(ItemApplicationEntry."Inbound Item Entry No.", -ItemApplicationEntry.Quantity, true);
                until ItemApplicationEntry.Next() = 0;
        end;
    end;

    local procedure ShowQuantityOpen(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntry."Remaining Quantity" = 0 then
            exit;

        ItemLedgerEntry2.SetRange("Item No.", ItemLedgerEntry."Item No.");
        ItemLedgerEntry2.SetRange("Location Code", ItemLedgerEntry."Location Code");
        ItemLedgerEntry2.SetRange(Positive, not ItemLedgerEntry.Positive);
        ItemLedgerEntry2.SetRange(Open, true);
        ItemLedgerEntry2.SetAutoCalcFields("Reserved Quantity");
        ItemLedgerEntry2.SetLoadFields("Remaining Quantity", "Reserved Quantity");
        if ItemLedgerEntry2.FindSet() then
            repeat
                if ItemLedgerEntry2."Remaining Quantity" - ItemLedgerEntry2."Reserved Quantity" <> 0 then
                    if not ItemApplicationEntry.ExistsBetween(ItemLedgerEntry."Entry No.", ItemLedgerEntry2."Entry No.") then
                        InsertTempEntry(ItemLedgerEntry2."Entry No.", 0, true);
            until ItemLedgerEntry2.Next() = 0;
    end;

    local procedure ShowCostApplied(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        InitApplied();

        if ItemLedgerEntry.Positive then begin
            ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
            ItemApplicationEntry.SetRange("Cost Application", true);
            ItemApplicationEntry.SetLoadFields("Outbound Item Entry No.", Quantity);
            // Show even average cost application
            if ItemApplicationEntry.FindSet() then
                repeat
                    InsertTempEntry(ItemApplicationEntry."Outbound Item Entry No.", ItemApplicationEntry.Quantity, false);
                until ItemApplicationEntry.Next() = 0;
        end else begin
            ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetRange("Cost Application", true);
            ItemApplicationEntry.SetLoadFields("Inbound Item Entry No.", Quantity);
            // Show even average cost application
            if ItemApplicationEntry.FindSet() then
                repeat
                    InsertTempEntry(ItemApplicationEntry."Inbound Item Entry No.", -ItemApplicationEntry.Quantity, false);
                until ItemApplicationEntry.Next() = 0;
        end;
    end;

    local procedure ShowCostOpen(ItemLedgerEntry: Record "Item Ledger Entry"; MaxToApply2: Decimal)
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry2.SetRange("Item No.", ItemLedgerEntry."Item No.");
        ItemLedgerEntry2.SetRange("Location Code", ItemLedgerEntry."Location Code");
        ItemLedgerEntry2.SetRange(Positive, not ItemLedgerEntry.Positive);
        ItemLedgerEntry2.SetFilter("Shipped Qty. Not Returned", '<%1&>=%2', 0, -MaxToApply2);
        if (MaxToApply2 <> 0) and ItemLedgerEntry.Positive then
            ItemLedgerEntry2.SetFilter("Shipped Qty. Not Returned", '<=%1', -MaxToApply2);
        ItemLedgerEntry2.SetLoadFields("Shipped Qty. Not Returned", "Remaining Quantity");
        if ItemLedgerEntry2.FindSet() then
            repeat
                if CostAvailable(ItemLedgerEntry2) <> 0 then
                    if not ItemApplicationEntry.ExistsBetween(ItemLedgerEntry."Entry No.", ItemLedgerEntry2."Entry No.") then
                        InsertTempEntry(ItemLedgerEntry2."Entry No.", 0, true);
            until ItemLedgerEntry2.Next() = 0;
    end;

    local procedure InsertTempEntry(EntryNo: Integer; AppliedQty: Decimal; ShowQuantity2: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        ItemLedgerEntry.Get(EntryNo);

        IsHandled := false;
        OnBeforeInsertTempEntry(ItemLedgerEntry, AppliedQty, ShowQuantity2, TotalApplied, TempItemLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        if ShowQuantity2 then
            if AppliedQty * ItemLedgerEntry.Quantity < 0 then
                exit;

        if not TempItemLedgerEntry.Get(EntryNo) then begin
            TempItemLedgerEntry.Reset();
            TempItemLedgerEntry := ItemLedgerEntry;
            TempItemLedgerEntry.CalcFields("Reserved Quantity");
            TempItemLedgerEntry.Quantity := AppliedQty;
            TempItemLedgerEntry.Insert();
        end else begin
            TempItemLedgerEntry.Quantity := TempItemLedgerEntry.Quantity + AppliedQty;
            TempItemLedgerEntry.Modify();
        end;

        TotalApplied := TotalApplied + AppliedQty;
    end;

    local procedure InitApplied()
    begin
        Clear(TotalApplied);
    end;

    local procedure RemoveApplications(Inbound: Integer; OutBound: Integer)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", Inbound);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", OutBound);
        if ItemApplicationEntry.FindSet() then
            repeat
                ItemJnlPostLine.UnApply(ItemApplicationEntry);
                ItemJnlPostLine.LogUnapply(ItemApplicationEntry);
            until ItemApplicationEntry.Next() = 0;
    end;

    local procedure UnapplyRec()
    var
        ItemLedgerEntryToApply: Record "Item Ledger Entry";
        AppliedItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntryToApply.Get(ItemLedgerEntryToShow."Entry No.");
        CurrPage.SetSelectionFilter(TempItemLedgerEntry);
        if TempItemLedgerEntry.FindSet() then begin
            repeat
                AppliedItemLedgerEntry.Get(TempItemLedgerEntry."Entry No.");
                if AppliedItemLedgerEntry."Entry No." <> 0 then
                    if ItemLedgerEntryToApply.Positive then
                        RemoveApplications(ItemLedgerEntryToApply."Entry No.", AppliedItemLedgerEntry."Entry No.")
                    else
                        RemoveApplications(AppliedItemLedgerEntry."Entry No.", ItemLedgerEntryToApply."Entry No.");
            until TempItemLedgerEntry.Next() = 0;

            BlockItem(ItemLedgerEntryToApply."Item No.");
        end;

        Show();
    end;

    procedure ApplyRec()
    var
        ItemLedgerEntryToApply: Record "Item Ledger Entry";
        AppliedItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntryToApply.Get(ItemLedgerEntryToShow."Entry No.");
        CurrPage.SetSelectionFilter(TempItemLedgerEntry);
        if TempItemLedgerEntry.FindSet() then
            repeat
                AppliedItemLedgerEntry.Get(TempItemLedgerEntry."Entry No.");
                if AppliedItemLedgerEntry."Entry No." <> 0 then begin
                    ItemJnlPostLine.ReApply(ItemLedgerEntryToApply, AppliedItemLedgerEntry."Entry No.");
                    ItemJnlPostLine.LogApply(ItemLedgerEntryToApply, AppliedItemLedgerEntry);
                end;
            until TempItemLedgerEntry.Next() = 0;

        if ItemLedgerEntryToApply.Positive then
            RemoveDuplicateApplication(ItemLedgerEntryToApply."Entry No.");

        Show();
    end;

    local procedure RemoveDuplicateApplication(ItemLedgerEntryNo: Integer)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntryNo);
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>0');
        if not ItemApplicationEntry.IsEmpty() then begin
            ItemApplicationEntry.SetRange("Outbound Item Entry No.", 0);
            ItemApplicationEntry.DeleteAll();
        end
    end;

    local procedure BlockItem(ItemNo: Code[20])
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlockItem(ItemNo, IsHandled);
        if IsHandled then
            exit;

        Item.Get(ItemNo);
        if Item."Application Wksh. User ID" <> UpperCase(UserId) then
            Item.CheckBlockedByApplWorksheet();

        Item."Application Wksh. User ID" := CopyStr(UserId(), 1, MaxStrLen(Item."Application Wksh. User ID"));
        Item.Modify(true);
    end;

    local procedure GetApplQty()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(Rec."Entry No.");
        ApplQty := Rec.Quantity;
        Qty := ItemLedgerEntry.Quantity;
    end;

    local procedure QuantityAvailable(ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    begin
        ItemLedgerEntry.CalcFields("Reserved Quantity");
        exit(ItemLedgerEntry."Remaining Quantity" - ItemLedgerEntry."Reserved Quantity");
    end;

    local procedure CostAvailable(ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if ItemLedgerEntry."Shipped Qty. Not Returned" <> 0 then
            exit(-ItemLedgerEntry."Shipped Qty. Not Returned");

        exit(ItemLedgerEntry."Remaining Quantity" + ItemApplicationEntry.Returned(ItemLedgerEntry."Entry No."));
    end;

    procedure CaptionExpr(): Text
    begin
        if ShowApplied then
            exit(AppliedEntriesLbl);

        exit(UnappliedEntriesLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlockItem(ItemNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempEntry(ItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal; ShowQuantity: Boolean; var TotalApplied: Decimal; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}

