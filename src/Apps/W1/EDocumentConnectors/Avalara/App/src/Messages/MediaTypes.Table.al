// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Stores available media types (e.g., PDF, XML, UBL) per Avalara mandate for document download.
/// </summary>
table 6800 "Media Types"
{
    Access = Internal;
    Caption = 'Media Types';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Mandate; Text[40])
        {
            Caption = 'Mandate';
        }
        field(2; "Invoice Available Media Types"; Text[256])
        {
            Caption = 'Invoice Available Media Types';
        }
    }
    keys
    {
        key(PK; Mandate)
        {
            Clustered = true;
        }
    }
}
