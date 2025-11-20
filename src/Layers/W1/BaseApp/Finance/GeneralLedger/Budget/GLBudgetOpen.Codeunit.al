// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;

codeunit 7 "GLBudget-Open"
{
    TableNo = "G/L Account";

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

