// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.Sales.History;

/// <summary>
/// Extends the Sales Cr.Memo Header table with an Avalara Document ID field for tracking posted credit memos.
/// </summary>
tableextension 6373 "Avalara Sales Cr.Memo Header" extends "Sales Cr.Memo Header"
{
    fields
    {
        field(6370; "Avalara Doc. ID"; Text[50])
        {
            Caption = 'Avalara Doc. ID';
            DataClassification = OrganizationIdentifiableInformation;
        }
    }
}
