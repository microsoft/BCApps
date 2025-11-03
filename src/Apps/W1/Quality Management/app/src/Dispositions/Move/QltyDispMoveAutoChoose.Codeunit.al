// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Move;

using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// This codeunits responsability is to deal with a move reaction.
/// This is used to help automatically choose the type of movement.
/// Consider using the movement dispositions directly if you know the type of movement you need.
/// Item-reclass based move
/// Warehouse-reclass based move.
/// Movement worksheet.
/// Movement document.
/// </summary>
codeunit 20442 "Qlty. Disp. Move Auto Choose" implements "Qlty. Disposition"
{
    var
        BackwardsCompatibleFlagCallMoveInventoryFirstUseWorksheet: Boolean;
        UnableToChangeBinsBetweenLocationsBecauseDirectedPickAndPutErr: Label 'Unable to change location of the inventory from test %1 from location %2 to %3 because %2 is directed pick and put-away, you can only change bins with the same location.', Comment = '%1=the test, %2=from location, %3=to location';
        DocumentTypeLbl: Label 'Move';
        ThereIsNothingToMoveToErr: Label 'There is no location or bin to move to. Unable to perform the inventory related transaction on the test %1. Please define the target location and bin and try again.', Locked = true, Comment = '%1=the test';
        RequestedInventoryMoveButUnableToFindSufficientDetailsErr: Label 'A bin movement for the inventory related to test %1 was requested, however insufficient inventory information is available to do this task.\\  Please verify that the test has sufficient details for the location, item, variant, lot, and serial. \\ If you are using PowerAutomate please make sure that your power automate flow has sufficient configuration.\\If you are moving in Business Central make sure to define the quantity to move.', Comment = '%1=the test';

    /// <summary>
    /// Used as an interim shim to assist with obsoletions and refactoring.
    /// Consider using the disposition method that you want directly instead.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <returns></returns>
    procedure PerformDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        Location: Record Location;
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyDispMoveWorksheet: Codeunit "Qlty. Disp. Move Worksheet";
        WarehouseQltyDispMoveWhseReclass: Codeunit "Qlty. Disp. Move Whse.Reclass.";
        QltyDispMoveItemReclass: Codeunit "Qlty. Disp. Move Item Reclass.";
        mentQltyDispInternalMove: Codeunit "Qlty. Disp. Internal Move";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        Handled: Boolean;
    begin
        OnBeforeProcessDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DidSomething, Handled);
        if Handled then
            exit;

        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with automatic choice";
        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            Clear(Location);
            if TempQuantityToActQltyDispositionBuffer."Location Filter" <> '' then
                Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

            if Location."Directed Put-away and Pick" then begin
                if (TempQuantityToActQltyDispositionBuffer."New Location Code" <> '') and (TempQuantityToActQltyDispositionBuffer."New Location Code" <> TempQuantityToActQltyDispositionBuffer."Location Filter") then
                    Error(UnableToChangeBinsBetweenLocationsBecauseDirectedPickAndPutErr, QltyInspectionTestHeader."No.", TempQuantityToActQltyDispositionBuffer."Location Filter", TempQuantityToActQltyDispositionBuffer."New Location Code");

                if BackwardsCompatibleFlagCallMoveInventoryFirstUseWorksheet then
                    DidSomething := QltyDispMoveWorksheet.PerformDisposition(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer)
                else
                    DidSomething := WarehouseQltyDispMoveWhseReclass.PerformDisposition(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer);
            end else
                if BackwardsCompatibleFlagCallMoveInventoryFirstUseWorksheet then
                    DidSomething := mentQltyDispInternalMove.PerformDisposition(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer)
                else
                    DidSomething := QltyDispMoveItemReclass.PerformDisposition(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer);

        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        OnAfterProcessDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DidSomething);
    end;

    /// <summary>
    /// Do not use directly for net new code.  This method is an interim shim to help with obsoletions and refactoring for dispositions.
    /// Instead use the new dispositions directly.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="UseMovement"></param>
    /// <returns></returns>
    internal procedure MoveInventory(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; UseMovement: Boolean) DidSomething: Boolean
    var
    begin
        if (TempInstructionQltyDispositionBuffer."New Location Code" = '') and (TempInstructionQltyDispositionBuffer."New Bin Code" = '') then
            Error(ThereIsNothingToMoveToErr, QltyInspectionTestHeader.GetFriendlyIdentifier());

        BackwardsCompatibleFlagCallMoveInventoryFirstUseWorksheet := UseMovement;

        DidSomething := PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer);

        if not DidSomething then
            Error(RequestedInventoryMoveButUnableToFindSufficientDetailsErr, QltyInspectionTestHeader.GetFriendlyIdentifier());
    end;

    /// <summary>
    /// Provides an opportunity to modify the instruction or replace it completely.
    /// </summary>
    /// <param name="QltyInspectionTestHeader">Quality Inspection Test</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="prbDidSomething">Provides an opportunity to replace the default boolean success/fail of if it worked.</param>
    /// <param name="Handled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var prbDidSomething: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to extend the processing
    /// </summary>
    /// <param name="QltyInspectionTestHeader">Quality Inspection Test</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="prbDidSomething">Provides an opportunity to replace the default boolean success/fail of if it worked.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var prbDidSomething: Boolean)
    begin
    end;
}
