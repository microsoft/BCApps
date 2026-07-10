// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.DynamicsFieldService;

using System.DataAdministration;

codeunit 6619 "FS Environment Cleanup Subs"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure ClearFSConnectionOnEnvironmentCopy(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        FSConnectionSetup: Record "FS Connection Setup";
        EmptyGuid: Guid;
    begin
        if CompanyName() <> CompanyName then
            FSConnectionSetup.ChangeCompany(CompanyName);

        if not FSConnectionSetup.Get() then
            exit;

        FSConnectionSetup.DeletePassword();
        FSConnectionSetup."Is Enabled" := false;
        FSConnectionSetup."Server Address" := '';
        FSConnectionSetup."User Name" := '';
        FSConnectionSetup."User Password Key" := EmptyGuid;
        FSConnectionSetup."Connection String" := '';
        Clear(FSConnectionSetup."Server Connection String");
        FSConnectionSetup.Modify();
    end;
}
