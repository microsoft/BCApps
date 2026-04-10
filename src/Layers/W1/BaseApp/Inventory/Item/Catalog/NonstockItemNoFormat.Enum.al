// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

enum 5719 "Nonstock Item No. Format"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Vendor Item No.")
    {
        Caption = 'Vendor Item No.';
    }
    value(1; "Mfr. + Vendor Item No.")
    {
        Caption = 'Mfr. + Vendor Item No.';
    }
    value(2; "Vendor Item No. + Mfr.")
    {
        Caption = 'Vendor Item No. + Mfr.';
    }
    value(3; "Entry No.")
    {
        Caption = 'Entry No.';
    }
    value(4; "Item No. Series")
    {
        Caption = 'Item No. Series';
    }
}
