// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.QualityManagement.Document;

codeunit 20456 "Qlty. Batch Notif. Helper"
{
    var
        BatchCreatedInspectionIds: List of [Code[20]];
        IsBatchActive: Boolean;

    internal procedure BeginBatch()
    begin
        Clear(BatchCreatedInspectionIds);
        IsBatchActive := true;
    end;

    internal procedure EndBatch()
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        if not IsBatchActive then
            exit;

        IsBatchActive := false;
        if BatchCreatedInspectionIds.Count() = 0 then
            exit;

        QltyInspectionCreate.DisplayInspectionsIfConfigured(false, BatchCreatedInspectionIds);
        Clear(BatchCreatedInspectionIds);
    end;

    internal procedure TrackCreatedInspection(InspectionNo: Code[20])
    begin
        if not IsBatchActive then
            exit;

        if InspectionNo = '' then
            exit;

        if not BatchCreatedInspectionIds.Contains(InspectionNo) then
            BatchCreatedInspectionIds.Add(InspectionNo);
    end;

    internal procedure ConfigureForBatch(var QltyInspectionCreate: Codeunit "Qlty. Inspection - Create")
    begin
        if IsBatchActive then
            QltyInspectionCreate.SetPreventDisplayingInspectionEvenIfConfigured(true);
    end;
}
