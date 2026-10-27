// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Foundation.Address;
using Microsoft.Purchases.Archive;

tableextension 31332 "Purchase Line Archive CZ" extends "Purchase Line Archive"
{
    fields
    {
        field(31305; "Physical Transfer CZ"; Boolean)
        {
            Caption = 'Physical Transfer';
            DataClassification = CustomerContent;
        }
        field(31310; "Country/Reg. of Orig. Code CZ"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
    }
}