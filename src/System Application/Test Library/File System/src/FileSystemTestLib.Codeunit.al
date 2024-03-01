// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.FileSystem;

using System.FileSystem;

codeunit 80204 "File System Test Lib."
{
    Permissions = tabledata "File Scenario" = rid;

    procedure GetFileScenarioAccountIdAndFileConnector(Scenario: Enum "File Scenario"; var AccountId: Guid; var FileSystemConnector: Interface "File System Connector"): Boolean
    var
        FileScenarios: Record "File Scenario";
    begin
        if not FileScenarios.Get(Scenario) then
            exit;

        AccountId := FileScenarios."Account Id";
        FileSystemConnector := FileScenarios.Connector;
        exit(true);
    end;
}