// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Integration.SyncEngine;
using System.DataAdministration;
using System.Diagnostics;
using System.Utilities;

codeunit 3993 "Base Application Logs Truncate"
{
    Access = Internal;
    Permissions =
                tabledata "Change Log Entry" = rd,
                tabledata "Error Message" = rd,
                tabledata "Error Message Register" = rd,
                tabledata "Integration Synch. Job Errors" = rd;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnTruncateRecordsIndirectPermissionRequired', '', true, true)]
    local procedure TruncateRecordsWithIndirectPermissionsOnTruncateRecordsIndirectPermissionRequired(var RecRef: RecordRef; var Handled: Boolean)
    begin
        // if someone else took it, exit
        if Handled then
            exit;

        // check if we can handle the table
        if not (RecRef.Number in [Database::"Change Log Entry",
            Database::"Integration Synch. Job Errors",
            Database::"Error Message",
            Database::"Error Message Register"])
        then
            exit;

        // delete all remaining records
        RecRef.Truncate(true);

        // set handled
        Handled := true;
    end;
}