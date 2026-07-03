// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.QualityManagement.Document;

/// <summary>
/// Manually-bound subscriber used to mark the reopen/finish inspection integration
/// events as handled, so tests can verify the status-change guard is reset on the
/// handled early-exit paths.
/// </summary>
codeunit 139973 "Qlty. Change Status Subscr."
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. Inspection Header", 'OnBeforeReopenInspection', '', false, false)]
    local procedure HandleReopenInspection(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. Inspection Header", 'OnBeforeFinishInspection', '', false, false)]
    local procedure HandleFinishInspection(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
