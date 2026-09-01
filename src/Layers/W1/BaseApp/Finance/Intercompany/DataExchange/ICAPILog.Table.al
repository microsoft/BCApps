// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using System.Reflection;

table 444 "IC API Log"
{
    Access = Internal;
    Caption = 'IC API Log';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
        }
        field(3; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Outgoing,Incoming';
            OptionMembers = Outgoing,Incoming;
            DataClassification = SystemMetadata;
        }
        field(4; Method; Text[10])
        {
            Caption = 'Method';
            DataClassification = SystemMetadata;
        }
        field(5; "Request URI"; Blob)
        {
            DataClassification = CustomerContent;
        }
        field(6; "Request URI Preview"; Text[250])
        {
            Caption = 'Request URI';
            DataClassification = CustomerContent;
        }
        field(7; "Request Body"; Blob)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Response Body"; Blob)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Status Code"; Integer)
        {
            Caption = 'Status Code';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    internal procedure GetRequestURIAsText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Request URI");
        if not Rec."Request URI".HasValue() then
            exit('');
        Rec."Request URI".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    internal procedure GetRequestBodyAsText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Request Body");
        if not Rec."Request Body".HasValue() then
            exit('');
        Rec."Request Body".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    internal procedure GetResponseBodyAsText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Response Body");
        if not Rec."Response Body".HasValue() then
            exit('');
        Rec."Response Body".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    internal procedure LogEntry(PartnerCode: Code[20]; DirectionValue: Option; MethodValue: Text; Uri: Text; RequestContent: Text; ResponseContent: Text; StatusCodeValue: Integer)
    var
        OutStream: OutStream;
    begin
        Clear(Rec);
        Rec."IC Partner Code" := PartnerCode;
        Rec.Direction := DirectionValue;
        Rec.Method := CopyStr(MethodValue, 1, MaxStrLen(Rec.Method));
        Rec."Request URI Preview" := CopyStr(Uri, 1, MaxStrLen(Rec."Request URI Preview"));
        Rec."Status Code" := StatusCodeValue;
        Rec.Insert(true);

        Rec."Request URI".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Uri);

        if RequestContent <> '' then begin
            Rec."Request Body".CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(RequestContent);
        end;

        if ResponseContent <> '' then begin
            Rec."Response Body".CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(ResponseContent);
        end;

        Rec.Modify();
    end;
}
