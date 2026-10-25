// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Intercompany.Setup;

/// <summary>
/// Extends Company-Initialize with Intercompany-specific initialization.
/// Ensures IC Setup record is created and the IC General Journal source code is inserted on company initialization.
/// </summary>
codeunit 8504 "IC Company Initialize"
{
    Permissions = tabledata "IC Setup" = i;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitSetupTables', '', false, false)]
    local procedure OnAfterInitSetupTablesInsertICSetup()
    var
        ICSetup: Record "IC Setup";
    begin
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
    end;
}
