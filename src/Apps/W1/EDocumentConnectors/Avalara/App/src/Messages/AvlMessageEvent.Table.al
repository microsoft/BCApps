// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Stores event records from Avalara document processing, including status messages and response data.
/// </summary>
table 6380 "Avl Message Event"
{
    Access = Internal;
    Caption = 'Message Event';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
        }
        field(2; MessageRow; Integer)
        {
            Caption = 'Row';
        }
        field(3; EventDateTime; DateTime)
        {
            Caption = 'Event Date Time';
        }
        field(4; Message; Text[256])
        {
            Caption = 'Message';
        }
        field(5; ResponseKey; Text[256])
        {
            Caption = 'Response Key';
        }
        field(6; ResponseValue; Text[256])
        {
            Caption = 'Response Value';
        }
        field(7; PostedDocument; Text[40])
        {
            Caption = 'Posted Document';
        }
        field(8; EDocEntryNo; Integer)
        {
            Caption = 'EDoc Entry No';
        }
        field(9; "Full Message"; Blob)
        {
            Caption = 'Full Message';
        }
    }
    keys
    {
        key(PK; Id, MessageRow)
        {
            Clustered = true;
        }
    }

    procedure SetFullMessage(MessageText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Full Message".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(MessageText);
    end;

    procedure GetFullMessage(): Text
    var
        InStream: InStream;
        MessageText: Text;
    begin
        Rec.CalcFields("Full Message");
        if not Rec."Full Message".HasValue() then
            exit(Rec.Message);
        Rec."Full Message".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(MessageText);
        exit(MessageText);
    end;
}
