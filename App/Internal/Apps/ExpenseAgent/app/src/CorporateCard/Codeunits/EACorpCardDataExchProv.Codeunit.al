// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;
using System.Utilities;

codeunit 7243 EACorpCardDataExchProv implements IEACorpCardProvider
{
    Access = Internal;
    Permissions = tabledata "Data Exch." = rimd,
                  tabledata "Data Exch. Def" = rm,
                  tabledata "Data Exch. Mapping" = rimd,
                  tabledata "Data Exch. Field" = rimd,
                  tabledata "Data Exch. Field Mapping" = r;

    var
        ProviderDefCodeMissingErr: Label 'Data Exchange Definition Code must be set on provider %1.', Comment = '%1 = Provider code';
        InvalidTransErr: Label 'Mandatory data is missing for provider transaction %1.', Comment = '%1 = Provider transaction ID';
        NoParsedLinesErr: Label 'No transaction lines were parsed from file %1 for provider %2. Verify Data Exchange definition %3 and mapping %4.', Comment = '%1 = file name, %2 = provider code, %3 = Data Exch Def Code, %4 = Data Exch Line Def Code';
        NonCsvFallbackErr: Label 'No Data Exchange fields were parsed for non-CSV provider %1 (feed type %2). Verify Data Exchange definition %3 and line mapping %4.', Comment = '%1 = provider code, %2 = feed type, %3 = Data Exch Def Code, %4 = Data Exch Line Def Code';

    procedure Download(var CorpCardBatch: Record EACorpCardBatch)
    var
        DataExch: Record "Data Exch.";
        CorpCardProvider: Record EACorpCardProvider;
        CreateCorpCardSetup: Codeunit "Create Corp Card Setup";
    begin
        CorpCardProvider.Get(CorpCardBatch."Provider Code");
        CreateCorpCardSetup.EnsureDataExchangeForProvider(CorpCardProvider);
        if CorpCardProvider."Data Exch Def Code" = '' then
            Error(ProviderDefCodeMissingErr, CorpCardProvider.Code);

        DataExch.Init();
        DataExch."Data Exch. Def Code" := CorpCardProvider."Data Exch Def Code";
        DataExch."Data Exch. Line Def Code" := CorpCardProvider."Data Exch Map Code";
        DataExch."Related Record" := CorpCardProvider.RecordId;
        DataExch.Insert(true);

        InjectSourceContent(CorpCardProvider, CorpCardBatch, DataExch);

        CorpCardBatch."Data Exch Entry No." := DataExch."Entry No.";
        CorpCardBatch."Source Ref" := CopyStr(
            StrSubstNo('%1:%2', DataExch."Data Exch. Def Code", DataExch."Entry No."),
            1,
            MaxStrLen(CorpCardBatch."Source Ref"));
        CorpCardBatch.Modify();

        OnAfterCreateDataExch(CorpCardProvider, CorpCardBatch, DataExch);
    end;

    procedure ParseToStaging(BatchNo: Integer)
    var
        CorpCardBatch: Record EACorpCardBatch;
        CorpCardProvider: Record EACorpCardProvider;
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        CorpCardMapMgt: Codeunit EACorpCardMapMgt;
        CreateCorpCardSetup: Codeunit "Create Corp Card Setup";
        PostImportOrch: Codeunit EACorpCardPostImportOrch;
    begin
        CorpCardBatch.Get(BatchNo);
        if CorpCardBatch."Data Exch Entry No." = 0 then
            exit;

        CorpCardProvider.Get(CorpCardBatch."Provider Code");
        CreateCorpCardSetup.EnsureDataExchangeForProvider(CorpCardProvider);
        DataExch.Get(CorpCardBatch."Data Exch Entry No.");
        EnsureDataExchFileContentFromProviderPayload(DataExch, CorpCardProvider);
        if DataExch."Data Exch. Line Def Code" = '' then begin
            DataExch."Data Exch. Line Def Code" := CorpCardProvider."Data Exch Map Code";
            DataExch.Modify(true);
        end;
        DataExchDef.Get(CorpCardProvider."Data Exch Def Code");
        CorpCardMapMgt.ValidateMandatoryFieldMappings(CorpCardProvider);

        if not DataExch.ImportToDataExch(DataExchDef) then begin
            CorpCardBatch.Status := CorpCardBatch.Status::Failed;
            CorpCardBatch.Rejected += 1;
            CorpCardBatch.Modify();
            exit;
        end;

        if HasParsedFields(DataExch) then
            MapDataExchToTrans(CorpCardBatch, CorpCardProvider, DataExch)
        else
            if CorpCardProvider."Feed Type" = CorpCardProvider."Feed Type"::CSV then
                ParseCsvPayloadToTrans(CorpCardBatch, CorpCardProvider, DataExch)
            else begin
                CorpCardBatch.Status := CorpCardBatch.Status::Failed;
                CorpCardBatch.Rejected += 1;
                CorpCardBatch.Modify();
                Error(NonCsvFallbackErr, CorpCardProvider.Code, CorpCardProvider."Feed Type", CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code");
            end;

        PostImportOrch.ProcessBatchPostImport(BatchNo);
    end;

    procedure Ack(BatchNo: Integer)
    begin
        OnAfterAck(BatchNo);
    end;

    local procedure InjectSourceContent(CorpCardProvider: Record EACorpCardProvider; CorpCardBatch: Record EACorpCardBatch; var DataExch: Record "Data Exch.")
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        SourceFileName: Text[250];
        Handled: Boolean;
    begin
        Handled := false;
        OnProvideSourceContent(CorpCardProvider, CorpCardBatch, TempBlob, SourceFileName, Handled);
        if not Handled then
            exit;

        TempBlob.CreateInStream(InStr);
        DataExch."File Content".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);

        if SourceFileName <> '' then
            DataExch."File Name" := CopyStr(SourceFileName, 1, MaxStrLen(DataExch."File Name"));

        DataExch.Modify();
    end;

    local procedure EnsureDataExchFileContentFromProviderPayload(var DataExch: Record "Data Exch."; CorpCardProvider: Record EACorpCardProvider)
    var
        ProviderRefreshed: Record EACorpCardProvider;
        SourceInStr: InStream;
        TargetOutStr: OutStream;
    begin
        if not ProviderRefreshed.Get(CorpCardProvider.Code) then
            exit;

        ProviderRefreshed.CalcFields("Source Payload");
        if not ProviderRefreshed."Source Payload".HasValue() then
            exit;

        ProviderRefreshed."Source Payload".CreateInStream(SourceInStr);
        DataExch."File Content".CreateOutStream(TargetOutStr);
        CopyStream(TargetOutStr, SourceInStr);

        if ProviderRefreshed."Source File Name" <> '' then
            DataExch."File Name" := CopyStr(ProviderRefreshed."Source File Name", 1, MaxStrLen(DataExch."File Name"));

        DataExch.Modify();
    end;

    local procedure HasParsedFields(DataExch: Record "Data Exch."): Boolean
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        exit(not DataExchField.IsEmpty());
    end;

    local procedure ParseCsvPayloadToTrans(var CorpCardBatch: Record EACorpCardBatch; CorpCardProvider: Record EACorpCardProvider; DataExch: Record "Data Exch.")
    var
        CorpCardTrans: Record EACorpCardTrans;
        CorpCardDedupMgt: Codeunit EACorpCardDedupMgt;
        CorpCardValidateMgt: Codeunit EACorpCardValidateMgt;
        InStr: InStream;
        LineTxt: Text;
        IsHeader: Boolean;
        ValidationReason: Text[250];
    begin
        DataExch.CalcFields("File Content");
        if not DataExch."File Content".HasValue() then
            exit;

        DataExch."File Content".CreateInStream(InStr);
        IsHeader := true;
        while not InStr.EOS do begin
            InStr.ReadText(LineTxt);
            LineTxt := DelChr(LineTxt, '<>', ' ');
            if LineTxt = '' then
                continue;

            if IsHeader then begin
                IsHeader := false;
                if IsHeaderLine(LineTxt) then
                    continue;
            end;

            Clear(CorpCardTrans);
            CorpCardTrans.Init();
            CorpCardTrans."Batch No." := CorpCardBatch."Batch No.";
            CorpCardTrans."Provider Code" := CorpCardProvider.Code;
            CorpCardTrans.Status := CorpCardTrans.Status::Imported;

            MapCsvLineToTrans(LineTxt, CorpCardTrans);

            ValidationReason := '';
            if not CorpCardValidateMgt.ValidateTrans(CorpCardTrans, ValidationReason) then begin
                CorpCardTrans.Status := CorpCardTrans.Status::Exception;
                if ValidationReason = '' then
                    ValidationReason := StrSubstNo(InvalidTransErr, CorpCardTrans."Provider Trans Id");
                InsertException(CorpCardBatch, CorpCardTrans, Enum::EACorpCardExcpType::Validation, ValidationReason);
                CorpCardBatch.Exceptions += 1;
                CorpCardBatch.Rejected += 1;
                continue;
            end;

            if CorpCardDedupMgt.IsDuplicate(CorpCardTrans) then begin
                CorpCardBatch.Duplicates += 1;
                continue;
            end;

            CorpCardTrans.Insert(true);
            CorpCardBatch.Imported += 1;
        end;

        CorpCardBatch.Modify();

        if CorpCardBatch.Imported = 0 then begin
            CorpCardBatch.Status := CorpCardBatch.Status::Failed;
            CorpCardBatch.Rejected += 1;
            CorpCardBatch.Modify();
            Error(NoParsedLinesErr, DataExch."File Name", CorpCardProvider.Code, CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code");
        end;
    end;

    local procedure IsHeaderLine(LineTxt: Text): Boolean
    begin
        exit((StrPos(LowerCase(LineTxt), 'providertransid') > 0) and (StrPos(LineTxt, ',') > 0));
    end;

    local procedure MapCsvLineToTrans(LineTxt: Text; var CorpCardTrans: Record EACorpCardTrans)
    var
        DateTxt: Text;
        PostingDateTxt: Text;
        AmountTxt: Text;
    begin
        CorpCardTrans."Provider Trans Id" := CopyStr(GetCsvField(LineTxt, 1), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Card Id" := CopyStr(GetCsvField(LineTxt, 2), 1, MaxStrLen(CorpCardTrans."Card Id"));

        DateTxt := GetCsvField(LineTxt, 3);
        if not ParseIsoDate(DateTxt, CorpCardTrans."Trans Date") then
            Evaluate(CorpCardTrans."Trans Date", DateTxt);

        PostingDateTxt := GetCsvField(LineTxt, 4);
        if ParseIsoDate(PostingDateTxt, CorpCardTrans."Posting Date") then
            Evaluate(CorpCardTrans."Posting Date", PostingDateTxt);

        AmountTxt := NormalizeDecimalText(GetCsvField(LineTxt, 5));
        Evaluate(CorpCardTrans.Amount, AmountTxt);

        CorpCardTrans."Currency Code" := CopyStr(GetCsvField(LineTxt, 6), 1, MaxStrLen(CorpCardTrans."Currency Code"));
        CorpCardTrans."Merchant Raw" := CopyStr(GetCsvField(LineTxt, 7), 1, MaxStrLen(CorpCardTrans."Merchant Raw"));
        CorpCardTrans.MCC := CopyStr(GetCsvField(LineTxt, 8), 1, MaxStrLen(CorpCardTrans.MCC));
        CorpCardTrans.Country := CopyStr(GetCsvField(LineTxt, 9), 1, MaxStrLen(CorpCardTrans.Country));
    end;

    local procedure GetCsvField(LineTxt: Text; FieldIndex: Integer): Text
    var
        FieldTxt: Text;
        CommaCount: Integer;
    begin
        CommaCount := StrLen(LineTxt) - StrLen(DelChr(LineTxt, '=', ','));
        if FieldIndex > (CommaCount + 1) then
            exit('');

        FieldTxt := SelectStr(FieldIndex, LineTxt);
        exit(DelChr(FieldTxt, '=', '"'));
    end;

    local procedure ParseIsoDate(DateTxt: Text; var ParsedDate: Date): Boolean
    var
        YearNo: Integer;
        MonthNo: Integer;
        DayNo: Integer;
    begin
        if StrLen(DateTxt) < 10 then
            exit(false);
        if (CopyStr(DateTxt, 5, 1) <> '-') or (CopyStr(DateTxt, 8, 1) <> '-') then
            exit(false);

        if not Evaluate(YearNo, CopyStr(DateTxt, 1, 4)) then
            exit(false);
        if not Evaluate(MonthNo, CopyStr(DateTxt, 6, 2)) then
            exit(false);
        if not Evaluate(DayNo, CopyStr(DateTxt, 9, 2)) then
            exit(false);

        ParsedDate := DMY2Date(DayNo, MonthNo, YearNo);
        exit(true);
    end;

    local procedure NormalizeDecimalText(AmountTxt: Text): Text
    var
        DecimalSeparatorTxt: Text;
    begin
        DecimalSeparatorTxt := DelChr(Format(1.1), '=', '0123456789');
        if DecimalSeparatorTxt = ',' then
            exit(ConvertStr(AmountTxt, '.', ','));
        exit(AmountTxt);
    end;

    local procedure MapDataExchToTrans(var CorpCardBatch: Record EACorpCardBatch; CorpCardProvider: Record EACorpCardProvider; DataExch: Record "Data Exch.")
    var
        CorpCardTrans: Record EACorpCardTrans;
        DataExchField: Record "Data Exch. Field";
        DataExchFieldPerLine: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TempFieldIdsToNegate: Record Integer temporary;
        ProcessDataExch: Codeunit "Process Data Exch.";
        CorpCardDedupMgt: Codeunit EACorpCardDedupMgt;
        CorpCardValidateMgt: Codeunit EACorpCardValidateMgt;
        CorpCardRecRef: RecordRef;
        CurrentLineNo: Integer;
        ValidationReason: Text[250];
    begin
        DataExchField.SetAutoCalcFields("Data Exch. Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if not DataExchField.FindSet() then
            exit;

        CurrentLineNo := -1;
        repeat
            if CurrentLineNo = DataExchField."Line No." then
                continue;

            CurrentLineNo := DataExchField."Line No.";
            TempFieldIdsToNegate.DeleteAll();

            Clear(CorpCardTrans);
            CorpCardTrans.Init();
            CorpCardTrans."Batch No." := CorpCardBatch."Batch No.";
            CorpCardTrans."Provider Code" := CorpCardProvider.Code;
            CorpCardTrans.Status := CorpCardTrans.Status::Imported;

            CorpCardRecRef.GetTable(CorpCardTrans);

            DataExchFieldPerLine.Reset();
            DataExchFieldPerLine.SetAutoCalcFields("Data Exch. Def Code");
            DataExchFieldPerLine.SetRange("Data Exch. No.", DataExch."Entry No.");
            DataExchFieldPerLine.SetRange("Line No.", CurrentLineNo);
            if DataExchFieldPerLine.FindSet() then
                repeat
                    if not FindFieldMapping(DataExchFieldPerLine, DataExchFieldMapping) then
                        continue;

                    ProcessDataExch.SetField(CorpCardRecRef, DataExchFieldMapping, DataExchFieldPerLine, TempFieldIdsToNegate);
                until DataExchFieldPerLine.Next() = 0;

            ProcessDataExch.NegateAmounts(CorpCardRecRef, TempFieldIdsToNegate);
            CorpCardRecRef.SetTable(CorpCardTrans);
            NormalizeMappedTransFields(CorpCardTrans);

            ValidationReason := '';
            if not CorpCardValidateMgt.ValidateTrans(CorpCardTrans, ValidationReason) then begin
                CorpCardTrans.Status := CorpCardTrans.Status::Exception;
                if ValidationReason = '' then
                    ValidationReason := StrSubstNo(InvalidTransErr, CorpCardTrans."Provider Trans Id");
                InsertException(CorpCardBatch, CorpCardTrans, Enum::EACorpCardExcpType::Validation, ValidationReason);
                CorpCardBatch.Exceptions += 1;
                CorpCardBatch.Rejected += 1;
                continue;
            end;

            if CorpCardDedupMgt.IsDuplicate(CorpCardTrans) then begin
                CorpCardBatch.Duplicates += 1;
                continue;
            end;

            CorpCardTrans.Insert(true);
            CorpCardBatch.Imported += 1;
        until DataExchField.Next() = 0;

        CorpCardBatch.Modify();
    end;

    local procedure FindFieldMapping(DataExchField: Record "Data Exch. Field"; var DataExchFieldMapping: Record "Data Exch. Field Mapping"): Boolean
    begin
        DataExchFieldMapping.Reset();
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchField."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchField."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", Database::EACorpCardTrans);
        DataExchFieldMapping.SetRange("Column No.", DataExchField."Column No.");

        exit(DataExchFieldMapping.FindFirst());
    end;

    local procedure InsertException(CorpCardBatch: Record EACorpCardBatch; CorpCardTrans: Record EACorpCardTrans; ExcpType: Enum EACorpCardExcpType; Message: Text[250])
    var
        CorpCardException: Record EACorpCardException;
    begin
        CorpCardException.Init();
        CorpCardException."Batch No." := CorpCardBatch."Batch No.";
        CorpCardException."Trans Entry No." := CorpCardTrans."Entry No.";
        CorpCardException."Exception Type" := ExcpType;
        CorpCardException.Message := Message;
        CorpCardException."Created DT" := CurrentDateTime();
        CorpCardException.Insert(true);
    end;

    local procedure NormalizeMappedTransFields(var CorpCardTrans: Record EACorpCardTrans)
    begin
        // CAMT mappings can carry key-value text in remittance/additional fields.
        if StrPos(CorpCardTrans."Card Id", 'CardId=') > 0 then
            CorpCardTrans."Card Id" := CopyStr(ExtractTaggedValue(CorpCardTrans."Card Id", 'CardId='), 1, MaxStrLen(CorpCardTrans."Card Id"));

        if StrPos(CorpCardTrans.MCC, 'MCC=') > 0 then
            CorpCardTrans.MCC := CopyStr(ExtractTaggedValue(CorpCardTrans.MCC, 'MCC='), 1, MaxStrLen(CorpCardTrans.MCC));

        if (CorpCardTrans.Country = '') and (StrPos(CorpCardTrans."Merchant Raw", 'Country=') > 0) then
            CorpCardTrans.Country := CopyStr(ExtractTaggedValue(CorpCardTrans."Merchant Raw", 'Country='), 1, MaxStrLen(CorpCardTrans.Country));
    end;

    local procedure ExtractTaggedValue(SourceText: Text; Tag: Text): Text
    var
        TagPos: Integer;
        ValuePos: Integer;
        EndPos: Integer;
        ValueTxt: Text;
    begin
        TagPos := StrPos(SourceText, Tag);
        if TagPos = 0 then
            exit('');

        ValuePos := TagPos + StrLen(Tag);
        if ValuePos > StrLen(SourceText) then
            exit('');

        ValueTxt := CopyStr(SourceText, ValuePos);
        EndPos := StrPos(ValueTxt, ';');
        if EndPos > 0 then
            ValueTxt := CopyStr(ValueTxt, 1, EndPos - 1);

        exit(DelChr(ValueTxt, '<>', ' '));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDataExch(CorpCardProvider: Record EACorpCardProvider; var CorpCardBatch: Record EACorpCardBatch; var DataExch: Record "Data Exch.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProvideSourceContent(CorpCardProvider: Record EACorpCardProvider; CorpCardBatch: Record EACorpCardBatch; var TempBlob: Codeunit "Temp Blob"; var SourceFileName: Text[250]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAck(BatchNo: Integer)
    begin
    end;
}