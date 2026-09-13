// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Inventory.Location;

tableextension 7420 "Excise Location Ext" extends Location
{
    fields
    {
        field(7412; Bonded; Boolean)
        {
            Caption = 'Bonded';
            DataClassification = CustomerContent;
        }
    }
}
