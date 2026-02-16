// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Move;

using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;

codeunit 20451 "Qlty. Disp. Move Worksheet" implements "Qlty. Disposition"
{
    EventSubscriberInstance = Manual;

    var
        TempCreatedWhseWorksheetLine: Record "Whse. Worksheet Line" temporary;
        CreatedWarehouseActivityHeaderDocumentNo: Code[20];
        WorksheetLineDescriptionTemplateLbl: Label 'Inspection [%3] changed bin from [%1] to [%2]', Comment = '%1 = From Bin code; %2 = To Bin code; %3 = the inspection';
        UnableToChangeBinsBetweenLocationsBecauseDirectedPickAndPutErr: Label 'Unable to change location of the inventory from inspection %1 from location %2 to %3 because %2 is directed pick and put-away, you can only change bins with the same location.', Comment = '%1=the inspection, %2=from location, %3=to location';
        MissingBinMoveBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the movement batches.';
        RequestedInventoryMoveButUnableToFindSufficientDetailsErr: Label 'A worksheet movement for the inventory related to inspection %1 was requested, however insufficient inventory information is available to do this task.\\  Please verify that the inspection has sufficient details for the item, variant, lot, serial and package. \\ Make sure to define the quantity to move.', Comment = '%1=the inspection';
        DocumentTypeWarehouseMovementLbl: Label 'Warehouse Movement';
        NoWhseWkshErr: Label 'There is no Warehouse Worksheet for the specified template, worksheet name, and location. Ensure the correct worksheet is defined on the Quality Management Setup Card and the worksheet exists for location %1.', Comment = '%1=location';

    internal procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        FromLocation: Record Location;
        CreatedWarehouseActivityHeader: Record "Warehouse Activity Header";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        MovementWorksheetTemplateName: Code[10];
        MovementLineCreated: Boolean;
        CreatedDocumentNo: Text;
    begin
        Clear(TempCreatedWhseWorksheetLine);
        TempCreatedWhseWorksheetLine.DeleteAll(false);
        Clear(CreatedWarehouseActivityHeaderDocumentNo);

        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Movement Worksheet";
        QltyManagementSetup.Get();
        MovementWorksheetTemplateName := QltyManagementSetup.GetMovementWorksheetTemplateName();
        if QltyManagementSetup."Movement Worksheet Name" = '' then
            Error(MissingBinMoveBatchErr);

        if TempInstructionQltyDispositionBuffer."Location Filter" = '' then
            if QltyInspectionHeader."Location Code" <> '' then
                TempInstructionQltyDispositionBuffer."Location Filter" := QltyInspectionHeader."Location Code";

        if (TempInstructionQltyDispositionBuffer."New Location Code" = '') and (TempInstructionQltyDispositionBuffer."New Bin Code" = '') then
            Error(RequestedInventoryMoveButUnableToFindSufficientDetailsErr, QltyInspectionHeader."No.");

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        TempQuantityToActQltyDispositionBuffer.FindSet();

        repeat
            if FromLocation.Code <> TempQuantityToActQltyDispositionBuffer.GetFromLocationCode() then
                FromLocation.Get(TempQuantityToActQltyDispositionBuffer."Location Filter");

            if (TempQuantityToActQltyDispositionBuffer."New Location Code" <> '') and (TempQuantityToActQltyDispositionBuffer."New Location Code" <> TempQuantityToActQltyDispositionBuffer."Location Filter") then
                Error(UnableToChangeBinsBetweenLocationsBecauseDirectedPickAndPutErr, QltyInspectionHeader."No.", TempQuantityToActQltyDispositionBuffer."Location Filter", TempQuantityToActQltyDispositionBuffer."New Location Code");

            MovementLineCreated := false;

            CreateWarehouseWorksheetLine(
                QltyInspectionHeader,
                MovementWorksheetTemplateName,
                QltyManagementSetup."Movement Worksheet Name",
                TempQuantityToActQltyDispositionBuffer.GetFromLocationCode(),
                TempQuantityToActQltyDispositionBuffer.GetFromBinCode(),
                TempQuantityToActQltyDispositionBuffer."New Bin Code",
                TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)",
                MovementLineCreated);

            DidSomething := DidSomething or MovementLineCreated;

            if (MovementLineCreated and (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only")) then
                QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Movement Worksheet Name");

        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        if (DidSomething and (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post)) then
            CreatedDocumentNo := CreateMovementFromMovementWorksheetLines(QltyInspectionHeader, MovementWorksheetTemplateName, QltyManagementSetup."Movement Worksheet Name", FromLocation.Code);

        if CreatedDocumentNo <> '' then
            if CreatedWarehouseActivityHeader.Get(CreatedWarehouseActivityHeader.Type::Movement, CreatedDocumentNo) then
                QltyNotificationMgmt.NotifyDocumentCreated(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeWarehouseMovementLbl, CreatedDocumentNo, CreatedWarehouseActivityHeader);
    end;

    local procedure CreateMovementFromMovementWorksheetLines(QltyInspectionHeader: Record "Qlty. Inspection Header"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; FromLocationCode: Code[20]): Text
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        MovementWhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        LineFilter: Text;
    begin
        TempCreatedWhseWorksheetLine.Reset();
        LineFilter := '';
        if TempCreatedWhseWorksheetLine.FindSet() then
            repeat
                if StrLen(LineFilter) > 0 then
                    LineFilter += '|';
                LineFilter += Format(TempCreatedWhseWorksheetLine."Line No.", 0, 9);
            until TempCreatedWhseWorksheetLine.Next() = 0;

        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWkshTemplateName);
        WhseWorksheetLine.SetRange(Name, WhseWkshName);
        WhseWorksheetLine.SetRange("Location Code", FromLocationCode);
        WhseWorksheetLine.SetRange("Item No.", QltyInspectionHeader."Source Item No.");
        WhseWorksheetLine.SetRange("Variant Code", QltyInspectionHeader."Source Variant Code");
        if StrLen(LineFilter) > 0 then
            WhseWorksheetLine.SetFilter("Line No.", LineFilter);
        WhseWorksheetLine.SetFilter(Quantity, '>0');
        MovementWhseSourceCreateDocument.SetHideValidationDialog(true);
        MovementWhseSourceCreateDocument.UseRequestPage(false);
        MovementWhseSourceCreateDocument.SetWhseWkshLine(WhseWorksheetLine);
        BindSubscription(this);
        MovementWhseSourceCreateDocument.Run();
        UnbindSubscription(this);
        exit(CreatedWarehouseActivityHeaderDocumentNo);
    end;

    local procedure CreateWarehouseWorksheetLine(QltyInspectionHeader: Record "Qlty. Inspection Header"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; FromLocationCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; Quantity: Decimal; var WorksheetLineCreated: Boolean)
    var
        WkshWhseWorksheetLine: Record "Whse. Worksheet Line";
        TempWarehouseEntry: Record "Warehouse Entry" temporary;
        WhseWorksheetName: Record "Whse. Worksheet Name";
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        LineNo: Integer;
        IsHandled: Boolean;
        WhseActivitySortMethod: Enum "Whse. Activity Sorting Method";
    begin
        WhseWorksheetName.SetRange("Worksheet Template Name", WhseWkshTemplateName);
        WhseWorksheetName.SetRange(Name, WhseWkshName);
        WhseWorksheetName.SetRange("Location Code", FromLocationCode);
        if WhseWorksheetName.IsEmpty() then
            Error(NoWhseWkshErr, FromLocationCode);

        LineNo := 10000;
        WhseActivitySortMethod := WhseActivitySortMethod::None;
        WkshWhseWorksheetLine.SetUpNewLine(WhseWkshTemplateName, WhseWkshName, FromLocationCode, WhseActivitySortMethod, LineNo);
        WkshWhseWorksheetLine.Validate("Item No.", QltyInspectionHeader."Source Item No.");
        WkshWhseWorksheetLine.Validate("Variant Code", QltyInspectionHeader."Source Variant Code");
        WkshWhseWorksheetLine.Validate("From Bin Code", FromBinCode);
        WkshWhseWorksheetLine.Validate("To Bin Code", ToBinCode);
        WkshWhseWorksheetLine.Validate(Quantity, Quantity);
        WkshWhseWorksheetLine.Validate("Qty. to Handle", Quantity);
        WkshWhseWorksheetLine.Description := CopyStr(StrSubstNo(
            WorksheetLineDescriptionTemplateLbl,
            FromBinCode,
            ToBinCode,
            QltyInspectionHeader.GetFriendlyIdentifier()), 1, MaxStrLen(WkshWhseWorksheetLine.Description));
        WkshWhseWorksheetLine.Insert();
        TempCreatedWhseWorksheetLine := WkshWhseWorksheetLine;
        if TempCreatedWhseWorksheetLine.Insert() then;

        if QltyInspectionHeader.IsItemTrackingUsed() then begin
            TempWarehouseEntry."Item No." := QltyInspectionHeader."Source Item No.";
            TempWarehouseEntry."Variant Code" := QltyInspectionHeader."Source Variant Code";
            TempWarehouseEntry."Lot No." := QltyInspectionHeader."Source Lot No.";
            TempWarehouseEntry."Serial No." := QltyInspectionHeader."Source Serial No.";
            TempWarehouseEntry."Package No." := QltyInspectionHeader."Source Package No.";
            TempWarehouseEntry."Expiration Date" := QltyItemTrackingMgmt.GetExpirationDate(QltyInspectionHeader, FromLocationCode);
            TempWarehouseEntry."Location Code" := FromLocationCode;
            OnBeforeSetWhseWkshTrackingLines(QltyInspectionHeader, FromLocationCode, FromBinCode, ToBinCode, Quantity, WorksheetLineCreated, WkshWhseWorksheetLine, TempWarehouseEntry, IsHandled);
            if not IsHandled then
                if (TempWarehouseEntry."Lot No." <> '') or (TempWarehouseEntry."Serial No." <> '') or (TempWarehouseEntry."Package No." <> '') then
                    WkshWhseWorksheetLine.SetItemTrackingLines(TempWarehouseEntry, Quantity);
        end;
        WorksheetLineCreated := true;
        OnAfterCreateWarehouseWorksheetLine(QltyInspectionHeader, FromLocationCode, FromBinCode, ToBinCode, Quantity, WorksheetLineCreated, TempWarehouseEntry, WkshWhseWorksheetLine);
    end;

    #region Event Subscribers

    [EventSubscriber(ObjectType::Report, Report::"Whse.-Source - Create Document", 'OnAfterPostReport', '', true, true)]
    local procedure HandleOnAfterPostReport(FirstActivityNo: Code[20]; LastActivityNo: Code[20])
    begin
        CreatedWarehouseActivityHeaderDocumentNo := LastActivityNo;
    end;

    #endregion Event Subscribers

    /// <summary>
    /// Provides an opportunity to alter the warehouse worksheet line that was made with MoveInventory
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="FromLocationCode"></param>
    /// <param name="FromBinCode"></param>
    /// <param name="ToBinCode"></param>
    /// <param name="Quantity"></param>
    /// <param name="WorksheetLineCreated"></param>
    /// <param name="ltrecWarehouseEntry"></param>
    /// <param name="lrecWhseWkshLine"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWarehouseWorksheetLine(QltyInspectionHeader: Record "Qlty. Inspection Header"; FromLocationCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; Quantity: Decimal; var WorksheetLineCreated: Boolean; var TempWarehouseEntry: Record "Warehouse Entry" temporary; var WkshWhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    /// <summary>
    /// Provides an opportunity to alter the warehouse worksheet tracking lines that were made with MoveInventory
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="FromLocationCode"></param>
    /// <param name="FromBinCode"></param>
    /// <param name="ToBinCode"></param>
    /// <param name="Quantity"></param>
    /// <param name="WorksheetLineCreated"></param>
    /// <param name="lrecWhseWkshLine"></param>
    /// <param name="ltrecWarehouseEntry"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetWhseWkshTrackingLines(QltyInspectionHeader: Record "Qlty. Inspection Header"; FromLocationCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; Quantity: Decimal; var WorksheetLineCreated: Boolean; WkshWhseWorksheetLine: Record "Whse. Worksheet Line"; var TempWarehouseEntry: Record "Warehouse Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}
