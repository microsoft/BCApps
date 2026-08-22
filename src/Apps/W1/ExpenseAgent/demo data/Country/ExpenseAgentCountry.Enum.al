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
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data W1";
    }
    value(1; US)
    {
        Caption = 'US';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data US";
    }
    value(2; GB)
    {
        Caption = 'GB';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data GB";
    }
    value(3; CA)
    {
        Caption = 'CA';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data CA";
    }
    value(4; NZ)
    {
        Caption = 'NZ';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data NZ";
    }
    value(5; AU)
    {
        Caption = 'AU';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data AU";
    }
    value(6; ES)
    {
        Caption = 'ES';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data ES";
    }
    value(7; DK)
    {
        Caption = 'DK';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data DK";
    }
    value(8; FR)
    {
        Caption = 'FR';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data FR";
    }
    value(9; DE)
    {
        Caption = 'DE';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data DE";
    }
    value(10; AT)
    {
        Caption = 'AT';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data AT";
    }
    value(11; NL)
    {
        Caption = 'NL';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data NL";
    }
    value(12; BE)
    {
        Caption = 'BE';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data BE";
    }
    value(13; IT)
    {
        Caption = 'IT';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data IT";
    }
    value(14; CH)
    {
        Caption = 'CH';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data CH";
    }
    value(15; NO)
    {
        Caption = 'NO';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data NO";
    }
    value(16; FI)
    {
        Caption = 'FI';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data FI";
    }
    value(17; CZ)
    {
        Caption = 'CZ';
        Implementation = "Expense Agent Country Data" = "Create Expense Country Data CZ";
    }
}
