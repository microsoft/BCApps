// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
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
        CreateExpenseCountryData: Codeunit "Create Expense Country Data";
    begin
        ExpenseAgentModuleSetup.InitRecord();
        CreateExpenseCountryData.CreateSetupData();
    end;

    procedure CreateMasterData()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CreateExpenseCountryData: Codeunit "Create Expense Country Data";
        CreateVATPostingGroups: Codeunit "Create VAT Posting Groups";
    begin
        CreateExpenseCountryData.CreateMasterData();
        if not CreateExpenseCountryData.IsVATCountry() then
            exit;

        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Default VAT Bus. Posting Group", CreateVATPostingGroups.Domestic());
        ExpenseAgentSetup.Modify(true);
        Commit();
        Codeunit.Run(Codeunit::"Create Expense VAT Rates");
    end;

    procedure CreateTransactionalData()
    var
        CreateExpenseCountryData: Codeunit "Create Expense Country Data";
    begin
        CreateExpenseCountryData.CreateTransactionalData();
    end;

    procedure CreateHistoricalData()
    var
        CreateExpenseCountryData: Codeunit "Create Expense Country Data";
    begin
        CreateExpenseCountryData.CreateHistoricalData();
    end;
}