// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

report 153 "Customer Statement"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Statement';
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

