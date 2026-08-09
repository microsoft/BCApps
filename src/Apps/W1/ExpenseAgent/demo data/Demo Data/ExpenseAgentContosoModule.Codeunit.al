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
    begin
        ExpenseAgentModuleSetup.InitRecord();
        Codeunit.Run(Codeunit::"Create Expense Payment Method");
        Codeunit.Run(Codeunit::"Create Expense No. Series DM");
        Codeunit.Run(Codeunit::"Create Expense Group");
        Codeunit.Run(Codeunit::"Create Expense G/L Account");
        Codeunit.Run(Codeunit::"Create Expense Posting Group");
        Codeunit.Run(Codeunit::"Create Expense Team");
        Codeunit.Run(Codeunit::"Create Exp. Agent Setup");
    end;

    procedure CreateMasterData()
    begin
        Codeunit.Run(Codeunit::"Create Expense Location");
        Codeunit.Run(Codeunit::"Create Expense Categories DM");
        Codeunit.Run(Codeunit::"Create Expense Subcategories");
        Codeunit.Run(Codeunit::"Create Expense Rule Header");
        Codeunit.Run(Codeunit::"Create Expense Rule Condition");
        Codeunit.Run(Codeunit::"Create Expense User");
    end;

    procedure CreateTransactionalData()
    begin
        Codeunit.Run(Codeunit::"Create Expense");
        Codeunit.Run(Codeunit::"Create Exp. Report");
    end;

    procedure CreateHistoricalData()
    begin
        Codeunit.Run(Codeunit::"Create Posted Expense Report");
    end;
}