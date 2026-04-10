// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>Holds information about emails retrieved from an inbox.</summary>
table 8886 "Email Inbox"
{
    Access = Public;

    fields
    {
        field(1; Id; BigInteger)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(2; "Message Id"; Guid)
        {
            DataClassification = SystemMetadata;
            TableRelation = "Email Message".Id;
        }

        field(3; "Account Id"; Guid)
        {
            DataClassification = SystemMetadata;
        }

        field(4; Connector; Enum "Email Connector")
        {
            DataClassification = SystemMetadata;
        }

        field(5; "User Security Id"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
        }

        field(6; Description; Text[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(7; "Conversation Id"; Text[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(8; "External Message Id"; Text[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(9; "Sender Name"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }

        field(10; "Sender Address"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }

        field(11; "Received DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
        }

        field(12; "Sent DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
        }

        field(13; "Is Read"; Boolean)
        {
            DataClassification = CustomerContent;
        }

        field(14; "Is Draft"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key(MessageId; "Message Id")
        {
        }
    }
}