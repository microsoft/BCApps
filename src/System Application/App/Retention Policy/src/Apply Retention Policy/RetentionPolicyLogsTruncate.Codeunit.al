// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.DataAdministration;

codeunit 3921 "Retention Policy Logs Truncate"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Retention Policy Log Entry" = rd;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", OnTruncateRecordsIndirectPermissionRequired, '', true, true)]
    local procedure TruncateRecordsWithIndirectPermissionsOnTruncateRecordsIndirectPermissionRequired(var RecRef: RecordRef; var Handled: Boolean)
    begin
        // if someone else took it, exit
        if Handled then
            exit;

        // check if we can handle the table
        if not (RecRef.Number in [Database::"Retention Policy Log Entry"]) then
            exit;

        // delete all remaining records
        RecRef.Truncate(true);

        // set handled
        Handled := true;
    end;
}