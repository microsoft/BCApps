// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6984 "EA Outbox Email"
{
    Access = Internal;
    Caption = 'EA Outbox Email';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = X;
    Description = 'This table stores outbound emails queued for sending by the Expense Agent.';
    ReplicateData = false;

    fields
    {
        field(1; Id; BigInteger)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; Subject; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(3; Body; Blob)
        {
            DataClassification = CustomerContent;
        }
        field(4; "HTML Formatted Body"; Boolean)
        {
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(5; Status; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = Pending,Sent,Failed,Rejected;
            OptionCaption = 'Pending,Sent,Failed,Rejected', Comment = 'Pending = waiting to be sent, Sent = successfully sent, Failed = send failed, Rejected = recipient not allowed';
            InitValue = Pending;
        }
        field(6; "Retry Count"; Integer)
        {
            DataClassification = SystemMetadata;
            InitValue = 0;
            MinValue = 0;
        }
        field(7; "Correlation Id"; Guid)
        {
            Caption = 'Correlation Id';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the identifier that correlates this outbox email with the notification that created it (for example, a welcome email for an expense user).';
        }
        field(8; "Notification Type"; Enum "EA Notification Type")
        {
            Caption = 'Notification Type';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the kind of notification this outbox email represents.';
        }
        field(20; ToLine; Text[2048])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; CCLine; Text[2048])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(40; BCCLine; Text[2048])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key(StatusKey; Status)
        {
        }
        key(CorrelationKey; "Correlation Id")
        {
        }
    }

    procedure ReadBody() BodyText: Text
    var
        BodyInStream: InStream;
        Line: Text;
    begin
        Rec.CalcFields(Body);

        if Body.HasValue() then begin
            Body.CreateInStream(BodyInStream, TextEncoding::UTF8);
            repeat
                BodyInStream.ReadText(Line);
                BodyText += Line;
            until BodyInStream.EOS();
        end;

    end;

    procedure WriteBody(BodyText: Text)
    var
        BodyOutStream: OutStream;
    begin
        Rec.CalcFields(Body);

        Body.CreateOutStream(BodyOutStream, TextEncoding::UTF8);
        BodyOutStream.WriteText(BodyText);
    end;
}
