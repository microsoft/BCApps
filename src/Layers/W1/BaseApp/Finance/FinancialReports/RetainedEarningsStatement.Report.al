// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Generates standard retained earnings statement report using predefined account schedule templates.
/// Produces formatted statement showing changes in retained earnings and equity movements.
/// </summary>
/// <remarks>
/// Template-driven retained earnings statement using standard account schedule configuration.
/// Processes equity account balances through account schedule engine for standardized
/// retained earnings presentation. Supports period-based analysis and equity movement tracking.
/// </remarks>
report 156 "Retained Earnings Statement"
{
    AccessByPermission = TableData "G/L Account" = R;
    ApplicationArea = Basic, Suite;
    Caption = 'Retained Earnings Statement';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {
        AboutTitle = 'About Retained Earnings Statement';
        AboutText = 'The **Retained Earnings Statement** report is a key finance report with data and layout based on a financial report definition. You can change the financial report definition used for the report on the *General Ledger Setup* page under the *Reporting* section.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        GLAccountCategoryMgt.RunAccountScheduleReport(GeneralLedgerSetup."Fin. Rep. for Retained Earn.");
    end;
}

