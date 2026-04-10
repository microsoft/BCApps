// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

using System.ExternalFileStorage;

codeunit 135811 "File Scenario Mock"
{
    Permissions = tabledata "File Scenario" = rid;

    procedure AddMapping(FileScenario: Enum "File Scenario"; AccountId: Guid; Connector: Enum "Ext. File Storage Connector")
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