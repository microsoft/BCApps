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
        ExpAgentCountryResolver: Codeunit "Exp. Agent Country Resolver";
        ExpenseAgentCountryData: Interface "Expense Agent Country Data";
    begin
        ExpenseAgentModuleSetup.InitRecord();
        ExpenseAgentCountryData := ExpAgentCountryResolver.Resolve();
        ExpenseAgentCountryData.CreateSetupData();
    end;

    procedure CreateMasterData()
    var
        ExpAgentCountryResolver: Codeunit "Exp. Agent Country Resolver";
        ExpenseAgentCountryData: Interface "Expense Agent Country Data";
    begin
        ExpenseAgentCountryData := ExpAgentCountryResolver.Resolve();
        ExpenseAgentCountryData.CreateMasterData();
    end;

    procedure CreateTransactionalData()
    var
        ExpAgentCountryResolver: Codeunit "Exp. Agent Country Resolver";
        ExpenseAgentCountryData: Interface "Expense Agent Country Data";
    begin
        ExpenseAgentCountryData := ExpAgentCountryResolver.Resolve();
        ExpenseAgentCountryData.CreateTransactionalData();
    end;

    procedure CreateHistoricalData()
    var
        ExpAgentCountryResolver: Codeunit "Exp. Agent Country Resolver";
        ExpenseAgentCountryData: Interface "Expense Agent Country Data";
    begin
        ExpenseAgentCountryData := ExpAgentCountryResolver.Resolve();
        ExpenseAgentCountryData.CreateHistoricalData();
    end;
}