// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

using Microsoft.Purchases.Vendor;

table 6540 "euBP Setup"
{
    Caption = 'euBP Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Payroll Expense Filter"; Text[250])
        {
            Caption = 'Payroll Expense Filter';
            DataClassification = CustomerContent;
        }
        field(3; "Employer Contr. Filter"; Text[250])
        {
            Caption = 'Employer Contribution Filter';
            DataClassification = CustomerContent;
        }
        field(4; "Payroll Tax Filter"; Text[250])
        {
            Caption = 'Payroll Tax Filter';
            DataClassification = CustomerContent;
        }
        field(5; "Payroll Posting Filter"; Text[250])
        {
            Caption = 'Payroll Posting Filter';
            DataClassification = CustomerContent;
        }
        field(6; "Payroll Vendor Filter"; Code[250])
        {
            Caption = 'Payroll Vendor Filter';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
            ValidateTableRelation = false;
        }
        field(7; "Sender ID"; Text[30])
        {
            Caption = 'Sender ID';
            DataClassification = CustomerContent;
        }
        field(8; "Receiver ID"; Text[30])
        {
            Caption = 'Receiver ID';
            DataClassification = CustomerContent;
        }
        field(9; "LOHN Payload"; Blob)
        {
            Caption = 'LOHN Payload';
            DataClassification = CustomerContent;
        }
        field(10; "LOHN Payload Name"; Text[250])
        {
            Caption = 'LOHN Payload Name';
            DataClassification = CustomerContent;
        }
        field(11; "LOHN Last Validated At"; DateTime)
        {
            Caption = 'LOHN Last Validated At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    internal procedure EnsureExists()
    begin
        if not Rec.Get() then
            Rec.Insert();
    end;

    internal procedure UploadLohnPayload(FileName: Text; var InputInStream: InStream)
    var
        OutputInStream: InStream;
        OutputOutStream: OutStream;
    begin
        EnsureExists();

        "LOHN Payload".CreateOutStream(OutputOutStream);
        CopyStream(OutputOutStream, InputInStream);

        "LOHN Payload Name" := CopyStr(FileName, 1, MaxStrLen("LOHN Payload Name"));
        Modify(true);

        CalcFields("LOHN Payload");
        "LOHN Payload".CreateInStream(OutputInStream, TextEncoding::UTF8);
        ValidateLohnPayload(OutputInStream);
    end;

    internal procedure ValidateStoredLohnPayload()
    var
        InputInStream: InStream;
    begin
        TestField("LOHN Payload");
        CalcFields("LOHN Payload");
        "LOHN Payload".CreateInStream(InputInStream, TextEncoding::UTF8);
        ValidateLohnPayload(InputInStream);
    end;

    internal procedure GetLohnPayloadText(): Text
    var
        InputInStream: InStream;
    begin
        if not HasLohnPayload() then
            exit('');

        CalcFields("LOHN Payload");
        "LOHN Payload".CreateInStream(InputInStream, TextEncoding::UTF8);
        exit(ReadAllText(InputInStream));
    end;

    internal procedure HasLohnPayload(): Boolean
    begin
        CalcFields("LOHN Payload");
        exit("LOHN Payload".HasValue());
    end;

    local procedure ValidateLohnPayload(var InputInStream: InStream)
    var
        EUBPXmlMgt: Codeunit "euBP XML Mgt.";
    begin
        EUBPXmlMgt.ValidateLohnPayload(ReadAllText(InputInStream));
        "LOHN Last Validated At" := CurrentDateTime();
        Modify(true);
    end;

    local procedure ReadAllText(var InputInStream: InStream): Text
    var
        TextBuilder: TextBuilder;
        Line: Text;
    begin
        while not InputInStream.EOS do begin
            InputInStream.ReadText(Line);
            TextBuilder.Append(Line);
        end;

        exit(TextBuilder.ToText());
    end;
}
