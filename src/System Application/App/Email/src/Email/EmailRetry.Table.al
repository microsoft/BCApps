// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

using System.Security.AccessControl;

table 8890 "Email Retry"
{
    Access = Internal;

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
        }
        field(3; "Account Id"; Guid)
        {
            Access = Internal;
            DataClassification = CustomerContent;
        }
        field(4; Connector; Enum "Email Connector")
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(5; "User Security Id"; Guid)
        {
            Access = Internal;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(6; Description; Text[2048])
        {
            Access = Internal;
            DataClassification = CustomerContent;
        }
        field(7; Status; Enum "Email Status")
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(8; "Task Scheduler Id"; Guid)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(9; Sender; Code[50])
        {
            Access = Internal;
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security Id")));
        }
        field(10; "Date Queued"; DateTime)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(11; "Date Failed"; DateTime)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(12; "Send From"; Text[250])
        {
            Access = Internal;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Error Message"; Text[2048])
        {
            Access = Internal;
            DataClassification = CustomerContent;
        }
        field(14; "Date Sending"; DateTime)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(15; "Retry No."; Integer)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
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