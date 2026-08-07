// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 8221 "Expense Agent Country" implements "Expense Agent Country Data"
{
    Extensible = false;

    value(0; Default)
    {
        Caption = 'Default';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
    value(1; US)
    {
        Caption = 'US';
        Implementation = "Expense Agent Country Data" = "US Country Data";
    }
    value(2; GB)
    {
        Caption = 'GB';
        Implementation = "Expense Agent Country Data" = "GB Country Data";
    }
    value(3; CA)
    {
        Caption = 'CA';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
    value(4; NZ)
    {
        Caption = 'NZ';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
    value(5; AU)
    {
        Caption = 'AU';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
    value(6; ES)
    {
        Caption = 'ES';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
    value(7; DK)
    {
        Caption = 'DK';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
    value(8; FR)
    {
        Caption = 'FR';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
    value(9; DE)
    {
        Caption = 'DE';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
    value(10; AT)
    {
        Caption = 'AT';
        Implementation = "Expense Agent Country Data" = "W1 Country Data";
    }
}
