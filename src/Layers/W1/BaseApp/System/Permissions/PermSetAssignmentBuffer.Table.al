// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

table 9883 "Perm. Set Assignment Buffer"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; SecurityId; Guid)
        {
            Caption = 'Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'User,Security Group';
            OptionMembers = User,SecurityGroup;
            DataClassification = SystemMetadata;
        }
        field(3; Code; Code[50])
        {
            Caption = 'Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; CompanyName; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; SecurityId)
        {
            Clustered = true;
        }
    }
}