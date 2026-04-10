// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;

/// <summary>
/// Manages budget initialization and filter setup for G/L Account budget analysis workflows.
/// Provides automatic budget creation and dimension filter configuration for budget analysis pages.
/// </summary>
/// <remarks>
/// Key functionality: Default budget creation, budget filter initialization, and dimension filter setup.
/// Integration: Called from G/L Account budget analysis pages and budget-related workflows.
/// Extensibility: Support for custom budget initialization logic through event subscribers.
/// </remarks>
codeunit 7 "GLBudget-Open"
{
    TableNo = "G/L Account";

    /// <summary>
    /// Initializes budget filters and creates default budget if none exists for G/L Account analysis.
    /// Automatically sets up budget context for analysis pages and ensures valid budget selection.
    /// </summary>
    trigger OnRun()
    begin
        if Rec.GetFilter("Budget Filter") = '' then
            SearchForName := true
        else begin
            GLBudgetName.SetFilter(Name, Rec.GetFilter("Budget Filter"));
            SearchForName := not GLBudgetName.FindFirst();
            GLBudgetName.SetRange(Name);
        end;
        if SearchForName then begin
            if not GLBudgetName.FindFirst() then begin
                GLBudgetName.Init();
                GLBudgetName.Name := Text000;
                GLBudgetName.Description := Text001;
                GLBudgetName.Insert();
            end;
            Rec.SetFilter("Budget Filter", GLBudgetName.Name);
        end;
    end;

    var
        GLBudgetName: Record "G/L Budget Name";
        SearchForName: Boolean;

#pragma warning disable AA0074
        Text000: Label 'DEFAULT';
        Text001: Label 'Default Budget';
#pragma warning restore AA0074

    /// <summary>
    /// Configures dimension filters and period settings for G/L Account budget analysis pages.
    /// Sets up optimal default filters and enables/disables dimension controls based on configuration.
    /// </summary>
    /// <param name="GlobalDim1Filter">Reference to Global Dimension 1 filter variable.</param>
    /// <param name="GlobalDim2Filter">Reference to Global Dimension 2 filter variable.</param>
    /// <param name="GlobalDim1FilterEnable">Reference to boolean indicating if Global Dimension 1 filter is enabled.</param>
    /// <param name="GlobalDim2FilterEnable">Reference to boolean indicating if Global Dimension 2 filter is enabled.</param>
    /// <param name="PeriodType">Reference to period type enum for analysis.</param>
    /// <param name="DateFilter">Reference to date filter string.</param>
    /// <param name="GLAccount">G/L Account record with current filter context.</param>
    procedure SetupFiltersOnGLAccBudgetPage(var GlobalDim1Filter: Text; var GlobalDim2Filter: Text; var GlobalDim1FilterEnable: Boolean; var GlobalDim2FilterEnable: Boolean; var PeriodType: Enum "Analysis Period Type"; var DateFilter: Text; var GLAccount: Record "G/L Account")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GlobalDim1Filter := GLAccount.GetFilter("Global Dimension 1 Filter");
        GlobalDim2Filter := GLAccount.GetFilter("Global Dimension 2 Filter");
        GLSetup.Get();
        GlobalDim1FilterEnable :=
          (GLSetup."Global Dimension 1 Code" <> '') and
          (GlobalDim1Filter = '');
        GlobalDim2FilterEnable :=
          (GLSetup."Global Dimension 2 Code" <> '') and
          (GlobalDim2Filter = '');
        PeriodType := PeriodType::Month;
        DateFilter := GLAccount.GetFilter("Date Filter");
        if DateFilter = '' then begin
            DateFilter := Format(CalcDate('<-CY>', Today)) + '..' + Format(CalcDate('<CY>', Today));
            GLAccount.SetFilter("Date Filter", DateFilter);
        end;
    end;
}

