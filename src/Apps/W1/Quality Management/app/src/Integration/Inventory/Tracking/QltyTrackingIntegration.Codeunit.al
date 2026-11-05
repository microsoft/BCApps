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
using System.Utilities;

codeunit 20415 "Qlty. Tracking Integration"
{
    InherentPermissions = X;

    var
        EntryTypeBlockedErr: Label '"%1" transaction is not allowed for item %2 with tracking %3 because quality inspection %4 has result %5, which is configured to block this transaction.', Comment = '%1=entry type being blocked, %2=item, %3=combined package tracking details of Lot No., Serial No. and Package No., %4=quality inspection, %5=result';
        WarehouseEntryTypeBlockedErr: Label '"%1" warehouse transaction is not allowed for item %2 with tracking %3 because quality inspection %4 has result %5, which is configured to block this transaction.', Comment = '%1=entry type being blocked, %2=item, %3=combined package tracking details of Lot No., Serial No. and Package No., %4=quality inspection, %5=result';
        NavigatePageSearchFiltersTok: Label 'NAVIGATEFILTERS', Locked = true;
        BlockedByQualityInspectionTitleLbl: Label 'Blocked by quality inspection', Comment = 'Title for the error message when a transaction is blocked by a quality inspection';
        ShowInspectionActionLbl: Label 'Show Quality Inspection';

    /// <summary>
    /// Blocks item journal posting when a matching quality inspection result disallows the entry type.
    /// </summary>
    /// <param name="ItemJnlLine2">The item journal line being validated.</param>
    /// <param name="TrackingSpecification">The item-tracking values being validated.</param>
    /// <param name="ItemTrackingSetup">The item-tracking requirements supplied by the posting routine.</param>
    /// <param name="Item">The item supplied by the posting routine.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::Microsoft.QualityManagement.Setup."Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::Microsoft.QualityManagement.Configuration.Result."Qlty. Inspection Result", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Header", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterCheckItemTrackingInformation', '', true, true)]
    local procedure HandleOnAfterCheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup"; Item: Record Item)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        Blocked: Boolean;
        IsFinished: Boolean;
        IsHandled: Boolean;
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

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

        SetLoadFieldsByEntryType(QltyInspectionResult, ItemJnlLine2."Entry Type");

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

                    if Blocked then
                        LogBlockedTransactionError(
                            QltyInspectionHeader,
                            StrSubstNo(EntryTypeBlockedErr,
                                ItemJnlLine2."Entry Type",
                                ItemJnlLine2."Item No.",
                                GetItemTrackingDetails(TrackingSpecification."Lot No.", TrackingSpecification."Serial No.", TrackingSpecification."Package No."),
                                QltyInspectionHeader.GetFriendlyIdentifier(),
                                QltyInspectionResult.Code));
                end;
            end;
        until QltyInspectionHeader.Next() = 0;
    end;

    /// <summary>
    /// Validates a warehouse activity line against matching quality inspection results after registration checks.
    /// </summary>
    /// <param name="WarehouseActivityLine">The warehouse activity line to validate.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterCheckWhseActivLine', '', true, true)]
    local procedure HandleOnAfterCheckWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        CommonCheckWarehouseActivityLineIsAllowed(WarehouseActivityLine);
    end;

    /// <summary>
    /// Validates a warehouse activity line against matching quality inspection results after blocked-tracking checks.
    /// </summary>
    /// <param name="WhseActivityLine">The warehouse activity line to validate.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterCheckItemTrackingInfoBlocked', '', true, true)]
    local procedure HandleOnAfterCheckItemTrackingInfoBlocked(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        CommonCheckWarehouseActivityLineIsAllowed(WhseActivityLine);
    end;

    /// <summary>
    /// Validates a warehouse activity line against matching quality inspection results before posting proceeds.
    /// </summary>
    /// <param name="WarehouseActivityLine">The warehouse activity line to validate.</param>
    /// <param name="WarehouseActivityHeader">The warehouse activity header supplied by the posting routine.</param>
    /// <param name="Location">The warehouse location supplied by the posting routine.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnAfterCheckWarehouseActivityLine', '', true, true)]
    local procedure HandleOnAfterCheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location)
    begin
        CommonCheckWarehouseActivityLineIsAllowed(WarehouseActivityLine);
    end;

    /// <summary>
    /// Blocks a warehouse activity when a matching quality inspection result disallows its activity type.
    /// </summary>
    /// <param name="WarehouseActivityLine">The warehouse activity line to evaluate.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::Microsoft.QualityManagement.Setup."Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::Microsoft.QualityManagement.Configuration.Result."Qlty. Inspection Result", 'R', InherentPermissionsScope::Permissions)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Header", 'R', InherentPermissionsScope::Permissions)]
    local procedure CommonCheckWarehouseActivityLineIsAllowed(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        Blocked: Boolean;
        IsFinished: Boolean;
        IsHandled: Boolean;
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

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

        SetLoadFieldsByActivityType(QltyInspectionResult, WarehouseActivityLine."Activity Type");

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
                        LogBlockedTransactionError(
                                QltyInspectionHeader,
                                StrSubstNo(WarehouseEntryTypeBlockedErr,
                                    WarehouseActivityLine."Activity Type",
                                    WarehouseActivityLine."Item No.",
                                    GetItemTrackingDetails(WarehouseActivityLine."Lot No.", WarehouseActivityLine."Serial No.", WarehouseActivityLine."Package No."),
                                    QltyInspectionHeader.GetFriendlyIdentifier(),
                                    QltyInspectionResult.Code));
                end;
            end;
        until QltyInspectionHeader.Next() = 0;
    end;

    /// <summary>
    /// Removes the location filter and applies the source ID while retrieving item-tracking lookup data for inspections.
    /// Used to help assist edits find item tracking numbers.
    /// In the context of Quality Inspections location doesn't really matter.
    /// Used as part of the AssistEdit Item Tracking Number functionality.
    /// </summary>
    /// <param name="ReservEntry">The reservation entries whose filters are adjusted.</param>
    /// <param name="TempTrackingSpecification">The inspection tracking specification that supplies source filters.</param>
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
    /// Broadens ledger-entry lookup filters and includes posted documents related to the inspection source document.
    /// </summary>
    /// <param name="TempTrackingSpecification">The inspection tracking specification that supplies source filters.</param>
    /// <param name="TempReservationEntry">The temporary reservation entry supplied by data collection.</param>
    /// <param name="ItemLedgerEntry">The item ledger entries whose filters are adjusted.</param>
    /// <param name="FullDataSet">Indicates whether data collection requests the full data set.</param>
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
    /// Builds a pipe-separated filter suffix of posted document numbers related to the source order and line.
    /// </summary>
    /// <param name="TempTrackingSpecification">The tracking specification containing the source order and line filters.</param>
    /// <returns>A pipe-prefixed list of related posted document numbers, or blank when none exist.</returns>
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
    /// Loads only the result field that the given entry type is evaluated against.
    /// </summary>
    /// <param name="QltyInspectionResult">The inspection result record whose load fields are configured.</param>
    /// <param name="EntryType">The item ledger entry type to evaluate.</param>
    local procedure SetLoadFieldsByEntryType(var QltyInspectionResult: Record "Qlty. Inspection Result"; EntryType: Enum "Item Ledger Entry Type")
    begin
        case EntryType of
            EntryType::"Assembly Consumption":
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Asm. Cons.");
            EntryType::"Assembly Output":
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Asm. Out.");
            EntryType::Consumption:
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Consump.");
            EntryType::Output:
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Output");
            EntryType::Purchase:
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Purchase");
            EntryType::Sale:
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Sales");
            EntryType::Transfer:
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Transfer");
        end;
    end;

    /// <summary>
    /// Loads only the result field that the given warehouse activity type is evaluated against.
    /// </summary>
    /// <param name="QltyInspectionResult">The inspection result record whose load fields are configured.</param>
    /// <param name="ActivityType">The warehouse activity type to evaluate.</param>
    local procedure SetLoadFieldsByActivityType(var QltyInspectionResult: Record "Qlty. Inspection Result"; ActivityType: Enum "Warehouse Activity Type")
    begin
        case ActivityType of
            ActivityType::"Invt. Movement":
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Invt. Mov.");
            ActivityType::"Invt. Pick":
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Invt. Pick");
            ActivityType::"Invt. Put-away":
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Invt. PA");
            ActivityType::Movement:
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Movement");
            ActivityType::Pick:
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Pick");
            ActivityType::"Put-away":
                QltyInspectionResult.SetLoadFields("Item Tracking Allow Put-Away");
        end;
    end;

    /// <summary>
    /// Combines nonblank lot, serial, and package numbers into a space-separated tracking description.
    /// </summary>
    /// <param name="LotNo">The lot number.</param>
    /// <param name="SerialNo">The serial number.</param>
    /// <param name="PackageNo">The package number.</param>
    /// <returns>The combined item-tracking description.</returns>
    local procedure GetItemTrackingDetails(LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50]): Text
    var
        TrackingDetails: Text;
    begin
        TrackingDetails := LotNo;
        if SerialNo <> '' then begin
            if TrackingDetails <> '' then
                TrackingDetails += ' ';
            TrackingDetails += SerialNo;
        end;
        if PackageNo <> '' then begin
            if TrackingDetails <> '' then
                TrackingDetails += ' ';
            TrackingDetails += PackageNo;
        end;
        exit(TrackingDetails);
    end;

    /// <summary>
    /// Raises a navigable quality-inspection error and logs it when error-message collection is active.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that blocks the transaction.</param>
    /// <param name="ErrorMessage">The error message to log and raise.</param>
    local procedure LogBlockedTransactionError(QltyInspectionHeader: Record "Qlty. Inspection Header"; ErrorMessage: Text)
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        BlockedErrorInfo: ErrorInfo;
    begin
        if ErrorMessageManagement.IsActive() then begin
            ErrorMessageManagement.LogContextFieldError(
            0,
            ErrorMessage,
            QltyInspectionHeader,
            QltyInspectionHeader.FieldNo("Result Code"),
            '');
            Error(''); // Needed to stop the transaction from continuing in the preview mode, but the error message will be logged in the Error Message Management log.
        end;

        BlockedErrorInfo.Title := BlockedByQualityInspectionTitleLbl;
        BlockedErrorInfo.Message := ErrorMessage;
        BlockedErrorInfo.RecordId := QltyInspectionHeader.RecordId();
        BlockedErrorInfo.FieldNo := QltyInspectionHeader.FieldNo("Result Code");
        BlockedErrorInfo.PageNo := Page::"Qlty. Inspection";
        BlockedErrorInfo.DataClassification := DataClassification::CustomerContent;
        BlockedErrorInfo.ErrorType := ErrorType::Client;
        BlockedErrorInfo.AddNavigationAction(ShowInspectionActionLbl);
        Error(BlockedErrorInfo);
    end;

    /// <summary>
    /// Restores the available quantity for surplus inspection tracking entries in item-tracking lookup summaries.
    /// </summary>
    /// <param name="TempGlobalEntrySummary">The entry summary whose total quantity can be restored.</param>
    /// <param name="TempReservEntry">The reservation entry supplying the quantity.</param>
    /// <param name="TrackingSpecification">The tracking specification used to identify inspection lookups.</param>
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
    /// Adds matching quality inspections to item-tracking Navigate results and stores the inspection filters for display.
    /// </summary>
    /// <param name="sender">The item-tracking Navigate management codeunit used to insert result entries.</param>
    /// <param name="TempRecordBuffer">The temporary Navigate record buffer.</param>
    /// <param name="ItemFilters">The item and item-tracking filters used to find inspections.</param>
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
    /// Notifies subscribers after inspection filters are set and before item-journal tracking inspections are selected.
    /// </summary>
    /// <param name="ItemJournalLine">The item journal line being evaluated.</param>
    /// <param name="TrackingSpecification">The item-tracking values being evaluated.</param>
    /// <param name="QltyInspectionHeader">The filtered inspection record that subscribers can adjust.</param>
    /// <param name="IsHandled">Set to true to skip the standard inspection evaluation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrackingOnAfterSetFilters(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers before an item-journal tracking restriction raises a blocking error.
    /// </summary>
    /// <param name="ItemJournalLine">The item journal line being evaluated.</param>
    /// <param name="TrackingSpecification">The item-tracking values being evaluated.</param>
    /// <param name="QltyInspectionHeader">The matching quality inspection.</param>
    /// <param name="QltyInspectionResult">The inspection result whose transaction rule is being evaluated.</param>
    /// <param name="Blocked">Indicates whether the transaction is blocked; subscribers can change this value.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleCheckItemTrackingBeforeBlockErrorCheck(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionResult: Record "Qlty. Inspection Result"; var Blocked: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers after inspection filters are set and before warehouse tracking inspections are selected.
    /// </summary>
    /// <param name="WarehouseActivityLine">The warehouse activity line being evaluated.</param>
    /// <param name="QltyInspectionHeader">The filtered inspection record that subscribers can adjust.</param>
    /// <param name="IsHandled">Set to true to skip the standard inspection evaluation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseItemTrackingOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers before a warehouse tracking restriction raises a blocking error.
    /// </summary>
    /// <param name="WarehouseActivityLine">The warehouse activity line being evaluated.</param>
    /// <param name="QltyInspectionHeader">The matching quality inspection.</param>
    /// <param name="QltyInspectionResult">The inspection result whose warehouse activity rule is being evaluated.</param>
    /// <param name="Blocked">Indicates whether the activity is blocked; subscribers can change this value.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleCheckWhseItemTrackingBeforeBlockErrorCheck(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionResult: Record "Qlty. Inspection Result"; var Blocked: Boolean)
    begin
    end;
}