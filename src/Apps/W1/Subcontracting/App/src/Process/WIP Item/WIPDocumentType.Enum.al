// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 99001509 "WIP Document Type"
{
    Extensible = true;
    value(0; "Transfer Order")
    {
        Caption = 'Transfer Order';
    }
    value(1; "Adjustment (Manual)")
    {
        Caption = 'Adjustment (Manual)';
    }
    value(2; "Adjustment (Finish Prod Order)")
    {
        Caption = 'Adjustment (Finish Prod Order)';
    }
}
