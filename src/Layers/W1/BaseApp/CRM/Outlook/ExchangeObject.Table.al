// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

table 1602 "Exchange Object"
{
    Caption = 'Exchange Object';
    DataClassification = CustomerContent;
    ReplicateData = false;
    TableType = Temporary;

    fields
    {
        field(1; "Item ID"; Text[250])
        {
            Caption = 'Item ID';
            Description = 'ID of object in Exchange.';
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            Description = 'Type of Exchange object.';
            OptionCaption = 'Email,Attachment';
            OptionMembers = Email,Attachment;
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
            Description = 'Name of the object in Exchange.';
        }
        field(4; Body; BLOB)
        {
            Caption = 'Body';
            Description = 'Body of the message.';
        }
        field(5; "Parent ID"; Text[250])
        {
            Caption = 'Parent ID';
            Description = 'ID of the parent object.';
        }
        field(6; Content; BLOB)
        {
            Caption = 'Content';
            Description = 'Content of the object.';
        }
        field(8; ViewLink; BLOB)
        {
            Caption = 'ViewLink';
            Description = 'A link to view the object in a browser.';
        }
        field(10; Owner; Guid)
        {
            Caption = 'Owner';
            DataClassification = EndUserPseudonymousIdentifiers;
            Description = 'Owner of the Exchange object.';
        }
        field(11; Selected; Boolean)
        {
            Caption = 'Selected';
            Description = 'A selection flag';
        }
        field(12; "Content Type"; Text[250])
        {
            Caption = 'Content Type';
            Description = 'The file type of the attachment';
        }
        field(13; InitiatedAction; Option)
        {
            Caption = 'InitiatedAction';
            Description = 'The action to be performed to the record';
            OptionCaption = 'InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow,InitiateSendToAttachments';
            OptionMembers = InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow,InitiateSendToAttachments;
        }
        field(15; IsInline; Boolean)
        {
            Caption = 'IsInline';
            Description = 'Indicates if the attachment is Inline';
        }
        field(18; RecId; RecordId)
        {
            Caption = 'Record ID';
            Description = 'Specifies the record ID of the entity that the exchange object is referencing.';
        }
    }

    keys
    {
        key(Key1; "Item ID")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
    }

    procedure SetBody(BodyText: Text)
    var
        OutStream: OutStream;
    begin
        CalcFields(Body);
        Clear(Body);
        Body.CreateOutStream(OutStream);
        OutStream.WriteText(BodyText);
    end;

    procedure GetBody() BodyText: Text
    var
        InStream: InStream;
    begin
        CalcFields(Body);
        Body.CreateInStream(InStream);
        InStream.ReadText(BodyText);
    end;

    procedure SetViewLink(NewLinkUrl: Text)
    var
        WriteStream: OutStream;
    begin
        CalcFields(ViewLink);
        Clear(ViewLink);
        ViewLink.CreateOutStream(WriteStream);
        WriteStream.WriteText(NewLinkUrl);
    end;

    procedure GetViewLink() UrlText: Text
    var
        ReadStream: InStream;
    begin
        CalcFields(ViewLink);
        ViewLink.CreateInStream(ReadStream);
        ReadStream.ReadText(UrlText);
    end;

    procedure SetContent(NewContent: InStream)
    var
        OutStream: OutStream;
    begin
        CalcFields(Content);
        Clear(Content);
        Content.CreateOutStream(OutStream);
        CopyStream(OutStream, NewContent);
    end;
}
