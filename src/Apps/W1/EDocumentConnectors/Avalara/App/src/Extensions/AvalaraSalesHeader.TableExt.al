// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.Document;

/// <summary>
/// Extends the Sales Header table with an Avalara Document ID field linked to the E-Document record.
/// </summary>
tableextension 6371 "Avalara Sales Header" extends "Sales Header"
{
    fields
    {
        field(6370; "Avalara Doc. ID"; Text[50])
        {
            Caption = 'Avalara Doc. ID';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            TableRelation = "E-Document"."Avalara Document Id";
        }
    }
}
