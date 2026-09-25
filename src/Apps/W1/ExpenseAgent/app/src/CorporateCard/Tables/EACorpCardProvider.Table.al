// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;
using System.Threading;

table 7426 "EA Corp Card Provider"
{
    Access = Internal;
    Caption = 'Corp Card Provider';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Providers";
    DrillDownPageId = "EA Corp Card Providers";
    ReplicateData = false;
    Permissions =
        tabledata "EA Corp Card" = rimd,
        tabledata "EA Corp Card Batch" = rimd,
        tabledata "EA Corp Card Exception" = rimd,
        tabledata "EA Corp Card Trans" = rimd,
        tabledata "EA Corp Card Trans Detail" = rimd,
        tabledata "Data Exch." = rimd,
        tabledata "EA Corp Card Provider" = rimd;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the code of the corporate card provider.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the description of the corporate card provider.';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the corporate card provider is enabled.';
        }
        field(4; "Feed Type"; Enum "EA Corp Card Feed Type")
        {
            Caption = 'Feed Type';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the feed type for the corporate card provider.';
        }
        field(6; "Data Exch Def Code"; Code[20])
        {
            Caption = 'Data Exchange Definition Code';
            DataClassification = SystemMetadata;
            TableRelation = "Data Exch. Def";
            ToolTip = 'Specifies the data exchange definition code for the corporate card provider.';
        }
        field(7; "Data Exch Map Code"; Code[20])
        {
            Caption = 'Data Exchange Mapping Code';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the data exchange mapping code for the corporate card provider.';
        }
        field(10; "Import Frequency (Min)"; Integer)
        {
            Caption = 'Import Frequency (Min.)';
            DataClassification = SystemMetadata;
            MinValue = 0;
            ToolTip = 'Specifies the import frequency in minutes for the corporate card provider.';
        }
        field(11; "Last Import DT"; DateTime)
        {
            Caption = 'Last Import Date-Time';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the date and time of the last import for the corporate card provider.';
        }
        field(12; "Last Batch No."; Integer)
        {
            Caption = 'Last Batch No.';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the last batch number for the corporate card provider.';
        }
        field(13; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the source file name for the corporate card provider.';
        }
        field(14; "Source Payload"; Blob)
        {
            Caption = 'Source Payload';
            DataClassification = CustomerContent;
            Subtype = Memo;
            ToolTip = 'Specifies the source payload for the corporate card provider.';
        }
        field(15; "Source Payload Record Count"; Integer)
        {
            Caption = 'Source Payload Records';
            DataClassification = SystemMetadata;
            Editable = false;
            MinValue = 0;
            ToolTip = 'Specifies the number of transaction records detected in the uploaded source payload.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        if HasRelatedData() then
            if not Confirm(DeleteProviderWithRelatedDataQst, false, Code) then
                Error(DeleteProviderCanceledErr);

        DeleteRelatedData();
    end;

    internal procedure UpdateSourcePayloadRecordCount()
    var
        PayloadInStr: InStream;
        PayloadTxt: Text;
        SourceFileNameLower: Text;
        DataExchDefCodeUpper: Text;
    begin
        CalcFields("Source Payload");
        if not "Source Payload".HasValue() then begin
            "Source Payload Record Count" := 0;
            exit;
        end;

        "Source Payload".CreateInStream(PayloadInStr, TextEncoding::UTF8);
        PayloadTxt := ReadStreamAsText(PayloadInStr);
        if PayloadTxt = '' then begin
            "Source Payload Record Count" := 0;
            exit;
        end;

        SourceFileNameLower := LowerCase("Source File Name");
        DataExchDefCodeUpper := UpperCase("Data Exch Def Code");

        if (StrPos(SourceFileNameLower, '.csv') > 0) or (StrPos(DataExchDefCodeUpper, 'CSV') > 0) then
            "Source Payload Record Count" := GetCsvRecordCount(PayloadTxt)
        else
            if (StrPos(SourceFileNameLower, 'camt054') > 0) or (StrPos(SourceFileNameLower, 'camt.054') > 0) or (StrPos(DataExchDefCodeUpper, 'CAMT054') > 0) then
                "Source Payload Record Count" := CountOccurrences(PayloadTxt, '<TxDtls>')
            else
                if (StrPos(SourceFileNameLower, 'camt') > 0) or (StrPos(DataExchDefCodeUpper, 'CAMT') > 0) then
                    "Source Payload Record Count" := CountOccurrences(PayloadTxt, '<Ntry>')
                else
                    "Source Payload Record Count" := CountOccurrences(PayloadTxt, '<Transaction>');
    end;

    local procedure ReadStreamAsText(var PayloadInStr: InStream): Text
    var
        PayloadTextBuilder: TextBuilder;
        LineTxt: Text;
    begin
        while not PayloadInStr.EOS do begin
            PayloadInStr.ReadText(LineTxt);
            PayloadTextBuilder.AppendLine(LineTxt);
        end;

        exit(PayloadTextBuilder.ToText());
    end;

    local procedure GetCsvRecordCount(PayloadTxt: Text): Integer
    var
        Count: Integer;
        Remaining: Text;
        LineTxt: Text;
        NewLinePos: Integer;
        HeaderHandled: Boolean;
        CRChar: Char;
        LFChar: Char;
    begin
        Remaining := PayloadTxt;
        CRChar := 13;
        LFChar := 10;
        while Remaining <> '' do begin
            NewLinePos := StrPos(Remaining, Format(LFChar));
            if NewLinePos = 0 then begin
                LineTxt := Remaining;
                Remaining := '';
            end else begin
                LineTxt := CopyStr(Remaining, 1, NewLinePos - 1);
                Remaining := CopyStr(Remaining, NewLinePos + 1);
            end;

            LineTxt := LineTxt.Replace(Format(CRChar), '').Trim();
            if LineTxt = '' then
                continue;

            if not HeaderHandled then begin
                HeaderHandled := true;
                if IsCsvHeaderLine(LineTxt) then
                    continue;
            end;

            Count += 1;
        end;

        exit(Count);
    end;

    local procedure IsCsvHeaderLine(LineTxt: Text): Boolean
    var
        LowerLineTxt: Text;
    begin
        LowerLineTxt := LowerCase(LineTxt);
        exit((StrPos(LowerLineTxt, 'providertransid') > 0) and (StrPos(LowerLineTxt, 'cardid') > 0));
    end;

    local procedure CountOccurrences(SourceTxt: Text; Token: Text): Integer
    var
        Count: Integer;
        Position: Integer;
        SearchFrom: Integer;
    begin
        if (SourceTxt = '') or (Token = '') then
            exit(0);

        SearchFrom := 1;
        repeat
            Position := StrPos(CopyStr(SourceTxt, SearchFrom), Token);
            if Position = 0 then
                break;

            Count += 1;
            SearchFrom := SearchFrom + Position + StrLen(Token) - 1;
        until SearchFrom > StrLen(SourceTxt);

        exit(Count);
    end;

    local procedure HasRelatedData(): Boolean
    var
        CorpCard: Record "EA Corp Card";
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardTrans: Record "EA Corp Card Trans";
        DataExch: Record "Data Exch.";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CorpCard.SetRange("Provider Code", Code);
        if not CorpCard.IsEmpty() then
            exit(true);

        CorpCardBatch.SetRange("Provider Code", Code);
        if not CorpCardBatch.IsEmpty() then
            exit(true);

        CorpCardTrans.SetRange("Provider Code", Code);
        if not CorpCardTrans.IsEmpty() then
            exit(true);

        DataExch.SetRange("Related Record", RecordId);
        if not DataExch.IsEmpty() then
            exit(true);

        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        exit(not JobQueueEntry.IsEmpty());
    end;

    local procedure DeleteRelatedData()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardBatch: Record "EA Corp Card Batch";
        DataExch: Record "Data Exch.";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        JobQueueEntry.DeleteAll(true);

        DataExch.SetRange("Related Record", RecordId);
        DataExch.DeleteAll(true);

        CorpCardBatch.SetRange("Provider Code", Code);
        CorpCardBatch.DeleteAll(true);

        CorpCard.SetRange("Provider Code", Code);
        CorpCard.DeleteAll(true);
    end;

    var
        DeleteProviderWithRelatedDataQst: Label 'Provider %1 has related corp card data or setup. Do you want to delete the provider and all related records?', Comment = '%1 = Provider code';
        DeleteProviderCanceledErr: Label 'Deletion canceled.';
}