// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 476 "Report Inbox File Buffer"
{
    Caption = 'Report Inbox File Buffer';
    TableType = Temporary;
    Access = Internal;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(3; "Byte Size"; Integer)
        {
            Caption = 'Byte Size';
            DataClassification = SystemMetadata;
        }
        field(4; Content; Blob)
        {
            Caption = 'Content';
            DataClassification = CustomerContent;
        }
        field(5; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
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
