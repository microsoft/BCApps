// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

using System.Security.AccessControl;

/// <summary>Holds information about draft emails and email that are about to be sent.</summary>
table 8890 "Email Retry"
{
    Access = Internal;
    Extensible = true;

    fields
    {
        field(1; Id; BigInteger)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(2; "Message Id"; Guid)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            TableRelation = "Email Message".Id;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(3; "Account Id"; Guid)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(4; Connector; Enum "Email Connector")
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(5; "User Security Id"; Guid)
        {
            Access = Internal;
            DataClassification = EndUserPseudonymousIdentifiers;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(6; Description; Text[2048])
        {
            Access = Internal;
            DataClassification = CustomerContent;
            Editable = false;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(7; Status; Enum "Email Status")
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(8; "Task Scheduler Id"; Guid)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(9; Sender; Code[50])
        {
            Access = Internal;
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security Id")));
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(10; "Date Queued"; DateTime)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(11; "Date Failed"; DateTime)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(12; "Send From"; Text[250])
        {
            Access = Internal;
            DataClassification = EndUserIdentifiableInformation;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(13; "Error Message"; Text[2048])
        {
            Access = Internal;
            DataClassification = CustomerContent;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(14; "Date Sending"; DateTime)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }
        field(15; "Retry No."; Integer)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
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
        key(UserSecurityId; "User Security Id")
        {
        }
        key(RetryNo; "Retry No.")
        {
        }
    }
}