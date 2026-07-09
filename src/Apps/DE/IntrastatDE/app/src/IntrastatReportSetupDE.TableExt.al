// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

tableextension 11031 "Intrastat Report Setup DE" extends "Intrastat Report Setup"
{
    fields
    {
#pragma warning disable PTE0002
        field(11029; "Default Submission Channel"; Enum "Intrastat Submission Channel DE")
        {
            Caption = 'Default Submission Channel';
            DataClassification = CustomerContent;
        }
#pragma warning restore PTE0002
    }
}
