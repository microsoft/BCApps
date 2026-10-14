// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6902 "Credit Card Issuer"
{
    Access = Internal;
    Caption = 'Credit Card Issuer';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Visa)
    {
        Caption = 'Visa';
    }
    value(2; Mastercard)
    {
        Caption = 'Mastercard';
    }
    value(3; AMEX)
    {
        Caption = 'AMEX';
    }
    value(4; Other)
    {
        Caption = 'Other';
    }
}