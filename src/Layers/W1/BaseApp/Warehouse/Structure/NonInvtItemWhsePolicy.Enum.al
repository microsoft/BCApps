// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

enum 5775 "Non-Invt. Item Whse. Policy"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; "Attached/Assigned")
    {
        Caption = 'Attached/Assigned';
    }
    value(2; All)
    {
        Caption = 'All';
    }
}
