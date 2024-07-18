// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>Holds information about emails retrieved from an inbox.</summary>
table 8886 "Email Inbox"
{
    Access = Public;
    Extensible = true;
    Description = 'The table is public so that it can also be extensible. The table is one of the modules''s extensibility endpoints.';

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
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(3; "Account Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(4; Connector; Enum "Email Connector")
        {
            DataClassification = SystemMetadata;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(5; "User Security Id"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(6; Description; Text[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(7; "Conversation Id"; Text[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(8; "External Message Id"; Text[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(9; "Sender Name"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(10; "Sender Address"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(11; "Received DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }

        field(12; "Sent DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Description = 'The field is marked as internal in order to prevent modifying it from code.';
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Get the message id of the outbox email.
    /// </summary>
    /// <returns>Message id.</returns>
    procedure GetMessageId(): Guid
    begin
        exit(Rec."Message Id");
    end;

    /// <summary>
    /// Get the account id of the outbox email.
    /// </summary>
    /// <returns>Account id.</returns>
    procedure GetAccountId(): Guid
    begin
        exit(Rec."Account Id");
    end;

    /// <summary>
    /// Get the conversation id of the email.
    /// </summary>
    /// <returns>The converation id</returns>
    /// <remarks>The conversation id links to the email message on the service provider.</remarks>
    procedure GetConversationId(): Text
    begin
        exit(Rec."Conversation Id");
    end;

    /// <summary>
    /// The email connector of the outbox email.
    /// </summary>
    /// <returns>Email connector</returns>
    procedure GetConnector(): Enum "Email Connector"
    begin
        exit(Rec.Connector);
    end;
}