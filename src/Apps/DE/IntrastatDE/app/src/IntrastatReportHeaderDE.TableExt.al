// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

tableextension 11030 "Intrastat Report Header DE" extends "Intrastat Report Header"
{
    fields
    {
#pragma warning disable PTE0002
        field(11029; "Test Submission"; Boolean)
        {
            Caption = 'Test Submission';
            DataClassification = CustomerContent;
        }
        field(11030; "Submission Channel"; Enum "Intrastat Submission Channel DE")
        {
            Caption = 'Submission Channel';
            DataClassification = CustomerContent;
        }
#pragma warning restore PTE0002
    }
}
