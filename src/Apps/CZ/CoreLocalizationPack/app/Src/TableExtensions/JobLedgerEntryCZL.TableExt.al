// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Intrastat;

tableextension 11795 "Job Ledger Entry CZL" extends "Job Ledger Entry"
{
    fields
    {
        field(11764; "Correction CZL"; Boolean)
        {
            Caption = 'Correction';
            DataClassification = CustomerContent;
        }
    }
}
