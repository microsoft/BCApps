// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.FileSystem;

using System.FileSystem;

codeunit 80201 "File Scenario Mock"
{
    Permissions = tabledata "File Scenario" = rid;

    procedure AddMapping(FileScenario: Enum "File Scenario"; AccountId: Guid; Connector: Enum "File System Connector")
    var
        Scenario: Record "File Scenario";
    begin
        Scenario.Scenario := FileScenario;
        Scenario."Account Id" := AccountId;
        Scenario.Connector := Connector;

        Scenario.Insert();
    end;

    procedure DeleteAllMappings()
    var
        Scenario: Record "File Scenario";
    begin
        Scenario.DeleteAll();
    end;

}