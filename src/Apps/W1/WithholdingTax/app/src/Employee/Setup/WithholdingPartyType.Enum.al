// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

enum 6784 "Withholding Party Type"
{
    Extensible = true;
    Caption = 'Withholding Party Type';

    value(0; Vendor)
    {
        Caption = 'Vendor';
    }
    value(1; Customer)
    {
        Caption = 'Customer';
    }
    value(2; Employee)
    {
        Caption = 'Employee';
    }
}
