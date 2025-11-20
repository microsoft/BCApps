// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Inventory.Costing;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;
using System.Globalization;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Setup;

table 339 "Item Application Entry"
{
    Caption = 'Item Application Entry';
    DrillDownPageID = "Item Application Entries";
    LookupPageID = "Item Application Entries";
    Permissions = TableData "Item Application Entry" = rim,
                  TableData "Item Application Entry History" = ri;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(3; "Inbound Item Entry No."; Integer)
        {
            Caption = 'Inbound Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(4; "Outbound Item Entry No."; Integer)
        {
            Caption = 'Outbound Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(20; "Item Register No."; Integer)
        {
            Caption = 'Item Register No.';
            Editable = false;
            TableRelation = "Item Register";
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(23; "Transferred-from Entry No."; Integer)
        {
            Caption = 'Transferred-from Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(25; "Creation Date"; DateTime)
        {
            Caption = 'Creation Date';
        }
        field(26; "Created By User"; Code[50])
        {
            Caption = 'Created By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(27; "Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
        }
        field(28; "Last Modified By User"; Code[50])
        {
            Caption = 'Last Modified By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(101; "Item No."; Code[20])
        {
            CalcFormula = lookup("Item Ledger Entry"."Item No." where("Entry No." = field("Item Ledger Entry No.")));
            Caption = 'Item No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(102; "Location Code"; Code[10])
        {
            CalcFormula = lookup("Item Ledger Entry"."Location Code" where("Entry No." = field("Item Ledger Entry No.")));
            Caption = 'Location Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(103; "Variant Code"; Code[10])
        {
            CalcFormula = lookup("Item Ledger Entry"."Variant Code" where("Entry No." = field("Item Ledger Entry No.")));
            Caption = 'Variant Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(111; "Latest Valuation Date"; Date)
        {
            CalcFormula = max("Value Entry"."Valuation Date" where("Item Ledger Entry No." = field("Item Ledger Entry No.")));
            Caption = 'Latest Valuation Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5800; "Cost Application"; Boolean)
        {
            Caption = 'Cost Application';
        }
        field(5804; "Output Completely Invd. Date"; Date)
        {
            Caption = 'Output Completely Invd. Date';
        }
        field(5805; "Outbound Entry is Updated"; Boolean)
        {
            Caption = 'Outbound Entry is Updated';
            InitValue = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Posting Date", "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application")
        {
            IncludedFields = Quantity, "Transferred-from Entry No.", "Output Completely Invd. Date", "Outbound Entry is Updated";
        }
        key(Key3; "Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application", "Transferred-from Entry No.")
        {
            IncludedFields = "Posting Date", Quantity, "Inbound Item Entry No.", "Output Completely Invd. Date", "Outbound Entry is Updated";
        }
        key(Key4; "Transferred-from Entry No.", "Cost Application")
        {
            IncludedFields = "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", Quantity, "Posting Date", "Output Completely Invd. Date", "Outbound Entry is Updated";
        }
        key(Key5; "Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application")
        {
            IncludedFields = "Item Ledger Entry No.", Quantity, "Posting Date", "Transferred-from Entry No.", "Output Completely Invd. Date", "Outbound Entry is Updated";
        }
        key(Key6; "Item Ledger Entry No.", "Output Completely Invd. Date")
        {
            IncludedFields = "Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application", Quantity, "Posting Date", "Transferred-from Entry No.", "Outbound Entry is Updated";
        }
        key(Key9; "Inbound Item Entry No.", "Transferred-from Entry No.", "Item Ledger Entry No.")
        {
            IncludedFields = "Outbound Item Entry No.", "Cost Application", Quantity, "Posting Date", "Output Completely Invd. Date", "Outbound Entry is Updated";
        }
        key(Key10; "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application")
        {
            IncludedFields = Quantity, "Posting Date", "Transferred-from Entry No.", "Output Completely Invd. Date", "Outbound Entry is Updated";
        }
    }

    fieldgroups
    {
    }

    var
        TempVisitedItemApplicationEntry: Record "Item Application Entry" temporary;
        TempItemLedgerEntryInChainNo: Record "Integer" temporary;
#if not CLEAN27
        SearchedItemLedgerEntry: Record "Item Ledger Entry";
#endif
        TrackChain: Boolean;
        MaxValuationDate: Date;
        AppliedFromEntryToAdjustErr: Label 'You have to run the %1 batch job, before you can revalue %2 %3.', Comment = '%1 = Report::"Adjust Cost - Item Entries", %2 = Item Ledger Entry table caption, %3 = Inbound Item Ledger Entry No.';

    [InherentPermissions(PermissionObjectType::TableData, Database::"Item Application Entry", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Item Application Entry"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Item Application Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure AppliedOutbndEntryExists(InbndItemLedgEntryNo: Integer; IsCostApplication: Boolean; FilterOnOnlyCostNotAdjusted: Boolean): Boolean
    begin
        Reset();
        SetCurrentKey(
          "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        SetFilter("Item Ledger Entry No.", '<>%1', InbndItemLedgEntryNo);
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        if IsCostApplication then
            SetRange("Cost Application", true);

        if FilterOnOnlyCostNotAdjusted then
            SetRange("Outbound Entry is Updated", false);

        exit(FindSet());
    end;

    procedure AppliedOutbndEntryExists(var ItemApplicationEntries: Query "Item Application Entries"; InbndItemLedgEntryNo: Integer; IsCostApplication: Boolean; FilterOnOnlyCostNotAdjusted: Boolean): Boolean
    begin
        ItemApplicationEntries.SetRange(Inbound_Item_Entry_No, InbndItemLedgEntryNo);
        ItemApplicationEntries.SetFilter(Item_Ledger_Entry_No, '<>%1', InbndItemLedgEntryNo);
        ItemApplicationEntries.SetFilter(Outbound_Item_Entry_No, '<>0');
        if IsCostApplication then
            ItemApplicationEntries.SetRange(Cost_Application, true);
        if FilterOnOnlyCostNotAdjusted then
            ItemApplicationEntries.SetRange(Outbound_Entry_is_Updated, false);

        ItemApplicationEntries.Open();
        exit(ItemApplicationEntries.Read());
    end;

    procedure AppliedInbndTransEntryExists(InbndItemLedgEntryNo: Integer; IsCostApplication: Boolean): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetLoadFields(Positive, "Item No.");
        if not ItemLedgerEntry.Get(InbndItemLedgEntryNo) then
            exit(false);
        if not ItemLedgerEntry.Positive then
            exit(false);
        if not IsItemEntryTypeEverPosted(ItemLedgerEntry."Item No.", "Item Ledger Entry Type"::Transfer) then
            exit(false);

        Reset();
        SetCurrentKey("Transferred-from Entry No.", "Cost Application");
        SetRange("Transferred-from Entry No.", InbndItemLedgEntryNo);
        SetRange("Cost Application", IsCostApplication, true);
        if IsEmpty() then
            exit(false);

        FindSet();
        exit(true);
    end;

    procedure AppliedInbndTransEntryExists(var ItemApplicationEntries: Query "Item Application Entries"; InbndItemLedgEntryNo: Integer; IsCostApplication: Boolean): Boolean
    begin
        ItemApplicationEntries.SetRange(Transferred_from_Entry_No, InbndItemLedgEntryNo);
        ItemApplicationEntries.SetRange(Cost_Application, IsCostApplication, true);
        ItemApplicationEntries.Open();
        exit(ItemApplicationEntries.Read());
    end;

    procedure AppliedInbndEntryExists(OutbndItemLedgEntryNo: Integer; IsCostApplication: Boolean): Boolean
    begin
        Reset();
        SetCurrentKey(
          "Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application", "Transferred-from Entry No.");
        SetRange("Outbound Item Entry No.", OutbndItemLedgEntryNo);
        SetFilter("Item Ledger Entry No.", '<>%1', OutbndItemLedgEntryNo);
        SetRange("Transferred-from Entry No.", 0);
        if IsCostApplication then
            SetRange("Cost Application", true);
        exit(FindSet());
    end;

    procedure AppliedInbndEntryExists(var ItemApplicationEntries: Query "Item Application Entries"; OutbndItemLedgEntryNo: Integer; IsCostApplication: Boolean): Boolean
    begin
        ItemApplicationEntries.SetRange(Outbound_Item_Entry_No, OutbndItemLedgEntryNo);
        ItemApplicationEntries.SetFilter(Item_Ledger_Entry_No, '<>%1', OutbndItemLedgEntryNo);
        ItemApplicationEntries.SetRange(Transferred_from_Entry_No, 0);
        if IsCostApplication then
            ItemApplicationEntries.SetRange(Cost_Application, true);

        ItemApplicationEntries.Open();
        exit(ItemApplicationEntries.Read());
    end;

    procedure AppliedFromEntryExists(InbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        SetRange("Item Ledger Entry No.", InbndItemLedgEntryNo);
        exit(FindSet());
    end;

    procedure GetInboundEntriesTheOutbndEntryAppliedTo(OutbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        SetRange("Outbound Item Entry No.", OutbndItemLedgEntryNo);
        SetRange("Item Ledger Entry No.", OutbndItemLedgEntryNo);
        SetFilter("Inbound Item Entry No.", '<>%1', 0);
        exit(FindSet());
    end;

    procedure GetOutboundEntriesAppliedToTheInboundEntry(InbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        SetFilter("Item Ledger Entry No.", '<>%1', InbndItemLedgEntryNo);
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        exit(FindSet());
    end;

    procedure CheckAppliedFromEntryToAdjust(InbndItemLedgEntryNo: Integer)
    var
        OutbndItemLedgerEntry: Record "Item Ledger Entry";
        ObjTransl: Record "Object Translation";
    begin
        if AppliedFromEntryExists(InbndItemLedgEntryNo) then
            repeat
                OutbndItemLedgerEntry.SetLoadFields("Applied Entry to Adjust");
                OutbndItemLedgerEntry.Get("Outbound Item Entry No.");
                if OutbndItemLedgerEntry."Applied Entry to Adjust" then
                    Error(
                      AppliedFromEntryToAdjustErr,
                      ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, Report::"Adjust Cost - Item Entries"),
                      OutbndItemLedgerEntry.TableCaption(), InbndItemLedgEntryNo);
            until Next() = 0;
    end;

    procedure CostReceiver(): Integer
    begin
        if "Outbound Item Entry No." = 0 then
            exit(0);
        if "Item Ledger Entry No." = "Outbound Item Entry No." then
            exit("Outbound Item Entry No.");
        if "Item Ledger Entry No." = "Inbound Item Entry No." then
            exit("Inbound Item Entry No.");
        exit(0);
    end;

    procedure "Fixed"() Result: Boolean
    var
        InboundItemLedgerEntry: Record "Item Ledger Entry";
        OutboundItemLedgerEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        OnBeforeFixed(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Outbound Item Entry No." = 0 then
            exit(false);
        InboundItemLedgerEntry.SetLoadFields("Applies-to Entry");
        if not InboundItemLedgerEntry.Get("Inbound Item Entry No.") then
            exit(true);
        if InboundItemLedgerEntry."Applies-to Entry" = "Outbound Item Entry No." then
            exit(true);
        OutboundItemLedgerEntry.SetLoadFields("Applies-to Entry");
        if not OutboundItemLedgerEntry.Get("Outbound Item Entry No.") then
            exit(true);
        if OutboundItemLedgerEntry."Applies-to Entry" = "Inbound Item Entry No." then
            exit(true);
        exit(false);
    end;

    procedure InsertHistory(): Integer
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
        InventorySetup: Record "Inventory Setup";
        EntryNo: Integer;
    begin
        if InventorySetup.UseLegacyPosting() then begin
            ItemApplicationEntryHistory.SetCurrentKey("Primary Entry No.");
            if ItemApplicationEntryHistory.FindLast() then
                EntryNo := ItemApplicationEntryHistory."Primary Entry No.";
            EntryNo += 1;
        end else
            EntryNo := ItemApplicationEntryHistory.GetNextEntryNo();
        ItemApplicationEntryHistory.TransferFields(Rec, true);
        ItemApplicationEntryHistory."Deleted Date" := CurrentDateTime();
        ItemApplicationEntryHistory."Deleted By User" := CopyStr(UserId(), 1, MaxStrLen(ItemApplicationEntryHistory."Deleted By User"));
        ItemApplicationEntryHistory."Primary Entry No." := EntryNo;
        ItemApplicationEntryHistory.Insert(true);
        exit(ItemApplicationEntryHistory."Primary Entry No.");
    end;

    procedure CostApplication(): Boolean
    begin
        exit((Quantity > 0) and ("Item Ledger Entry No." = "Inbound Item Entry No."))
    end;

    procedure CheckIsCyclicalLoop(CheckItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        IsCyclicalLoop: Boolean;
    begin
        if CheckItemLedgEntry."Entry No." = FromItemLedgEntry."Entry No." then
            exit(true);
        TempVisitedItemApplicationEntry.DeleteAll();
        TempItemLedgerEntryInChainNo.DeleteAll();

        if FromItemLedgEntry.Positive then begin
            if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry, FromItemLedgEntry."Entry No.") then
                exit(true);
            exit(CheckCyclicFwdToInbndTransfers(CheckItemLedgEntry, FromItemLedgEntry."Entry No."));
        end;
        if FromItemLedgEntry."Entry Type" = FromItemLedgEntry."Entry Type"::Consumption then
            if CheckCyclicProdCyclicalLoop(CheckItemLedgEntry, FromItemLedgEntry) then
                exit(true);
        if FromItemLedgEntry."Entry Type" = FromItemLedgEntry."Entry Type"::"Assembly Consumption" then
            if CheckCyclicAsmCyclicalLoop(CheckItemLedgEntry, FromItemLedgEntry) then
                exit(true);

        IsCyclicalLoop := false;
        OnCheckIsCyclicalLoopOnBeforeCheckCyclicForwardToAppliedInbounds(CheckItemLedgEntry, FromItemLedgEntry, MaxValuationDate, IsCyclicalLoop);
        if IsCyclicalLoop then
            exit(true);

        exit(CheckCyclicFwdToAppliedInbnds(CheckItemLedgEntry, FromItemLedgEntry."Entry No."));
    end;

    local procedure CheckCyclicProdCyclicalLoop(CheckItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeCheckCyclicProdCyclicalLoop(Rec, CheckItemLedgerEntry, ItemLedgerEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not IsItemEntryTypeEverPosted(ItemLedgerEntry."Item No.", "Item Ledger Entry Type"::Output) then
            exit(false);

        if ItemLedgerEntry."Order Type" <> ItemLedgerEntry."Order Type"::Production then
            exit(false);
        if ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::Output then
            exit(false);
        if ItemLedgerEntry.Positive then
            exit(false);
        if (CheckItemLedgerEntry."Entry Type" = CheckItemLedgerEntry."Entry Type"::Output) and
           (ItemLedgerEntry."Order Type" = CheckItemLedgerEntry."Order Type") and
           (ItemLedgerEntry."Order No." = CheckItemLedgerEntry."Order No.") and
           (ItemLedgerEntry."Order Line No." = CheckItemLedgerEntry."Order Line No.")
        then
            exit(true);

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type");
        ItemLedgerEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ItemLedgerEntry.SetRange("Order Line No.", ItemLedgerEntry."Order Line No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        exit(CheckCyclicOrderCyclicalLoop(CheckItemLedgerEntry, ItemLedgerEntry));
    end;

    local procedure CheckCyclicAsmCyclicalLoop(CheckItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeCheckCyclicAsmCyclicalLoop(Rec, CheckItemLedgerEntry, ItemLedgerEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not IsItemEntryTypeEverPosted(ItemLedgerEntry."Item No.", "Item Ledger Entry Type"::"Assembly Output") then
            exit(false);

        if ItemLedgerEntry."Order Type" <> ItemLedgerEntry."Order Type"::Assembly then
            exit(false);
        if ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::"Assembly Output" then
            exit(false);
        if ItemLedgerEntry.Positive then
            exit(false);
        if (CheckItemLedgerEntry."Entry Type" = CheckItemLedgerEntry."Entry Type"::"Assembly Output") and
           (ItemLedgerEntry."Order Type" = CheckItemLedgerEntry."Order Type") and
           (ItemLedgerEntry."Order No." = CheckItemLedgerEntry."Order No.")
        then
            exit(true);

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type");
        ItemLedgerEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Output");
        exit(CheckCyclicOrderCyclicalLoop(CheckItemLedgerEntry, ItemLedgerEntry));
    end;

    local procedure CheckCyclicOrderCyclicalLoop(CheckItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    begin
        if MaxValuationDate <> 0D then
            ItemLedgerEntry.SetRange("Posting Date", 0D, MaxValuationDate);
        ItemLedgerEntry.SetLoadFields(Positive);
        if ItemLedgerEntry.FindSet() then
            repeat
                if TrackChain then begin
                    TempItemLedgerEntryInChainNo.Number := ItemLedgerEntry."Entry No.";
                    if TempItemLedgerEntryInChainNo.Insert() then;
                end;

                if ItemLedgerEntry."Entry No." = CheckItemLedgerEntry."Entry No." then
                    exit(true);

                if ItemLedgerEntry.Positive then
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgerEntry, ItemLedgerEntry."Entry No.") then
                        exit(true);
            until ItemLedgerEntry.Next() = 0;
        exit(false);
    end;

    local procedure CheckCyclicFwdToAppliedOutbnds(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplicationEntries: Query "Item Application Entries";
    begin
        if AppliedOutbndEntryExists(ItemApplicationEntries, EntryNo, false, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgerEntry, ItemApplicationEntries, EntryNo, true));

        exit(false);
    end;

    local procedure CheckCyclicFwdToAppliedInbnds(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplicationEntries: Query "Item Application Entries";
    begin
        if AppliedInbndEntryExists(ItemApplicationEntries, EntryNo, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgerEntry, ItemApplicationEntries, EntryNo, false));

        exit(false);
    end;

    local procedure CheckCyclicFwdToInbndTransfers(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplicationEntries: Query "Item Application Entries";
    begin
        if AppliedInbndTransEntryExists(ItemApplicationEntries, EntryNo, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgerEntry, ItemApplicationEntries, EntryNo, false));

        exit(false);
    end;

    local procedure CheckCyclicFwdToProdOutput(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not ItemLedgerEntry.Get(EntryNo) then
            exit(false);
        exit(CheckCyclicProdCyclicalLoop(CheckItemLedgerEntry, ItemLedgerEntry));
    end;

    local procedure CheckCyclicFwdToAsmOutput(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not ItemLedgerEntry.Get(EntryNo) then
            exit(false);
        exit(CheckCyclicAsmCyclicalLoop(CheckItemLedgerEntry, ItemLedgerEntry));
    end;

    local procedure CheckCyclicFwdToAppliedEntries(CheckItemLedgerEntry: Record "Item Ledger Entry"; var ItemApplicationEntries: Query "Item Application Entries"; FromEntryNo: Integer; IsPositiveToNegativeFlow: Boolean): Boolean
    var
        ToEntryNo: Integer;
        IsCyclicalLoop: Boolean;
    begin
        if EntryIsVisited(FromEntryNo) then
            exit(false);

        repeat
            if IsPositiveToNegativeFlow then
                ToEntryNo := ItemApplicationEntries.Outbound_Item_Entry_No
            else
                ToEntryNo := ItemApplicationEntries.Inbound_Item_Entry_No;

            if CheckLatestItemLedgerEntryValuationDate(ItemApplicationEntries.Item_Ledger_Entry_No, MaxValuationDate) then begin
                if TrackChain then begin
                    TempItemLedgerEntryInChainNo.Number := ToEntryNo;
                    if TempItemLedgerEntryInChainNo.Insert() then;
                end;

                if ToEntryNo = CheckItemLedgerEntry."Entry No." then
                    exit(true);

                if not IsPositiveToNegativeFlow then begin
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgerEntry, ToEntryNo) then
                        exit(true);
                end else begin
                    if CheckCyclicFwdToAppliedInbnds(CheckItemLedgerEntry, ToEntryNo) then
                        exit(true);
                    if CheckCyclicFwdToProdOutput(CheckItemLedgerEntry, ToEntryNo) then
                        exit(true);
                    if CheckCyclicFwdToAsmOutput(CheckItemLedgerEntry, ToEntryNo) then
                        exit(true);
                end;

                IsCyclicalLoop := false;
                OnCheckCyclicFwdToAppliedEntriesOnAfterCheckItemApplicationEntry(CheckItemLedgerEntry, ToEntryNo, IsPositiveToNegativeFlow, IsCyclicalLoop);
                if IsCyclicalLoop then
                    exit(true);
            end;
        until not ItemApplicationEntries.Read();

        if IsPositiveToNegativeFlow then
            exit(CheckCyclicFwdToInbndTransfers(CheckItemLedgerEntry, FromEntryNo));
        exit(false);
    end;

    local procedure EntryIsVisited(EntryNo: Integer): Boolean
    begin
        if TempVisitedItemApplicationEntry.Get(EntryNo) then begin
            // This is to take into account quantity flows from an inbound entry to an inbound transfer
            if TempVisitedItemApplicationEntry.Quantity = 2 then
                exit(true);
            TempVisitedItemApplicationEntry.Quantity := TempVisitedItemApplicationEntry.Quantity + 1;
            TempVisitedItemApplicationEntry.Modify();
            exit(false);
        end;
        TempVisitedItemApplicationEntry.Init();
        TempVisitedItemApplicationEntry."Entry No." := EntryNo;
        TempVisitedItemApplicationEntry.Quantity := TempVisitedItemApplicationEntry.Quantity + 1;
        TempVisitedItemApplicationEntry.Insert();
        exit(false);
    end;

    procedure GetVisitedEntries(FromItemLedgEntry: Record "Item Ledger Entry"; var ItemLedgEntryInChain: Record "Item Ledger Entry"; WithinValuationDate: Boolean)
    var
        ToItemLedgerEntry: Record "Item Ledger Entry";
        DummyItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        MaxValuationDate := 0D;
        if WithinValuationDate then begin
            ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Valuation Date");
            ValueEntry.SetRange("Item Ledger Entry No.", FromItemLedgEntry."Entry No.");
            ValueEntry.SetLoadFields("Valuation Date");
            ValueEntry.FindLast();
            MaxValuationDate := AvgCostEntryPointHandler.GetMaxValuationDate(FromItemLedgEntry, ValueEntry);
        end;

        TrackChain := true;
        ItemLedgEntryInChain.Reset();
        ItemLedgEntryInChain.DeleteAll();
        DummyItemLedgerEntry.Init();
        DummyItemLedgerEntry."Entry No." := -1;
        CheckIsCyclicalLoop(DummyItemLedgerEntry, FromItemLedgEntry);
        if TempItemLedgerEntryInChainNo.FindSet() then
            repeat
                ToItemLedgerEntry.Get(TempItemLedgerEntryInChainNo.Number);
                ItemLedgEntryInChain := ToItemLedgerEntry;
                ItemLedgEntryInChain.Insert();
            until TempItemLedgerEntryInChainNo.Next() = 0;
    end;

    procedure OutboundApplied(EntryNo: Integer; SameType: Boolean): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        OriginalItemLedgerEntry: Record "Item Ledger Entry";
        CalcQuantity: Decimal;
    begin
        OriginalItemLedgerEntry.SetLoadFields("Entry Type");
        if not OriginalItemLedgerEntry.Get(EntryNo) then
            exit(0);
        if OriginalItemLedgerEntry."Entry Type" = OriginalItemLedgerEntry."Entry Type"::Transfer then
            exit(0);

        ItemApplicationEntry.SetCurrentKey("Outbound Item Entry No.");
        ItemApplicationEntry.SetLoadFields("Inbound Item Entry No.", Quantity);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", EntryNo);
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", EntryNo);
        CalcQuantity := 0;
        if ItemApplicationEntry.FindSet() then
            repeat
                ItemLedgerEntry.SetLoadFields("Entry Type");
                if ItemLedgerEntry.Get(ItemApplicationEntry."Inbound Item Entry No.") then
                    if SameType then begin
                        if ItemLedgerEntry."Entry Type" = OriginalItemLedgerEntry."Entry Type" then
                            CalcQuantity := CalcQuantity + ItemApplicationEntry.Quantity
                    end else
                        CalcQuantity := CalcQuantity + ItemApplicationEntry.Quantity;
            until ItemApplicationEntry.Next() <= 0;
        exit(CalcQuantity);
    end;

    procedure InboundApplied(EntryNo: Integer; SameType: Boolean): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        OriginalItemLedgerEntry: Record "Item Ledger Entry";
        CalcQuantity: Decimal;
    begin
        OriginalItemLedgerEntry.SetLoadFields("Entry Type", Positive);
        if not OriginalItemLedgerEntry.Get(EntryNo) then
            exit(0);
        if OriginalItemLedgerEntry."Entry Type" = OriginalItemLedgerEntry."Entry Type"::Transfer then
            exit(0);

        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        ItemApplicationEntry.SetLoadFields("Outbound Item Entry No.", Quantity);
        ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", EntryNo);
        if not OriginalItemLedgerEntry.Positive then
            ItemApplicationEntry.SetRange("Item Ledger Entry No.", EntryNo);
        CalcQuantity := 0;
        if ItemApplicationEntry.FindSet() then
            repeat
                ItemLedgerEntry.SetLoadFields("Entry Type", "Applies-to Entry");
                if ItemLedgerEntry.Get(ItemApplicationEntry."Outbound Item Entry No.") then
                    if SameType then begin
                        if (ItemLedgerEntry."Entry Type" = OriginalItemLedgerEntry."Entry Type") or
                           (ItemLedgerEntry."Applies-to Entry" <> 0)
                        then
                            CalcQuantity := CalcQuantity + ItemApplicationEntry.Quantity
                    end else
                        CalcQuantity := CalcQuantity + ItemApplicationEntry.Quantity;
            until ItemApplicationEntry.Next() = 0;
        exit(CalcQuantity);
    end;

    procedure Returned(EntryNo: Integer): Decimal
    begin
        exit(-OutboundApplied(EntryNo, true) - InboundApplied(EntryNo, true));
    end;

    procedure ExistsBetween(ILE1: Integer; ILE2: Integer): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ILE1);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ILE2);
        if not ItemApplicationEntry.IsEmpty() then
            exit(true);

        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ILE2);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ILE1);
        exit(not ItemApplicationEntry.IsEmpty());
    end;

    local procedure IsItemEntryTypeEverPosted(ItemNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Entry Type"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", "Entry Type");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        exit(not ItemLedgerEntry.IsEmpty());
    end;

    procedure SetOutboundsNotUpdated(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if not (ItemLedgEntry."Applied Entry to Adjust" or ItemLedgEntry.Open) then
            exit;

        if ItemLedgEntry.Quantity < 0 then
            exit;

        ItemApplicationEntry.ReadIsolation(IsolationLevel::ReadCommitted);
        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.");
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgEntry."Entry No.");
        OnSetOutboundsNotUpdatedOnAfterSetFilters(ItemApplicationEntry);
        ItemApplicationEntry.SetRange("Outbound Entry is Updated", true);
        if not ItemApplicationEntry.IsEmpty() then
            ItemApplicationEntry.ModifyAll("Outbound Entry is Updated", false);
    end;

    procedure SetInboundToUpdated(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetCurrentKey("Outbound Item Entry No.");
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgEntry."Entry No.");
        OnSetInboundToUpdatedOnAfterSetFilters(ItemApplicationEntry);
        if ItemLedgEntry."Completely Invoiced" then
            if ItemApplicationEntry.Count() = 1 then begin
                ItemApplicationEntry.FindFirst();
                ItemApplicationEntry."Outbound Entry is Updated" := true;
                ItemApplicationEntry.Modify();
            end;
    end;

    procedure IsAppliedFromIncrease(InbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey(
          "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        SetRange("Item Ledger Entry No.", InbndItemLedgEntryNo);
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        SetRange("Cost Application", true);
        exit(FindFirst());
    end;

    procedure IsOutbndItemApplEntryCostApplication(OutboundItemLedgEntryNo: Integer): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", OutboundItemLedgEntryNo);
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", OutboundItemLedgEntryNo);
        ItemApplicationEntry.SetRange("Cost Application", false);
        exit(ItemApplicationEntry.IsEmpty());
    end;

    local procedure CheckLatestItemLedgerEntryValuationDate(ItemLedgerEntryNo: Integer; MaxDate: Date): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        if MaxDate = 0D then
            exit(true);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Valuation Date");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.SetLoadFields("Valuation Date");
        ValueEntry.FindLast();
        exit(ValueEntry."Valuation Date" <= MaxDate);
    end;

#if not CLEAN27
    [Obsolete('The optimization that used this function was obsoleted.', '27.0')]
    procedure SetSearchedItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        SearchedItemLedgerEntry.Copy(ItemLedgerEntry);
    end;
#endif

    procedure SetCostApplication(NewCostApplication: Boolean)
    begin
        if NewCostApplication <> "Cost Application" then begin
            "Cost Application" := NewCostApplication;
            Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFixed(ItemApplicationEntry: Record "Item Application Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetInboundToUpdatedOnAfterSetFilters(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCyclicProdCyclicalLoop(var ItemApplicationEntry: Record "Item Application Entry"; CheckItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCyclicAsmCyclicalLoop(var ItemApplicationEntry: Record "Item Application Entry"; CheckItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOutboundsNotUpdatedOnAfterSetFilters(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckIsCyclicalLoopOnBeforeCheckCyclicForwardToAppliedInbounds(CheckItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"; MaxValuationDate: Date; var IsCyclicalLoop: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckCyclicFwdToAppliedEntriesOnAfterCheckItemApplicationEntry(CheckItemLedgerEntry: Record "Item Ledger Entry"; ToEntryNo: Integer; IsPositiveToNegativeFlow: Boolean; var IsCyclicalLoop: Boolean)
    begin
    end;
}

