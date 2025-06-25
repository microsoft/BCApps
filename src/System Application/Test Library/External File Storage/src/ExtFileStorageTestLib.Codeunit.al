// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

using System.ExternalFileStorage;

codeunit 135813 "Ext. File Storage Test Lib."
{
    Permissions = tabledata "File Scenario" = rid;

    procedure GetFileScenarioAccountIdAndFileConnector(Scenario: Enum "File Scenario"; var AccountId: Guid; var ExternalFileStorageConnector: Interface "External File Storage Connector"): Boolean
    var
        FileScenarios: Record "File Scenario";
    begin
        if not FileScenarios.Get(Scenario) then
            exit;

        AccountId := FileScenarios."Account Id";
        ExternalFileStorageConnector := FileScenarios.Connector;
        exit(true);
    end;
}