// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Provides a processing-only report that launches the customer statement with custom layout support.
/// </summary>
report 153 "Customer Statement"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Statement';
    ToolTip = 'View a list of a customer''s transactions for a selected period, for example, to send to the customer at the close of an accounting period. You can choose to have all overdue balances displayed regardless of the period specified, or you can choose to include an aging band.';
    ProcessingOnly = true;
    UsageCategory = Documents;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {

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
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
    begin
        CustomerLayoutStatement.RunReport();
    end;
}

