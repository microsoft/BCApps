// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Generates standard balance sheet report using predefined account schedule templates.
/// Produces formatted financial statement showing assets, liabilities, and equity positions.
/// </summary>
/// <remarks>
/// Template-driven balance sheet report using standard account schedule configuration.
/// Processes general ledger balances through account schedule engine for standardized
/// financial statement presentation. Supports period-based analysis and drill-down capabilities.
/// </remarks>
report 151 "Balance Sheet"
{
    AccessByPermission = TableData "G/L Account" = R;
    ApplicationArea = Basic, Suite;
    Caption = 'Balance Sheet';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {
        AboutTitle = 'About Balance Sheet';
        AboutText = 'The **Balance Sheet** report is a key finance report with data and layout based on a financial report definition. You can change the financial report definition used for the report on the *General Ledger Setup* page under the *Reporting* section.';

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
        GLAccountCategoryMgt.RunAccountScheduleReport(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
    end;
}

