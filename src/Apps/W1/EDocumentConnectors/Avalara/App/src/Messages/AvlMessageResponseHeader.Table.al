// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Stores message response header data received from the Avalara E-Invoicing service.
/// </summary>
table 6379 "Avl Message Response Header"
{
    Access = Internal;
    Caption = 'Message Response Header';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
        }
        field(2; CompanyId; Text[50])
        {
            Caption = 'Company Id';
        }
        field(3; Status; Text[20])
        {
            Caption = 'Status';
        }
        field(4; "Full Response"; Blob)
        {
            Caption = 'Full Response';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    procedure SetFullResponse(ResponseText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Full Response".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(ResponseText);
    end;

    procedure GetFullResponse(): Text
    var
        InStream: InStream;
        ResponseText: Text;
    begin
        Rec.CalcFields("Full Response");
        if not Rec."Full Response".HasValue() then
            exit('');
        Rec."Full Response".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(ResponseText);
        exit(ResponseText);
    end;
}
