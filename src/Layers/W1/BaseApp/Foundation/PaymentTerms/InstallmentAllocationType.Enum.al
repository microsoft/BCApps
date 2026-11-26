// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

enum 8840 "Installment Allocation Type"
{
    Extensible = false;

    value(0; Percentage)
    {
        Caption = 'Percentage';
    }
    value(1; "Remaining Amount")
    {
        Caption = 'Remaining Amount';
    }
}
