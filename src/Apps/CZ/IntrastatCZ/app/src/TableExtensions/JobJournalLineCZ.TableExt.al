// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Foundation.Address;
using Microsoft.Projects.Project.Journal;

tableextension 31304 "Job Journal Line CZ" extends "Job Journal Line"
{
    fields
    {
        field(31300; "Statistic Indication CZ"; Code[10])
        {
            Caption = 'Statistic Indication';
            TableRelation = "Statistic Indication CZ".Code;
        }
        field(31310; "Country/Reg. of Orig. Code CZ"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
    }
}