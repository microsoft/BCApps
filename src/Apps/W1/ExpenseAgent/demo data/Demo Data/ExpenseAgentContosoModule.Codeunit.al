// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool;

codeunit 8202 "Expense Agent Contoso Module" implements "Contoso Demo Data Module"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure RunConfigurationPage()
    begin
        Page.Run(Page::"Expense Agent Module Setup");
    end;

    procedure GetDependencies() Dependencies: List of [enum "Contoso Demo Data Module"]
    begin
        Dependencies.Add(Enum::"Contoso Demo Data Module"::"Human Resources Module");
        Dependencies.Add(Enum::"Contoso Demo Data Module"::"Job Module");
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Finance);
    end;

    procedure CreateSetupData()
    var
        ExpenseAgentModuleSetup: Record "Expense Agent Module Setup";
        Resolver: Codeunit "Exp. Agent Country Resolver";
        CountryData: Interface "Expense Agent Country Data";
    begin
        ExpenseAgentModuleSetup.InitRecord();
        CountryData := Resolver.Resolve();
        CountryData.CreateSetupData();
    end;

    procedure CreateMasterData()
    var
        Resolver: Codeunit "Exp. Agent Country Resolver";
        CountryData: Interface "Expense Agent Country Data";
    begin
        CountryData := Resolver.Resolve();
        CountryData.CreateMasterData();
    end;

    procedure CreateTransactionalData()
    var
        Resolver: Codeunit "Exp. Agent Country Resolver";
        CountryData: Interface "Expense Agent Country Data";
    begin
        CountryData := Resolver.Resolve();
        CountryData.CreateTransactionalData();
    end;

    procedure CreateHistoricalData()
    var
        Resolver: Codeunit "Exp. Agent Country Resolver";
        CountryData: Interface "Expense Agent Country Data";
    begin
        CountryData := Resolver.Resolve();
        CountryData.CreateHistoricalData();
    end;
}