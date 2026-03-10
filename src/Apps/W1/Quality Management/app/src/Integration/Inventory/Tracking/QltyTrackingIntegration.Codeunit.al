// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Activity;
using System.IO;

codeunit 20415 "Qlty. Tracking Integration"
{
    InherentPermissions = X;

    var
        EntryTypeBlockedErr: Label 'This transaction was blocked because the quality inspection %1 has the result of %2 for item %4 with tracking %5, which is configured to disallow the transaction "%3". You can change whether this transaction is allowed by navigating to Quality Inspection Results.', Comment = '%1=quality inspection, %2=result, %3=entry type being blocked, %4=item, %5=combined package tracking details of Lot No., Serial No. and Package No.';
        WarehouseEntryTypeBlockedErr: Label 'This warehouse transaction was blocked because the quality inspection %1 has the result of %2 for item %4 with tracking %5 %6 %7, which is configured to disallow the transaction "%3". You can change whether this transaction is allowed by navigating to Quality Inspection Results.', Comment = '%1=quality inspection, %2=result, %3=entry type being blocked, %4=item, %5=Lot No., %6=Serial No., %7=Package No.';
        NavigatePageSearchFiltersTok: Label 'NAVIGATEFILTERS', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterCheckItemTrackingInformation', '', true, true)]
    local procedure HandleOnAfterCheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup"; Item: Record Item)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        Blocked: Boolean;
        IsFinished: Boolean;
        IsHandled: Boolean;
        TrackingDetails: Text;
    begin
        case true of
            not QltyInspectionHeader.ReadPermission(),
            not QltyInspectionResult.ReadPermission(),
            not QltyManagementSetup.GetSetupRecord():
                exit;
        end;

        QltyInspectionHeader.SetRange("Source Item No.", ItemJnlLine2."Item No.");
        QltyInspectionHeader.SetRange("Source Variant Code", ItemJnlLine2."Variant Code");
        QltyInspectionHeader.SetRange("Source Lot No.", TrackingSpecification."Lot No.");
        QltyInspectionHeader.SetRange("Source Serial No.", TrackingSpecification."Serial No.");
        QltyInspectionHeader.SetRange("Source Package No.", TrackingSpecification."Package No.");
        OnCheckItemTrackingOnAfterSetFilters(ItemJnlLine2, TrackingSpecification, QltyInspectionHeader, IsHandled);
        if IsHandled then
            exit;

        case QltyManagementSetup."Inspection Selection Criteria" of
            QltyManagementSetup."Inspection Selection Criteria"::"Any inspection that matches":
                if not QltyInspectionHeader.FindSet() then
                    exit;
            QltyManagementSetup."Inspection Selection Criteria"::"Any finished inspection that matches":
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    if not QltyInspectionHeader.FindSet() then
                        exit;
                end;
            QltyManagementSetup."Inspection Selection Criteria"::"Only the newest inspection/re-inspection":
                begin
                    QltyInspectionHeader.SetCurrentKey("No.", "Re-inspection No.");
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Inspection Selection Criteria"::"Only the newest finished inspection/re-inspection":
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    QltyInspectionHeader.SetCurrentKey("No.", "Re-inspection No.");
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified inspection":
                begin
                    QltyInspectionHeader.SetCurrentKey(SystemModifiedAt);
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified finished inspection":
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    QltyInspectionHeader.SetCurrentKey(SystemModifiedAt);
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
        end;

        repeat
            if QltyInspectionHeader."Result Code" <> '' then begin
                IsFinished := QltyInspectionHeader.Status = QltyInspectionHeader.Status::Finished;
                if QltyInspectionResult.Get(QltyInspectionHeader."Result Code") then begin
                    case ItemJnlLine2."Entry Type" of
                        ItemJnlLine2."Entry Type"::"Assembly Consumption":
                            Blocked := (QltyInspectionResult."Item Tracking Allow Asm. Cons." = QltyInspectionResult."Item Tracking Allow Asm. Cons."::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Asm. Cons." = QltyInspectionResult."Item Tracking Allow Asm. Cons."::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::"Assembly Output":
                            Blocked := (QltyInspectionResult."Item Tracking Allow Asm. Out." = QltyInspectionResult."Item Tracking Allow Asm. Out."::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Asm. Out." = QltyInspectionResult."Item Tracking Allow Asm. Out."::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Consumption:
                            Blocked := (QltyInspectionResult."Item Tracking Allow Consump." = QltyInspectionResult."Item Tracking Allow Consump."::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Consump." = QltyInspectionResult."Item Tracking Allow Consump."::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Output:
                            Blocked := (QltyInspectionResult."Item Tracking Allow Output" = QltyInspectionResult."Item Tracking Allow Output"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Output" = QltyInspectionResult."Item Tracking Allow Output"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Purchase:
                            Blocked := (QltyInspectionResult."Item Tracking Allow Purchase" = QltyInspectionResult."Item Tracking Allow Purchase"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Purchase" = QltyInspectionResult."Item Tracking Allow Purchase"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Sale:
                            Blocked := (QltyInspectionResult."Item Tracking Allow Sales" = QltyInspectionResult."Item Tracking Allow Sales"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Sales" = QltyInspectionResult."Item Tracking Allow Sales"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Transfer:
                            Blocked := (QltyInspectionResult."Item Tracking Allow Transfer" = QltyInspectionResult."Item Tracking Allow Transfer"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Transfer" = QltyInspectionResult."Item Tracking Allow Transfer"::"Allow finished only"));
                    end;
                    OnHandleCheckItemTrackingBeforeBlockErrorCheck(ItemJnlLine2, TrackingSpecification, QltyInspectionHeader, QltyInspectionResult, Blocked);

                    if Blocked then begin
                        TrackingDetails := TrackingSpecification."Lot No.";
                        if TrackingSpecification."Serial No." <> '' then begin
                            if StrLen(TrackingDetails) > 0 then
                                TrackingDetails += ' ';
                            TrackingDetails += TrackingSpecification."Serial No.";
                        end;
                        if TrackingSpecification."Package No." <> '' then begin
                            if StrLen(TrackingDetails) > 0 then
                                TrackingDetails += ' ';
                            TrackingDetails += TrackingSpecification."Package No.";
                        end;
                        Error(EntryTypeBlockedErr,
                            QltyInspectionHeader.GetFriendlyIdentifier(),
                            QltyInspectionResult.Code,
                            ItemJnlLine2."Entry Type",
                            ItemJnlLine2."Item No.",
                            TrackingDetails);
                    end;
                end;
            end;
        until QltyInspectionHeader.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterCheckWhseActivLine', '', true, true)]
    local procedure HandleOnAfterCheckWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        CommonCheckWarehouseActivityLineIsAllowed(WarehouseActivityLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterCheckItemTrackingInfoBlocked', '', true, true)]
    local procedure HandleOnAfterCheckItemTrackingInfoBlocked(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        CommonCheckWarehouseActivityLineIsAllowed(WhseActivityLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnAfterCheckWarehouseActivityLine', '', true, true)]
    local procedure HandleOnAfterCheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location)
    begin
        CommonCheckWarehouseActivityLineIsAllowed(WarehouseActivityLine);
    end;

    local procedure CommonCheckWarehouseActivityLineIsAllowed(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        Blocked: Boolean;
        IsFinished: Boolean;
        IsHandled: Boolean;
    begin
        case true of
            not QltyInspectionHeader.ReadPermission(),
            not QltyInspectionResult.ReadPermission(),
            not QltyManagementSetup.GetSetupRecord():
                exit;
        end;

        QltyInspectionHeader.SetRange("Source Item No.", WarehouseActivityLine."Item No.");
        QltyInspectionHeader.SetRange("Source Variant Code", WarehouseActivityLine."Variant Code");
        QltyInspectionHeader.SetRange("Source Lot No.", WarehouseActivityLine."Lot No.");
        QltyInspectionHeader.SetRange("Source Serial No.", WarehouseActivityLine."Serial No.");
        QltyInspectionHeader.SetRange("Source Package No.", WarehouseActivityLine."Package No.");
        OnCheckWhseItemTrackingOnAfterSetFilters(WarehouseActivityLine, QltyInspectionHeader, IsHandled);
        if IsHandled then
            exit;

        case QltyManagementSetup."Inspection Selection Criteria" of
            QltyManagementSetup."Inspection Selection Criteria"::"Any inspection that matches":
                if not QltyInspectionHeader.FindSet() then
                    exit;
            QltyManagementSetup."Inspection Selection Criteria"::"Any finished inspection that matches":
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    if not QltyInspectionHeader.FindSet() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Inspection Selection Criteria"::"Only the newest inspection/re-inspection":
                begin
                    QltyInspectionHeader.SetCurrentKey("No.", "Re-inspection No.");
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Inspection Selection Criteria"::"Only the newest finished inspection/re-inspection":
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    QltyInspectionHeader.SetCurrentKey("No.", "Re-inspection No.");
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified inspection":
                begin
                    QltyInspectionHeader.SetCurrentKey(SystemModifiedAt);
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified finished inspection":
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);

                    QltyInspectionHeader.SetCurrentKey(SystemModifiedAt);
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
        end;

        repeat
            if QltyInspectionHeader."Result Code" <> '' then begin
                IsFinished := QltyInspectionHeader.Status = QltyInspectionHeader.Status::Finished;

                if QltyInspectionResult.Get(QltyInspectionHeader."Result Code") then begin
                    case WarehouseActivityLine."Activity Type" of
                        WarehouseActivityLine."Activity Type"::"Invt. Movement":
                            Blocked := (QltyInspectionResult."Item Tracking Allow Invt. Mov." = QltyInspectionResult."Item Tracking Allow Invt. Mov."::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Invt. Mov." = QltyInspectionResult."Item Tracking Allow Invt. Mov."::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::"Invt. Pick":
                            Blocked := (QltyInspectionResult."Item Tracking Allow Invt. Pick" = QltyInspectionResult."Item Tracking Allow Invt. Pick"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Invt. Pick" = QltyInspectionResult."Item Tracking Allow Invt. Pick"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::"Invt. Put-away":
                            Blocked := (QltyInspectionResult."Item Tracking Allow Invt. PA" = QltyInspectionResult."Item Tracking Allow Invt. PA"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Invt. PA" = QltyInspectionResult."Item Tracking Allow Invt. PA"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::Movement:
                            Blocked := (QltyInspectionResult."Item Tracking Allow Movement" = QltyInspectionResult."Item Tracking Allow Movement"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Movement" = QltyInspectionResult."Item Tracking Allow Movement"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::Pick:
                            Blocked := (QltyInspectionResult."Item Tracking Allow Pick" = QltyInspectionResult."Item Tracking Allow Pick"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Pick" = QltyInspectionResult."Item Tracking Allow Pick"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::"Put-away":
                            Blocked := (QltyInspectionResult."Item Tracking Allow Put-Away" = QltyInspectionResult."Item Tracking Allow Put-Away"::Block) or
                                (not IsFinished and (QltyInspectionResult."Item Tracking Allow Put-Away" = QltyInspectionResult."Item Tracking Allow Put-Away"::"Allow finished only"));
                    end;
                    OnHandleCheckWhseItemTrackingBeforeBlockErrorCheck(WarehouseActivityLine, QltyInspectionHeader, QltyInspectionResult, Blocked);

                    if Blocked then
                        Error(
                            WarehouseEntryTypeBlockedErr,
                            QltyInspectionHeader.GetFriendlyIdentifier(),
                            QltyInspectionResult.Code,
                            WarehouseActivityLine."Activity Type",
                            WarehouseActivityLine."Item No.",
                            WarehouseActivityLine."Lot No.",
                            WarehouseActivityLine."Serial No.",
                            WarehouseActivityLine."Package No.");
                end;
            end;
        until QltyInspectionHeader.Next() = 0;
    end;

    /// <summary>
    /// Used to help assist edits find item tracking numbers.
    /// In the context of Quality Inspections location doesn't really matter.
    /// Used as part of the AssistEdit Item Tracking Number functionality.
    /// </summary>
    /// <param name="ReservEntry"></param>
    /// <param name="TempTrackingSpecification"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnRetrieveLookupDataOnAfterReservEntrySetFilters', '', true, true)]
    local procedure HandleOnRetrieveLookupDataOnAfterReservEntrySetFilters(var ReservEntry: Record "Reservation Entry"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        if TempTrackingSpecification."Source Type" <> Database::"Qlty. Inspection Header" then
            exit;

        ReservEntry.SetRange("Location Code");

        if TempTrackingSpecification."Source ID" <> '' then
            ReservEntry.SetRange("Source ID", TempTrackingSpecification."Source ID");
    end;

    /// <summary>
    /// Used as part of the AssistEdit Item Tracking Number functionality.
    /// </summary>
    /// <param name="TempTrackingSpecification"></param>
    /// <param name="TempReservationEntry"></param>
    /// <param name="ItemLedgerEntry"></param>
    /// <param name="FullDataSet"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnRetrieveLookupDataOnBeforeTransferToTempRec', '', true, true)]
    local procedure HandleOnRetrieveLookupDataOnBeforeTransferToTempRec(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; var ItemLedgerEntry: Record "Item Ledger Entry"; var FullDataSet: Boolean)
    var
        PipeSeparatedPostedDocs: Text;
    begin
        if TempTrackingSpecification."Source Type" <> Database::"Qlty. Inspection Header" then
            exit;

        ItemLedgerEntry.SetRange("Location Code");

        if TempTrackingSpecification."Source ID" <> '' then begin
            PipeSeparatedPostedDocs := CollectFilterPipeSeparatedOfPostedDocuments(TempTrackingSpecification);
            ItemLedgerEntry.SetFilter("Document No.", TempTrackingSpecification."Source ID" + PipeSeparatedPostedDocs);
        end;
    end;

    /// <summary>
    /// Used to build a filter that can be used when restricting the document.
    /// </summary>
    /// <param name="TempTrackingSpecification"></param>
    /// <returns></returns>
    local procedure CollectFilterPipeSeparatedOfPostedDocuments(var TempTrackingSpecification: Record "Tracking Specification" temporary): Text
    var
        ItemEntryRelation: Record "Item Entry Relation";
        PreviousOrderNo: Text;
        PipeSeparatedOutputTextBuilder: TextBuilder;
    begin
        if TempTrackingSpecification."Source ID" <> '' then
            ItemEntryRelation.SetRange("Order No.", TempTrackingSpecification."Source ID");
        if TempTrackingSpecification."Source Ref. No." <> 0 then
            ItemEntryRelation.SetRange("Order Line No.", TempTrackingSpecification."Source Ref. No.");
        ItemEntryRelation.SetCurrentKey("Source ID");
        ItemEntryRelation.Ascending(true);
        ItemEntryRelation.SetAscending("Source ID", true);
        if ItemEntryRelation.FindSet() then begin
            repeat
                if ItemEntryRelation."Source ID" <> PreviousOrderNo then begin
                    PreviousOrderNo := ItemEntryRelation."Source ID";
                    PipeSeparatedOutputTextBuilder.Append('|');
                    PipeSeparatedOutputTextBuilder.Append(ItemEntryRelation."Source ID");
                end;
            until ItemEntryRelation.Next() = 0;

            exit(PipeSeparatedOutputTextBuilder.ToText());
        end;
    end;

    /// <summary>
    /// Used as part of the AssistEdit Item Tracking Number functionality.
    /// </summary>
    /// <param name="TempGlobalEntrySummary"></param>
    /// <param name="TempReservEntry"></param>
    /// <param name="TrackingSpecification"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnCreateEntrySummary2OnBeforeInsertOrModify', '', true, true)]
    local procedure HandleOnCreateEntrySummary2OnBeforeInsertOrModify(var TempGlobalEntrySummary: Record "Entry Summary" temporary; TempReservEntry: Record "Reservation Entry" temporary; TrackingSpecification: Record "Tracking Specification")
    begin
        if TrackingSpecification."Source Type" <> Database::"Qlty. Inspection Header" then
            exit;

        if (TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Surplus) and
           (TempGlobalEntrySummary."Total Quantity" = 0) and
           (TempGlobalEntrySummary."Qty. Alloc. in Warehouse" = 0) and
           (TempGlobalEntrySummary."Total Requested Quantity" = 0) and
           (TempGlobalEntrySummary."Current Pending Quantity" = 0) and
           (TempGlobalEntrySummary."Double-entry Adjustment" = 0)
         then
            TempGlobalEntrySummary."Total Quantity" := TempReservEntry."Quantity (Base)";
    end;

    /// <summary>
    /// Allows quality inspections to show up in the 'Find Entries' for any given item tracking.
    /// This is when you are in the Find Entries / Navigate page in "search for items" mode
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="TempRecordBuffer"></param>
    /// <param name="ItemFilters"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnAfterFindTrackingRecords', '', true, true)]
    local procedure HandleItemTrackingNvgMgmtOnAfterFindTrackingRecords(sender: Codeunit "Item Tracking Navigate Mgt."; var TempRecordBuffer: Record "Record Buffer" temporary; var ItemFilters: Record Item)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempBufferItemTrackingSetup: Record "Item Tracking Setup" temporary;
        QltySessionHelper: Codeunit "Qlty. Session Helper";
        ReferenceToInspection: RecordRef;
    begin
        if not QltyInspectionHeader.ReadPermission() then
            exit;

        QltyInspectionHeader.SetFilter("Source Item No.", ItemFilters.GetFilter("No."));
        QltyInspectionHeader.SetFilter("Source Variant Code", ItemFilters.GetFilter("Variant Filter"));
        QltyInspectionHeader.SetFilter("Source Lot No.", ItemFilters.GetFilter("Lot No. Filter"));
        QltyInspectionHeader.SetFilter("Source Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        QltyInspectionHeader.SetFilter("Source Package No.", ItemFilters.GetFilter("Package No. Filter"));

        QltySessionHelper.SetSessionValue(NavigatePageSearchFiltersTok, QltyInspectionHeader.GetView());
        if QltyInspectionHeader.FindSet() then
            repeat
                Clear(TempBufferItemTrackingSetup);
                TempBufferItemTrackingSetup."Lot No." := QltyInspectionHeader."Source Lot No.";
                TempBufferItemTrackingSetup."Serial No." := QltyInspectionHeader."Source Serial No.";
                TempBufferItemTrackingSetup."Package No." := QltyInspectionHeader."Source Package No.";
                ReferenceToInspection.GetTable(QltyInspectionHeader);
                sender.InsertBufferRec(ReferenceToInspection, TempBufferItemTrackingSetup, QltyInspectionHeader."Source Item No.", QltyInspectionHeader."Source Variant Code");
            until QltyInspectionHeader.Next() = 0;
    end;

    /// <summary>
    /// This occurs when checking item tracking to determine if the item tracking is allowed for the given type of activity.
    /// This occurs *before* the inspection find occurs, and gives an opportunity to adjust inspection filters.
    /// Used for assembly consumption, assembly output, consumption, output, purchase, sale, transfer
    /// </summary>
    /// <param name="ItemJournalLine"></param>
    /// <param name="TrackingSpecification"></param>
    /// <param name="QltyInspectionHeader">Adjust filters to find the relevant inspection here as needed</param>
    /// <param name="IsHandled">Only set to true if you want to replace the entire behavior. Keep with false if you want the system to keep evaluating after adding or removing filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrackingOnAfterSetFilters(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// This occurs when checking item tracking to determine if the item tracking is allowed for the given type of activity.
    /// This occurs after an inspection has been found.
    /// Used for assembly consumption, assembly output, consumption, output, purchase, sale, transfer
    /// </summary>
    /// <param name="ItemJournalLine"></param>
    /// <param name="TrackingSpecification"></param>
    /// <param name="QltyInspectionHeader">Inspection has already been found at this point, this should be a reference to the inspection.</param>
    /// <param name="QltyResult">This is the result being analyzed.</param>
    /// <param name="Blocked">Set to true to flag as blocked</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleCheckItemTrackingBeforeBlockErrorCheck(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionResult: Record "Qlty. Inspection Result"; var Blocked: Boolean)
    begin
    end;

    /// <summary>
    /// This occurs when checking item tracking to determine if the item tracking is allowed for the given type of activity.
    /// This occurs *before* the inspection find occurs, and gives an opportunity to adjust inspection filters.
    /// Used for inventory movements, inventory picks, inventory put aways, movements, picks, putaways.
    /// </summary>
    /// <param name="WarehouseActivityLine"></param>
    /// <param name="QltyInspectionHeader">Adjust filters to find the relevant inspection here as needed</param>
    /// <param name="IsHandled">Only set to true if you want to replace the entire behavior. Keep with false if you want the system to keep evaluating after adding or removing filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseItemTrackingOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// This occurs when checking item tracking to determine if the item tracking is allowed for the given type of activity.
    /// This occurs after an inspection has been found.
    /// Used for inventory movements, inventory picks, inventory putaways, movements, picks, putaways.
    /// </summary>
    /// <param name="WarehouseActivityLine"></param>
    /// <param name="QltyInspectionHeader">Inspection has already been found at this point, this should be a reference to the inspection.</param>
    /// <param name="QltyResult">This is the result being analyzed.</param>
    /// <param name="Blocked">Set to true to flag as blocked</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleCheckWhseItemTrackingBeforeBlockErrorCheck(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionResult: Record "Qlty. Inspection Result"; var Blocked: Boolean)
    begin
    end;
}