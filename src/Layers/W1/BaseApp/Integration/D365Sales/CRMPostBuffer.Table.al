// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5387 "CRM Post Buffer"
{
    Caption = 'CRM Post Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
        }
        field(3; RecId; RecordID)
        {
            Caption = 'RecId';
            DataClassification = CustomerContent;
        }
        field(4; ChangeType; Option)
        {
            Caption = 'ChangeType';
            DataClassification = SystemMetadata;
            OptionCaption = ',SalesDocReleased,SalesShptHeaderCreated,SalesInvHeaderCreated';
            OptionMembers = ,SalesDocReleased,SalesShptHeaderCreated,SalesInvHeaderCreated;
        }
        field(5; ChangeDateTime; DateTime)
        {
            Caption = 'ChangeDateTime';
            DataClassification = SystemMetadata;
        }
        field(6; Message; Text[2048])
        {
            Caption = 'Message';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

