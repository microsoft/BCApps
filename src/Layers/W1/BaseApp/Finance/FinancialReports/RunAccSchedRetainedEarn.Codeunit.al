// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Executes the retained earnings statement financial report based on general ledger setup configuration.
/// Provides standardized access to the system-configured retained earnings statement report template.
/// </summary>
/// <remarks>
/// Retrieves the retained earnings statement financial report from general ledger setup and executes it
/// using the G/L Account Category Management functionality. Ensures consistent retained earnings statement
/// reporting across the application with centralized template management.
/// </remarks>
codeunit 575 "Run Acc. Sched. Retained Earn."
{

    trigger OnRun()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        GLAccountCategoryMgt.RunAccountScheduleReport(GeneralLedgerSetup."Fin. Rep. for Retained Earn.");
    end;
}

