// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Stores message response header data received from the Avalara E-Invoicing service.
/// </summary>
table 6379 "Message Response Header"
{
    Caption = 'Message Response Header';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
        }
        field(2; CompanyId; Text[50])
        {
            Caption = 'Company Id';
        }
        field(3; Status; Text[20])
        {
            Caption = 'Status';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
