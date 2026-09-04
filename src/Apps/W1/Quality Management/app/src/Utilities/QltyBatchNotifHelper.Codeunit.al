// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.QualityManagement.Document;

codeunit 20456 "Qlty. Batch Notif. Helper"
{
    var
        BatchCreatedQltyInspectionIds: List of [Code[20]];
        IsBatchActive: Boolean;

    /// <summary>
    /// Starts a batch and clears the tracked inspection numbers.
    /// </summary>
    internal procedure BeginBatch()
    begin
        Clear(BatchCreatedQltyInspectionIds);
        IsBatchActive := true;
    end;

    /// <summary>
    /// Ends the active batch and displays the newly created inspections when configured.
    /// </summary>
    internal procedure EndBatch()
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        if not IsBatchActive then
            exit;

        IsBatchActive := false;
        if BatchCreatedQltyInspectionIds.Count() = 0 then
            exit;

        QltyInspectionCreate.DisplayInspectionsIfConfigured(false, BatchCreatedQltyInspectionIds);
        Clear(BatchCreatedQltyInspectionIds);
    end;

    /// <summary>
    /// Tracks a newly created inspection while a batch is active.
    /// </summary>
    /// <param name="InspectionNo">The inspection number to track.</param>
    /// <param name="IsNewlyCreated">Indicates whether the inspection was newly created.</param>
    internal procedure TrackCreatedInspection(InspectionNo: Code[20]; IsNewlyCreated: Boolean)
    begin
        if not IsBatchActive then
            exit;

        if not IsNewlyCreated then
            exit;

        if InspectionNo = '' then
            exit;

        if not BatchCreatedQltyInspectionIds.Contains(InspectionNo) then
            BatchCreatedQltyInspectionIds.Add(InspectionNo);
    end;

    /// <summary>
    /// Prevents immediate inspection display while a batch is active.
    /// </summary>
    /// <param name="QltyInspectionCreate">The inspection creation codeunit to configure.</param>
    internal procedure ConfigureForBatch(var QltyInspectionCreate: Codeunit "Qlty. Inspection - Create")
    begin
        if IsBatchActive then
            QltyInspectionCreate.SetPreventDisplayingInspectionEvenIfConfigured(true);
    end;
}
