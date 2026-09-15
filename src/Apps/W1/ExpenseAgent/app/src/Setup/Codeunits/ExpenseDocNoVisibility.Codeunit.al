// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;
using Microsoft.Utilities;

codeunit 6900 "Expense Doc No Visibility"
{
    SingleInstance = true;

    var
        ExpenseDocsNoVisible: Dictionary of [Integer, Boolean];
        IsExpenseUserNoInitialized: Boolean;
        ExpenseUserNoVisible: Boolean;

    procedure ExpenseDocumentNoIsVisible(DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        DocNoVisibility: Codeunit DocumentNoVisibility;
        ExpenseAgentSetup: Page "Expense Agent Setup";
        DocNoSeries: Code[20];
        Result: Boolean;
    begin
        if DocNo <> '' then
            exit(false);

        if ExpenseDocsNoVisible.ContainsKey(Database::Expense) then
            exit(ExpenseDocsNoVisible.Get(Database::Expense));

        DocNoSeries := DetermineExpenseSeriesNo();
        if not NoSeries.Get(DocNoSeries) then begin
            ExpenseAgentSetup.RunModal();
            DocNoSeries := DetermineExpenseSeriesNo();
        end;
        Result := DocNoVisibility.ForceShowNoSeriesForDocNo(DocNoSeries);
        ExpenseDocsNoVisible.Add(Database::Expense, Result);

        exit(Result);
    end;

    procedure ExpenseReportDocumentNoIsVisible(DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        DocNoVisibility: Codeunit DocumentNoVisibility;
        ExpenseAgentSetup: Page "Expense Agent Setup";
        DocNoSeries: Code[20];
        Result: Boolean;
    begin
        if DocNo <> '' then
            exit(false);

        if ExpenseDocsNoVisible.ContainsKey(Database::"Expense Report Header") then
            exit(ExpenseDocsNoVisible.Get(Database::"Expense Report Header"));

        DocNoSeries := DetermineExpenseReportSeriesNo();
        if not NoSeries.Get(DocNoSeries) then begin
            ExpenseAgentSetup.RunModal();
            DocNoSeries := DetermineExpenseReportSeriesNo();
        end;
        Result := DocNoVisibility.ForceShowNoSeriesForDocNo(DocNoSeries);
        ExpenseDocsNoVisible.Add(Database::"Expense Report Header", Result);

        exit(Result);
    end;

    procedure ExpenseUserNoIsVisible(): Boolean
    var
        DocNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
    begin
        if IsExpenseUserNoInitialized then
            exit(ExpenseUserNoVisible);

        IsExpenseUserNoInitialized := true;

        NoSeriesCode := DetermineExpenseUserSeriesNo();
        ExpenseUserNoVisible := DocNoVisibility.ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ExpenseUserNoVisible);
    end;

    local procedure DetermineExpenseSeriesNo(): Code[20]
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        exit(ExpenseAgentSetup."Expense Nos.");
    end;

    local procedure DetermineExpenseReportSeriesNo(): Code[20]
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        exit(ExpenseAgentSetup."Expense Reports Nos.");
    end;

    local procedure DetermineExpenseUserSeriesNo(): Code[20]
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        exit(ExpenseAgentSetup."Expense User Nos.");
    end;
}