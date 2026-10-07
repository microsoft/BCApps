// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Dataverse;

codeunit 139202 "CDS Cleanup Test Subscribers"
{
    // Used by "CDS Integration Mgt Test" to force Record.Truncate to be unsupported for the
    // "CRM Integration Record" table. A subscriber on one of the table's delete events makes
    // Truncate return false, which exercises the DeleteAll fallback in CleanCDSIntegration.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"CRM Integration Record", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteCRMIntegrationRecord(var Rec: Record "CRM Integration Record"; RunTrigger: Boolean)
    begin
    end;
}
