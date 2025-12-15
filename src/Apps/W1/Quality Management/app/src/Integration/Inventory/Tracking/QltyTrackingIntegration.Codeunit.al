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
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Activity;
using System.IO;

codeunit 20415 "Qlty. Tracking Integration"
{
    InherentPermissions = X;

    var
        EntryTypeBlockedErr: Label 'This transaction was blocked because the quality inspection %1 has the grade of %2 for item %4 with tracking %5, which is configured to disallow the transaction "%3". You can change whether this transaction is allowed by navigating to Quality Inspection Grades.', Comment = '%1=quality test, %2=grade, %3=entry type being blocked, %4=item, %5=combined package tracking details of lot, serial, and package no.';
        WarehouseEntryTypeBlockedErr: Label 'This warehouse transaction was blocked because the quality inspection %1 has the grade of %2 for item %4 with tracking %5 %6, which is configured to disallow the transaction "%3". You can change whether this transaction is allowed by navigating to Quality Inspection Grades.', Comment = '%1=quality test, %2=grade, %3=entry type being blocked, %4=item, %5=lot, %6=serial';
        NavigatePageSearchFiltersTok: Label 'NAVIGATEFILTERS', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterCheckItemTrackingInformation', '', true, true)]
    local procedure HandleOnAfterCheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup"; Item: Record Item)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        Blocked: Boolean;
        IsFinished: Boolean;
        Handled: Boolean;
        TrackingDetails: Text;
    begin
        case true of
            not QltyInspectionHeader.ReadPermission(),
            not QltyInspectionGrade.ReadPermission(),
            not QltyManagementSetup.GetSetupRecord():
                exit;
        end;

        QltyInspectionHeader.SetRange("Source Item No.", ItemJnlLine2."Item No.");
        QltyInspectionHeader.SetRange("Source Variant Code", ItemJnlLine2."Variant Code");
        QltyInspectionHeader.SetRange("Source Lot No.", TrackingSpecification."Lot No.");
        QltyInspectionHeader.SetRange("Source Serial No.", TrackingSpecification."Serial No.");
        QltyInspectionHeader.SetRange("Source Package No.", TrackingSpecification."Package No.");
        OnHandleCheckItemTrackingAfterFilters(ItemJnlLine2, TrackingSpecification, QltyInspectionHeader, Handled);
        if Handled then
            exit;

        case QltyManagementSetup."Conditional Lot Find Behavior" of
            QltyManagementSetup."Conditional Lot Find Behavior"::Any:
                if not QltyInspectionHeader.FindSet() then
                    exit;
            QltyManagementSetup."Conditional Lot Find Behavior"::AnyFinished:
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    if not QltyInspectionHeader.FindSet() then
                        exit;
                end;
            QltyManagementSetup."Conditional Lot Find Behavior"::HighestReinspectionNumber:
                begin
                    QltyInspectionHeader.SetCurrentKey("No.", "Reinspection No.");
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Conditional Lot Find Behavior"::HighestFinishedReinspectionNumber:
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    QltyInspectionHeader.SetCurrentKey("No.", "Reinspection No.");
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentModified:
                begin
                    QltyInspectionHeader.SetCurrentKey(SystemModifiedAt);
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentFinishedModified:
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
            if QltyInspectionHeader."Grade Code" <> '' then begin
                IsFinished := QltyInspectionHeader.Status = QltyInspectionHeader.Status::Finished;
                if QltyInspectionGrade.Get(QltyInspectionHeader."Grade Code") then begin
                    case ItemJnlLine2."Entry Type" of
                        ItemJnlLine2."Entry Type"::"Assembly Consumption":
                            Blocked := (QltyInspectionGrade."Lot Allow Assembly Consumption" = QltyInspectionGrade."Lot Allow Assembly Consumption"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Assembly Consumption" = QltyInspectionGrade."Lot Allow Assembly Consumption"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::"Assembly Output":
                            Blocked := (QltyInspectionGrade."Lot Allow Assembly Output" = QltyInspectionGrade."Lot Allow Assembly Output"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Assembly Output" = QltyInspectionGrade."Lot Allow Assembly Output"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Consumption:
                            Blocked := (QltyInspectionGrade."Lot Allow Consumption" = QltyInspectionGrade."Lot Allow Consumption"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Consumption" = QltyInspectionGrade."Lot Allow Consumption"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Output:
                            Blocked := (QltyInspectionGrade."Lot Allow Output" = QltyInspectionGrade."Lot Allow Output"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Output" = QltyInspectionGrade."Lot Allow Output"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Purchase:
                            Blocked := (QltyInspectionGrade."Lot Allow Purchase" = QltyInspectionGrade."Lot Allow Purchase"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Purchase" = QltyInspectionGrade."Lot Allow Purchase"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Sale:
                            Blocked := (QltyInspectionGrade."Lot Allow Sales" = QltyInspectionGrade."Lot Allow Sales"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Sales" = QltyInspectionGrade."Lot Allow Sales"::"Allow finished only"));

                        ItemJnlLine2."Entry Type"::Transfer:
                            Blocked := (QltyInspectionGrade."Lot Allow Transfer" = QltyInspectionGrade."Lot Allow Transfer"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Transfer" = QltyInspectionGrade."Lot Allow Transfer"::"Allow finished only"));
                    end;
                    OnHandleCheckItemTrackingBeforeBlockErrorCheck(ItemJnlLine2, TrackingSpecification, QltyInspectionHeader, QltyInspectionGrade, Blocked);

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
                            QltyInspectionGrade.Code,
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
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        Blocked: Boolean;
        IsFinished: Boolean;
        Handled: Boolean;
    begin
        case true of
            not QltyInspectionHeader.ReadPermission(),
            not QltyInspectionGrade.ReadPermission(),
            not QltyManagementSetup.GetSetupRecord():
                exit;
        end;

        QltyInspectionHeader.SetRange("Source Item No.", WarehouseActivityLine."Item No.");
        QltyInspectionHeader.SetRange("Source Variant Code", WarehouseActivityLine."Variant Code");
        QltyInspectionHeader.SetRange("Source Lot No.", WarehouseActivityLine."Lot No.");
        QltyInspectionHeader.SetRange("Source Serial No.", WarehouseActivityLine."Serial No.");
        QltyInspectionHeader.SetRange("Source Package No.", WarehouseActivityLine."Package No.");

        OnHandleCheckWhseItemTrackingAfterFilters(WarehouseActivityLine, QltyInspectionHeader, Handled);
        if Handled then
            exit;

        case QltyManagementSetup."Conditional Lot Find Behavior" of
            QltyManagementSetup."Conditional Lot Find Behavior"::Any:
                if not QltyInspectionHeader.FindSet() then
                    exit;
            QltyManagementSetup."Conditional Lot Find Behavior"::AnyFinished:
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    if not QltyInspectionHeader.FindSet() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Conditional Lot Find Behavior"::HighestReinspectionNumber:
                begin
                    QltyInspectionHeader.SetCurrentKey("No.", "Reinspection No.");
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Conditional Lot Find Behavior"::HighestFinishedReinspectionNumber:
                begin
                    QltyInspectionHeader.SetRange(Status, QltyInspectionHeader.Status::Finished);
                    QltyInspectionHeader.SetCurrentKey("No.", "Reinspection No.");
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentModified:
                begin
                    QltyInspectionHeader.SetCurrentKey(SystemModifiedAt);
                    QltyInspectionHeader.Ascending(false);
                    if not QltyInspectionHeader.FindFirst() then
                        exit;
                    QltyInspectionHeader.SetRecFilter();
                end;
            QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentFinishedModified:
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
            if QltyInspectionHeader."Grade Code" <> '' then begin
                IsFinished := QltyInspectionHeader.Status = QltyInspectionHeader.Status::Finished;

                if QltyInspectionGrade.Get(QltyInspectionHeader."Grade Code") then begin
                    case WarehouseActivityLine."Activity Type" of
                        WarehouseActivityLine."Activity Type"::"Invt. Movement":
                            Blocked := (QltyInspectionGrade."Lot Allow Invt. Movement" = QltyInspectionGrade."Lot Allow Invt. Movement"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Invt. Movement" = QltyInspectionGrade."Lot Allow Invt. Movement"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::"Invt. Pick":
                            Blocked := (QltyInspectionGrade."Lot Allow Invt. Pick" = QltyInspectionGrade."Lot Allow Invt. Pick"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Invt. Pick" = QltyInspectionGrade."Lot Allow Invt. Pick"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::"Invt. Put-away":
                            Blocked := (QltyInspectionGrade."Lot Allow Invt. Put-away" = QltyInspectionGrade."Lot Allow Invt. Put-away"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Invt. Put-away" = QltyInspectionGrade."Lot Allow Invt. Put-away"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::Movement:
                            Blocked := (QltyInspectionGrade."Lot Allow Movement" = QltyInspectionGrade."Lot Allow Movement"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Movement" = QltyInspectionGrade."Lot Allow Movement"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::Pick:
                            Blocked := (QltyInspectionGrade."Lot Allow Pick" = QltyInspectionGrade."Lot Allow Pick"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Pick" = QltyInspectionGrade."Lot Allow Pick"::"Allow finished only"));

                        WarehouseActivityLine."Activity Type"::"Put-away":
                            Blocked := (QltyInspectionGrade."Lot Allow Put-Away" = QltyInspectionGrade."Lot Allow Put-Away"::Block) or
                                (not IsFinished and (QltyInspectionGrade."Lot Allow Put-away" = QltyInspectionGrade."Lot Allow Put-away"::"Allow finished only"));
                    end;
                    OnHandleCheckWhseItemTrackingBeforeBlockErrorCheck(WarehouseActivityLine, QltyInspectionHeader, QltyInspectionGrade, Blocked);

                    if Blocked then
                        Error(
                            WarehouseEntryTypeBlockedErr,
                            QltyInspectionHeader.GetFriendlyIdentifier(),
                            QltyInspectionGrade.Code,
                            WarehouseActivityLine."Activity Type",
                            WarehouseActivityLine."Item No.",
                            WarehouseActivityLine."Lot No.",
                            WarehouseActivityLine."Serial No.");
                end;
            end;
        until QltyInspectionHeader.Next() = 0;
    end;

    /// <summary>
    /// Used to help assist edits find serial and lot numbers.
    /// In the context of Quality Inspections location doesn't really matter.
    /// Used as part of the AssistEdit Lot Number functionality.
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
    /// Used as part of the AssistEdit Lot Number functionality.
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
    /// Used as part of the AssistEdit Lot Number functionality.
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
        ReferenceToTest: RecordRef;
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
                ReferenceToTest.GetTable(QltyInspectionHeader);
                sender.InsertBufferRec(ReferenceToTest, TempBufferItemTrackingSetup, QltyInspectionHeader."Source Item No.", QltyInspectionHeader."Source Variant Code");
            until QltyInspectionHeader.Next() = 0;
    end;

    /// <summary>
    /// This occurs when checking item tracking to determine if the lot/serial is allowed for the given type of activity.
    /// This occurs *before* the test find occurs, and gives an opportunity to adjust test filters.
    /// Used for assembly consumption, assembly output, consumption, output, purchase, sale, transfer
    /// </summary>
    /// <param name="ItemJournalLine"></param>
    /// <param name="TrackingSpecification"></param>
    /// <param name="QltyInspectionHeader">Adjust filters to find the relevant test here as needed</param>
    /// <param name="Handled">Only set to true if you want to replace the entire behavior. Keep with false if you want the system to keep evaluating after adding or removing filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleCheckItemTrackingAfterFilters(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// This occurs when checking item tracking to determine if the lot/serial is allowed for the given type of activity.
    /// This occurs after an inspection has been found.
    /// Used for assembly consumption, assembly output, consumption, output, purchase, sale, transfer
    /// </summary>
    /// <param name="ItemJournalLine"></param>
    /// <param name="TrackingSpecification"></param>
    /// <param name="QltyInspectionHeader">Test has already been found at this point, this should be a reference to the test.</param>
    /// <param name="QltyGrade">This is the grade being analyzed.</param>
    /// <param name="Blocked">Set to true to flag as blocked</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleCheckItemTrackingBeforeBlockErrorCheck(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionGrade: Record "Qlty. Inspection Grade"; var Blocked: Boolean)
    begin
    end;

    /// <summary>
    /// This occurs when checking item tracking to determine if the lot/serial is allowed for the given type of activity.
    /// This occurs *before* the test find occurs, and gives an opportunity to adjust test filters.
    /// Used for inventory movements, inventory picks, inventory put aways, movements, picks, putaways.
    /// </summary>
    /// <param name="WarehouseActivityLine"></param>
    /// <param name="QltyInspectionHeader">Adjust filters to find the relevant test here as needed</param>
    /// <param name="Handled">Only set to true if you want to replace the entire behavior. Keep with false if you want the system to keep evaluating after adding or removing filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleCheckWhseItemTrackingAfterFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// This occurs when checking item tracking to determine if the lot/serial is allowed for the given type of activity.
    /// This occurs after an inspection has been found.
    /// Used for inventory movements, inventory picks, inventory putaways, movements, picks, putaways.
    /// </summary>
    /// <param name="WarehouseActivityLine"></param>
    /// <param name="QltyInspectionHeader">Test has already been found at this point, this should be a reference to the test.</param>
    /// <param name="QltyGrade">This is the grade being analyzed.</param>
    /// <param name="Blocked">Set to true to flag as blocked</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleCheckWhseItemTrackingBeforeBlockErrorCheck(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionGrade: Record "Qlty. Inspection Grade"; var Blocked: Boolean)
    begin
    end;
}
