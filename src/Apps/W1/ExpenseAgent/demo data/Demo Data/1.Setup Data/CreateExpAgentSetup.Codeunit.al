// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Foundation;
using Microsoft.DemoTool.Helpers;
using Microsoft.Foundation.AuditCodes;

codeunit 8211 "Create Exp. Agent Setup"
{
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "Expense Agent Setup" = rm;

    trigger OnRun()
    begin
        CreateExpenseAgentSetup();

        CreateSourceCode();
        UpdateSourceCodeSetup();
    end;

    local procedure CreateExpenseAgentSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CreateExpenseNoSeriesDM: Codeunit "Create Expense No. Series DM";
        CreateUnitOfMeasure: Codeunit "Create Unit of Measure";
    begin
        ExpenseAgentSetup.Get();

        ExpenseAgentSetup.Validate("Expense User Nos.", CreateExpenseNoSeriesDM.ExpenseUserSeries());
        ExpenseAgentSetup.Validate("Expense Vendor Nos.", CreateExpenseNoSeriesDM.ExpenseVendorSeries());
        ExpenseAgentSetup.Validate("Expense Reports Nos.", CreateExpenseNoSeriesDM.ExpenseReportNoSeries());
        ExpenseAgentSetup.Validate("Posted Expense Reports Nos.", CreateExpenseNoSeriesDM.PostedExpenseReportNoSeries());
        ExpenseAgentSetup.Validate("Expense Nos.", CreateExpenseNoSeriesDM.ExpenseNoSeries());
        ExpenseAgentSetup.Validate("Use Rules", false);
        ExpenseAgentSetup.Validate("Enable Agent", false);
        ExpenseAgentSetup.Validate("Exchange Rate for Expenses", Enum::"Expense Exchange Rate"::"Expense Date");
        Evaluate(ExpenseAgentSetup."Do Not Allow Exp. Older Than", '<3M>');
        ExpenseAgentSetup.Validate("Allow Grp. of Trans. in Report", true);
        ExpenseAgentSetup.Validate("Check Category/SubCat. Usage", true);
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", 1.2);
        ExpenseAgentSetup.Validate("Full Per-Diem Calculation", Enum::"Exp. Full Per Diem Calculation"::"Full Calendar Day");
        ExpenseAgentSetup.Validate("Reduction for Lunch %", 30);
        ExpenseAgentSetup.Validate("Reduction for Dinner %", 20);
        ExpenseAgentSetup.Validate("Enable Anti-Corp. Statement", true);
        ExpenseAgentSetup.Validate("Min Hours for Partial Per Diem", 8);
        ExpenseAgentSetup.Validate("Percentage For Partial Day", 50);
        ExpenseAgentSetup.Validate("Default Mileage UOM", CreateUnitOfMeasure.Miles());
        ExpenseAgentSetup.Modify(true);
    end;

    local procedure CreateSourceCode()
    var
        ContosoAuditCode: Codeunit "Contoso Audit Code";
    begin
        ContosoAuditCode.InsertSourceCode(ExpenseSourceCode(), ExpenseDescriptionTok);
    end;

    local procedure UpdateSourceCodeSetup()
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.Expense := ExpenseSourceCode();
        SourceCodeSetup.Modify(false);
    end;

    var
        ExpenseTok: Label 'EXPENSE', MaxLength = 10, Locked = true;
        ExpenseDescriptionTok: Label 'Expenses', MaxLength = 100;

    procedure ExpenseSourceCode(): Code[10]
    begin
        exit(ExpenseTok);
    end;
}