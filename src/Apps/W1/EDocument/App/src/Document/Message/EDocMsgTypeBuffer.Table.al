// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Temporary buffer used to populate the "E-Document Message Lookup" modal page with the
/// applicable message types per context.
/// </summary>
table 6143 "E-Doc. Msg. Type Buffer"
{
    Caption = 'E-Document Message Type Buffer';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Message Type"; Enum "E-Document Message Type")
        {
            Caption = 'Message Type';
        }
        field(2; Caption; Text[100])
        {
            Caption = 'Caption';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Message Type") { Clustered = true; }
    }
}
