// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Foundation.NoSeries;

codeunit 8203 "Create Expense No. Series DM"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoNoSeries: Codeunit "Contoso No Series";
    begin
        ContosoNoSeries.InsertNoSeries(ExpenseUserSeries(), ExpenseUserSeriesDescriptionTok, ExpenseUserStartingNoLbl, '', '', '', 1, Enum::"No. Series Implementation"::Normal, true);
        ContosoNoSeries.InsertNoSeries(ExpenseVendorSeries(), ExpenseVendorSeriesDescriptionTok, ExpenseVendorStartingNoLbl, '', '', '', 1, Enum::"No. Series Implementation"::Normal, true);
        ContosoNoSeries.InsertNoSeries(ExpenseNoSeries(), ExpenseNoSeriesDescriptionTok, ExpenseStartingNoLbl, ExpenseEndingNoLbl, '', '', 1, Enum::"No. Series Implementation"::Normal, true);
        ContosoNoSeries.InsertNoSeries(ExpenseReportNoSeries(), ExpenseReportNoSeriesDescriptionTok, ExpenseReportStartingNoLbl, ExpenseReportEndingNoLbl, '', '', 1, Enum::"No. Series Implementation"::Normal, true);
        ContosoNoSeries.InsertNoSeries(PostedExpenseReportNoSeries(), PostedExpenseReportNoSeriesDescriptionTok, PostedExpenseReportStartingNoLbl, PostedExpenseReportEndingNoLbl, '', '', 1, Enum::"No. Series Implementation"::Normal, true);
    end;

    var
        ExpenseUserSeriesTok: Label 'EXPENSEUSERS', MaxLength = 20, Locked = true;
        ExpenseUserSeriesDescriptionTok: Label 'Expense Users', MaxLength = 100;
        ExpenseUserStartingNoLbl: Label 'EXP000001', MaxLength = 20;
        ExpenseVendorSeriesTok: Label 'EXPENSEVENDORS', MaxLength = 20, Locked = true;
        ExpenseVendorSeriesDescriptionTok: Label 'Expense Vendors', MaxLength = 100;
        ExpenseVendorStartingNoLbl: Label 'EXV000001', MaxLength = 20;
        ExpenseNoSeriesTok: Label 'EXPENSE', MaxLength = 20, Locked = true;
        ExpenseNoSeriesDescriptionTok: Label 'Expenses', MaxLength = 100;
        ExpenseStartingNoLbl: Label 'EXP100001', MaxLength = 20;
        ExpenseEndingNoLbl: Label 'EXP999999', MaxLength = 20;
        ExpenseReportNoSeriesTok: Label 'EXPREP', MaxLength = 20, Locked = true;
        ExpenseReportNoSeriesDescriptionTok: Label 'Expense Reports', MaxLength = 100;
        ExpenseReportStartingNoLbl: Label 'ER100001', MaxLength = 20;
        ExpenseReportEndingNoLbl: Label 'ER999999', MaxLength = 20;
        PostedExpenseReportNoSeriesTok: Label 'P-EXPREP', MaxLength = 20, Locked = true;
        PostedExpenseReportNoSeriesDescriptionTok: Label 'Posted Expense Reports', MaxLength = 100;
        PostedExpenseReportStartingNoLbl: Label 'P-ER100001', MaxLength = 20;
        PostedExpenseReportEndingNoLbl: Label 'P-ER999999', MaxLength = 20;

    procedure ExpenseUserSeries(): Code[20]
    begin
        exit(ExpenseUserSeriesTok);
    end;

    procedure ExpenseVendorSeries(): Code[20]
    begin
        exit(ExpenseVendorSeriesTok);
    end;

    procedure ExpenseNoSeries(): Code[20]
    begin
        exit(ExpenseNoSeriesTok);
    end;

    procedure ExpenseReportNoSeries(): Code[20]
    begin
        exit(ExpenseReportNoSeriesTok);
    end;

    procedure PostedExpenseReportNoSeries(): Code[20]
    begin
        exit(PostedExpenseReportNoSeriesTok);
    end;
}