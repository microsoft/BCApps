// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool;

codeunit 5592 "Quality Management Module" implements "Contoso Demo Data Module"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure RunConfigurationPage()
    var
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
    begin
        Message(ContosoDemoTool.GetNoConfiguirationMsg());
    end;

    procedure GetDependencies() Dependencies: List of [Enum "Contoso Demo Data Module"]
    begin
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Foundation);
    end;

    procedure CreateSetupData()
    begin
        Codeunit.Run(Codeunit::"Create Quality Lookup Value");
        Codeunit.Run(Codeunit::"Create Quality Test");
        Codeunit.Run(Codeunit::"Create Quality Insp. Result");
    end;

    procedure CreateMasterData()
    begin
        Codeunit.Run(Codeunit::"Create QM Insp. Template Hdr");
        Codeunit.Run(Codeunit::"Create QM Insp. Template Line");
        Codeunit.Run(Codeunit::"Create QM Result Condit. Conf.");
        Codeunit.Run(Codeunit::"Create QM Generation Rule");
        Codeunit.Run(Codeunit::"Create QM Generation Rule Manu");
    end;

    procedure CreateTransactionalData()
    begin
        exit;
    end;

    procedure CreateHistoricalData()
    begin
        exit;
    end;
}
