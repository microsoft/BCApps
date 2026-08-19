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

    internal procedure BeginBatch()
    begin
        Clear(BatchCreatedQltyInspectionIds);
        IsBatchActive := true;
    end;

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

    internal procedure ConfigureForBatch(var QltyInspectionCreate: Codeunit "Qlty. Inspection - Create")
    begin
        if IsBatchActive then
            QltyInspectionCreate.SetPreventDisplayingInspectionEvenIfConfigured(true);
    end;
}
