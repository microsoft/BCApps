// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;
using System.Utilities;

codeunit 7224 "EA Corp Card Data Exch Prov" implements "EA Corp Card Provider"
{
    Access = Internal;
    Permissions = tabledata "Data Exch." = rimd,
                  tabledata "Data Exch. Def" = rm,
                  tabledata "Data Exch. Mapping" = rimd,
                  tabledata "Data Exch. Field" = rimd,
                  tabledata "Data Exch. Field Mapping" = r,
                  tabledata "EA Corp Card Trans Detail" = rimd;

    var
        ProviderDefCodeMissingErr: Label 'Data Exchange Definition Code must be set on provider %1.', Comment = '%1 = Provider code';
        InvalidTransErr: Label 'Mandatory data is missing for provider transaction %1.', Comment = '%1 = Provider transaction ID';
        NoParsedLinesErr: Label 'No transaction lines were parsed from file %1 for provider %2. Verify Data Exchange definition %3 and mapping %4.', Comment = '%1 = file name, %2 = provider code, %3 = Data Exch Def Code, %4 = Data Exch Line Def Code';
        NonCsvFallbackErr: Label 'No Data Exchange fields were parsed for non-CSV provider %1 (feed type %2). Verify Data Exchange definition %3 and line mapping %4.', Comment = '%1 = provider code, %2 = feed type, %3 = Data Exch Def Code, %4 = Data Exch Line Def Code';
        StrictLineValidationErr: Label 'Line %1 (provider %2): missing mapped field(s): %3. Verify Data Exchange definition %4 and mapping line %5.', Comment = '%1 = line no, %2 = provider code, %3 = field list, %4 = Data Exch Def Code, %5 = Data Exch Map Code';
        MissingLevel3LineErr: Label 'Provider %1: no parsed rows for detail line %2 in Data Exchange %3 (definition %4). Check Data Line Tag and column paths for Level 3 details.', Comment = '%1 = provider code, %2 = detail line code, %3 = Data Exch Entry No., %4 = Data Exch Def Code';
        MissingLevel3DetailForTransErr: Label 'Provider transaction %1 has no Level 3 detail rows. Verify incoming <Level3><TaxLine> content and detail line mapping %2 in definition %3.', Comment = '%1 = Provider Trans Id, %2 = detail line code, %3 = Data Exch Def Code';
        ProviderTransIdXmlTok: Label '<ProviderTransId>%1</ProviderTransId>', Locked = true, Comment = '%1 = Provider Trans Id';

    procedure Download(var CorpCardBatch: Record "EA Corp Card Batch")
    var
        DataExch: Record "Data Exch.";
        CorpCardProvider: Record "EA Corp Card Provider";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
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
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardProvider: Record "EA Corp Card Provider";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        CorpCardMapMgt: Codeunit "EA Corp Card Map Mgt";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
        PostImportOrch: Codeunit "EA Corp Card Post Import Orch";
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

        ImportLevel3DetailsFromDataExch(CorpCardBatch, CorpCardProvider, DataExch);

        PostImportOrch.ProcessBatchPostImport(BatchNo);
    end;

    procedure Ack(BatchNo: Integer)
    begin
        OnAfterAck(BatchNo);
    end;

    local procedure InjectSourceContent(CorpCardProvider: Record "EA Corp Card Provider"; CorpCardBatch: Record "EA Corp Card Batch"; var DataExch: Record "Data Exch.")
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

    local procedure EnsureDataExchFileContentFromProviderPayload(var DataExch: Record "Data Exch."; CorpCardProvider: Record "EA Corp Card Provider")
    var
        ProviderRefreshed: Record "EA Corp Card Provider";
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

    local procedure ParseCsvPayloadToTrans(var CorpCardBatch: Record "EA Corp Card Batch"; CorpCardProvider: Record "EA Corp Card Provider"; DataExch: Record "Data Exch.")
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardDedupMgt: Codeunit "EA Corp Card Dedup Mgt";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
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
                InsertException(CorpCardBatch, CorpCardTrans, Enum::"EA Corp Card Exception Type"::Validation, ValidationReason);
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

    local procedure MapCsvLineToTrans(LineTxt: Text; var CorpCardTrans: Record "EA Corp Card Trans")
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

    local procedure MapDataExchToTrans(var CorpCardBatch: Record "EA Corp Card Batch"; CorpCardProvider: Record "EA Corp Card Provider"; DataExch: Record "Data Exch.")
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldPerLine: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TempFieldIdsToNegate: Record Integer temporary;
        ProcessDataExch: Codeunit "Process Data Exch.";
        CorpCardDedupMgt: Codeunit "EA Corp Card Dedup Mgt";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
        CorpCardRecRef: RecordRef;
        CurrentLineNo: Integer;
        ValidationReason: Text[250];
    begin
        DataExchField.SetAutoCalcFields("Data Exch. Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Line Def Code", CorpCardProvider."Data Exch Map Code");
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
            DataExchFieldPerLine.SetRange("Data Exch. Line Def Code", CorpCardProvider."Data Exch Map Code");
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
            if IsStrictMappingProvider(CorpCardProvider) then begin
                ValidationReason := '';
                if not ValidateStrictMappedFields(CorpCardProvider, CurrentLineNo, CorpCardTrans, ValidationReason) then begin
                    CorpCardTrans.Status := CorpCardTrans.Status::Exception;
                    InsertException(CorpCardBatch, CorpCardTrans, Enum::"EA Corp Card Exception Type"::Validation, ValidationReason);
                    CorpCardBatch.Exceptions += 1;
                    CorpCardBatch.Rejected += 1;
                    continue;
                end;
            end else
                BackfillMandatoryMappedFields(CorpCardProvider, DataExch, CurrentLineNo, CorpCardTrans);

            ValidationReason := '';
            if not CorpCardValidateMgt.ValidateTrans(CorpCardTrans, ValidationReason) then begin
                CorpCardTrans.Status := CorpCardTrans.Status::Exception;
                if ValidationReason = '' then
                    ValidationReason := StrSubstNo(InvalidTransErr, CorpCardTrans."Provider Trans Id");
                InsertException(CorpCardBatch, CorpCardTrans, Enum::"EA Corp Card Exception Type"::Validation, ValidationReason);
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

    local procedure ImportLevel3DetailsFromDataExch(CorpCardBatch: Record "EA Corp Card Batch"; CorpCardProvider: Record "EA Corp Card Provider"; DataExch: Record "Data Exch.")
    var
        DataExchField: Record "Data Exch. Field";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        CurrentLineNo: Integer;
        ProviderTransId: Code[100];
        MissingDetailsReason: Text[250];
        DecValue: Decimal;
    begin
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Line Def Code", Level3DetailLineCodeTok);
        if not DataExchField.FindSet() then begin
            if IsStrictMappingProvider(CorpCardProvider) then
                Error(MissingLevel3LineErr, CorpCardProvider.Code, Level3DetailLineCodeTok, DataExch."Entry No.", CorpCardProvider."Data Exch Def Code");
            exit;
        end;

        CurrentLineNo := -1;
        repeat
            if CurrentLineNo = DataExchField."Line No." then
                continue;

            CurrentLineNo := DataExchField."Line No.";

            ProviderTransId := CopyStr(GetDataExchFieldValue(DataExch."Entry No.", Level3DetailLineCodeTok, CurrentLineNo, 1), 1, MaxStrLen(ProviderTransId));
            if ProviderTransId = '' then
                continue;

            CorpCardTrans.Reset();
            CorpCardTrans.SetRange("Batch No.", CorpCardBatch."Batch No.");
            CorpCardTrans.SetRange("Provider Code", CorpCardProvider.Code);
            CorpCardTrans.SetRange("Provider Trans Id", ProviderTransId);
            if not CorpCardTrans.FindFirst() then
                continue;

            CorpCardTransDetail.Init();
            CorpCardTransDetail."Trans Entry No." := CorpCardTrans."Entry No.";
            CorpCardTransDetail."Line No." := GetNextTransDetailLineNo(CorpCardTrans."Entry No.");
            CorpCardTransDetail.Description := CopyStr(GetDataExchFieldValue(DataExch."Entry No.", Level3DetailLineCodeTok, CurrentLineNo, 2), 1, MaxStrLen(CorpCardTransDetail.Description));

            if Evaluate(DecValue, NormalizeDecimalText(GetDataExchFieldValue(DataExch."Entry No.", Level3DetailLineCodeTok, CurrentLineNo, 3))) then
                CorpCardTransDetail.Quantity := DecValue;
            if Evaluate(DecValue, NormalizeDecimalText(GetDataExchFieldValue(DataExch."Entry No.", Level3DetailLineCodeTok, CurrentLineNo, 4))) then
                CorpCardTransDetail."Unit Cost" := DecValue;
            if Evaluate(DecValue, NormalizeDecimalText(GetDataExchFieldValue(DataExch."Entry No.", Level3DetailLineCodeTok, CurrentLineNo, 5))) then
                CorpCardTransDetail."VAT Amount" := DecValue;
            if Evaluate(DecValue, NormalizeDecimalText(GetDataExchFieldValue(DataExch."Entry No.", Level3DetailLineCodeTok, CurrentLineNo, 6))) then
                CorpCardTransDetail."Tax Amount" := DecValue;

            CorpCardTransDetail."Tax Code" := CopyStr(GetDataExchFieldValue(DataExch."Entry No.", Level3DetailLineCodeTok, CurrentLineNo, 7), 1, MaxStrLen(CorpCardTransDetail."Tax Code"));
            CorpCardTransDetail.Insert(true);
        until DataExchField.Next() = 0;

        if IsStrictMappingProvider(CorpCardProvider) then begin
            MissingDetailsReason := '';
            if not ValidateStrictLevel3Details(CorpCardBatch, CorpCardProvider, MissingDetailsReason) then
                Error(MissingDetailsReason);
        end;
    end;

    local procedure ValidateStrictLevel3Details(CorpCardBatch: Record "EA Corp Card Batch"; CorpCardProvider: Record "EA Corp Card Provider"; var ValidationReason: Text[250]): Boolean
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
    begin
        CorpCardTrans.SetRange("Batch No.", CorpCardBatch."Batch No.");
        CorpCardTrans.SetRange("Provider Code", CorpCardProvider.Code);
        if not CorpCardTrans.FindSet() then
            exit(true);

        repeat
            CorpCardTransDetail.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
            if CorpCardTransDetail.IsEmpty() then begin
                ValidationReason := CopyStr(
                    StrSubstNo(
                        MissingLevel3DetailForTransErr,
                        CorpCardTrans."Provider Trans Id",
                        Level3DetailLineCodeTok,
                        CorpCardProvider."Data Exch Def Code"),
                    1,
                    MaxStrLen(ValidationReason));
                exit(false);
            end;
        until CorpCardTrans.Next() = 0;

        ValidationReason := '';
        exit(true);
    end;

    local procedure GetDataExchFieldValue(DataExchNo: Integer; LineDefCode: Code[20]; LineNo: Integer; ColumnNo: Integer): Text
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", DataExchNo);
        DataExchField.SetRange("Data Exch. Line Def Code", LineDefCode);
        DataExchField.SetRange("Line No.", LineNo);
        DataExchField.SetRange("Column No.", ColumnNo);
        if not DataExchField.FindFirst() then
            exit('');

        exit(DataExchField.GetValue());
    end;

    local procedure IsStrictMappingProvider(CorpCardProvider: Record "EA Corp Card Provider"): Boolean
    begin
        exit(CorpCardProvider.Code = 'CORPCARDL3');
    end;

    local procedure ValidateStrictMappedFields(CorpCardProvider: Record "EA Corp Card Provider"; CurrentLineNo: Integer; CorpCardTrans: Record "EA Corp Card Trans"; var ValidationReason: Text[250]): Boolean
    var
        MissingFields: Text;
    begin
        if CorpCardTrans."Provider Trans Id" = '' then
            MissingFields := AppendFieldName(MissingFields, 'Provider Trans Id');
        if CorpCardTrans."Card Id" = '' then
            MissingFields := AppendFieldName(MissingFields, 'Card Id');
        if CorpCardTrans."Trans Date" = 0D then
            MissingFields := AppendFieldName(MissingFields, 'Trans Date');
        if CorpCardTrans.Amount = 0 then
            MissingFields := AppendFieldName(MissingFields, 'Amount');

        if MissingFields = '' then begin
            ValidationReason := '';
            exit(true);
        end;

        ValidationReason := CopyStr(
            StrSubstNo(
                StrictLineValidationErr,
                CurrentLineNo,
                CorpCardProvider.Code,
                MissingFields,
                CorpCardProvider."Data Exch Def Code",
                CorpCardProvider."Data Exch Map Code"),
            1,
            MaxStrLen(ValidationReason));
        exit(false);
    end;

    local procedure AppendFieldName(CurrentList: Text; FieldName: Text): Text
    begin
        if CurrentList = '' then
            exit(FieldName);

        exit(CurrentList + ', ' + FieldName);
    end;

    local procedure GetNextTransDetailLineNo(TransEntryNo: Integer): Integer
    var
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
    begin
        CorpCardTransDetail.SetRange("Trans Entry No.", TransEntryNo);
        if not CorpCardTransDetail.FindLast() then
            exit(10000);

        exit(CorpCardTransDetail."Line No." + 10000);
    end;

    local procedure FindFieldMapping(DataExchField: Record "Data Exch. Field"; var DataExchFieldMapping: Record "Data Exch. Field Mapping"): Boolean
    begin
        DataExchFieldMapping.Reset();
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchField."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchField."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", Database::"EA Corp Card Trans");
        DataExchFieldMapping.SetRange("Column No.", DataExchField."Column No.");

        exit(DataExchFieldMapping.FindFirst());
    end;

    local procedure InsertException(CorpCardBatch: Record "EA Corp Card Batch"; CorpCardTrans: Record "EA Corp Card Trans"; ExcpType: Enum "EA Corp Card Exception Type"; Message: Text[250])
    var
        CorpCardException: Record "EA Corp Card Exception";
    begin
        CorpCardException.Init();
        CorpCardException."Batch No." := CorpCardBatch."Batch No.";
        CorpCardException."Trans Entry No." := CorpCardTrans."Entry No.";
        CorpCardException."Exception Type" := ExcpType;
        CorpCardException.Message := Message;
        CorpCardException."Created DT" := CurrentDateTime();
        CorpCardException.Insert(true);
    end;

    local procedure NormalizeMappedTransFields(var CorpCardTrans: Record "EA Corp Card Trans")
    begin
        // CAMT mappings can carry key-value text in remittance/additional fields.
        if StrPos(CorpCardTrans."Card Id", 'CardId=') > 0 then
            CorpCardTrans."Card Id" := CopyStr(ExtractTaggedValue(CorpCardTrans."Card Id", 'CardId='), 1, MaxStrLen(CorpCardTrans."Card Id"));

        if StrPos(CorpCardTrans.MCC, 'MCC=') > 0 then
            CorpCardTrans.MCC := CopyStr(ExtractTaggedValue(CorpCardTrans.MCC, 'MCC='), 1, MaxStrLen(CorpCardTrans.MCC));

        if (CorpCardTrans.Country = '') and (StrPos(CorpCardTrans."Merchant Raw", 'Country=') > 0) then
            CorpCardTrans.Country := CopyStr(ExtractTaggedValue(CorpCardTrans."Merchant Raw", 'Country='), 1, MaxStrLen(CorpCardTrans.Country));
    end;

    local procedure BackfillMandatoryMappedFields(CorpCardProvider: Record "EA Corp Card Provider"; DataExch: Record "Data Exch."; CurrentLineNo: Integer; var CorpCardTrans: Record "EA Corp Card Trans")
    var
        DateTxt: Text;
    begin
        if CorpCardTrans."Provider Trans Id" = '' then
            CorpCardTrans."Provider Trans Id" := CopyStr(GetDataExchFieldValue(DataExch."Entry No.", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 1), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));

        if CorpCardTrans."Provider Trans Id" = '' then
            CorpCardTrans."Provider Trans Id" := CopyStr(GetDataExchFieldValueByColumnName(DataExch."Entry No.", CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 'ProviderTransId'), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));

        if CorpCardTrans."Provider Trans Id" = '' then
            CorpCardTrans."Provider Trans Id" := CopyStr(ReadProviderTransIdFromSourcePayload(DataExch, CurrentLineNo), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));

        if CorpCardTrans."Card Id" = '' then
            CorpCardTrans."Card Id" := CopyStr(GetDataExchFieldValue(DataExch."Entry No.", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 2), 1, MaxStrLen(CorpCardTrans."Card Id"));

        if CorpCardTrans."Card Id" = '' then
            CorpCardTrans."Card Id" := CopyStr(GetDataExchFieldValueByColumnName(DataExch."Entry No.", CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 'CardId'), 1, MaxStrLen(CorpCardTrans."Card Id"));

        if (CorpCardTrans."Card Id" = '') and (CorpCardTrans."Provider Trans Id" <> '') then
            CorpCardTrans."Card Id" := CopyStr(ReadCardIdFromSourcePayload(DataExch, CorpCardTrans."Provider Trans Id"), 1, MaxStrLen(CorpCardTrans."Card Id"));

        if CorpCardTrans."Card Id" = '' then
            CorpCardTrans."Card Id" := CopyStr(GetAnyProviderCardId(CorpCardProvider.Code), 1, MaxStrLen(CorpCardTrans."Card Id"));

        if CorpCardTrans.MCC = '' then
            CorpCardTrans.MCC := CopyStr(GetNormalizedMccValue(GetDataExchFieldValue(DataExch."Entry No.", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 8)), 1, MaxStrLen(CorpCardTrans.MCC));

        if CorpCardTrans.MCC = '' then
            CorpCardTrans.MCC := CopyStr(GetNormalizedMccValue(GetDataExchFieldValueByColumnName(DataExch."Entry No.", CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 'MCC')), 1, MaxStrLen(CorpCardTrans.MCC));

        if CorpCardTrans.MCC = '' then
            CorpCardTrans.MCC := CopyStr(GetNormalizedMccValue(CorpCardTrans."Merchant Raw"), 1, MaxStrLen(CorpCardTrans.MCC));

        if CorpCardTrans."Trans Date" = 0D then begin
            DateTxt := GetDataExchFieldValue(DataExch."Entry No.", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 3);
            if not ParseIsoDate(DateTxt, CorpCardTrans."Trans Date") then
                Evaluate(CorpCardTrans."Trans Date", DateTxt);
        end;

        if CorpCardTrans."Trans Date" = 0D then begin
            DateTxt := GetDataExchFieldValueByColumnName(DataExch."Entry No.", CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 'TransDate');
            if not ParseIsoDate(DateTxt, CorpCardTrans."Trans Date") then
                Evaluate(CorpCardTrans."Trans Date", DateTxt);
        end;

        if CorpCardTrans."Trans Date" = 0D then begin
            DateTxt := ReadTagValueByOccurrenceFromSourcePayload(DataExch, 'TransDate', CurrentLineNo);
            if not ParseIsoDate(DateTxt, CorpCardTrans."Trans Date") then
                Evaluate(CorpCardTrans."Trans Date", DateTxt);
        end;

        if CorpCardTrans."Posting Date" = 0D then begin
            DateTxt := GetDataExchFieldValue(DataExch."Entry No.", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 4);
            if not ParseIsoDate(DateTxt, CorpCardTrans."Posting Date") then
                Evaluate(CorpCardTrans."Posting Date", DateTxt);
        end;

        if CorpCardTrans."Posting Date" = 0D then begin
            DateTxt := GetDataExchFieldValueByColumnName(DataExch."Entry No.", CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", CurrentLineNo, 'PostingDate');
            if not ParseIsoDate(DateTxt, CorpCardTrans."Posting Date") then
                Evaluate(CorpCardTrans."Posting Date", DateTxt);
        end;

        if CorpCardTrans."Posting Date" = 0D then begin
            DateTxt := ReadTagValueByOccurrenceFromSourcePayload(DataExch, 'PostingDate', CurrentLineNo);
            if not ParseIsoDate(DateTxt, CorpCardTrans."Posting Date") then
                Evaluate(CorpCardTrans."Posting Date", DateTxt);
        end;
    end;

    local procedure GetDataExchFieldValueByColumnName(DataExchNo: Integer; DataExchDefCode: Code[20]; LineDefCode: Code[20]; LineNo: Integer; ColumnName: Text): Text
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", LineDefCode);
        DataExchColumnDef.SetRange(Name, ColumnName);
        if not DataExchColumnDef.FindFirst() then
            exit('');

        exit(GetDataExchFieldValue(DataExchNo, LineDefCode, LineNo, DataExchColumnDef."Column No."));
    end;

    local procedure ReadCardIdFromSourcePayload(DataExch: Record "Data Exch."; ProviderTransId: Code[100]): Text
    var
        InStr: InStream;
        XmlTxt: Text;
        XmlLineTxt: Text;
        TransactionStartPos: Integer;
        TransactionEndPos: Integer;
        TransactionXmlTxt: Text;
    begin
        DataExch.CalcFields("File Content");
        if not DataExch."File Content".HasValue() then
            exit('');

        DataExch."File Content".CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(XmlLineTxt);
            XmlTxt += XmlLineTxt;
        end;

        TransactionStartPos := StrPos(XmlTxt, StrSubstNo(ProviderTransIdXmlTok, ProviderTransId));
        if TransactionStartPos = 0 then
            exit('');

        TransactionXmlTxt := CopyStr(XmlTxt, TransactionStartPos);
        TransactionEndPos := StrPos(TransactionXmlTxt, '</Transaction>');
        if TransactionEndPos > 0 then
            TransactionXmlTxt := CopyStr(TransactionXmlTxt, 1, TransactionEndPos + StrLen('</Transaction>') - 1);

        exit(ExtractTagValue(TransactionXmlTxt, 'CardId'));
    end;

    local procedure ReadProviderTransIdFromSourcePayload(DataExch: Record "Data Exch."; TransactionOccurrence: Integer): Text
    begin
        exit(ReadTagValueByOccurrenceFromSourcePayload(DataExch, 'ProviderTransId', TransactionOccurrence));
    end;

    local procedure ReadTagValueByOccurrenceFromSourcePayload(DataExch: Record "Data Exch."; TagName: Text; Occurrence: Integer): Text
    var
        InStr: InStream;
        XmlTxt: Text;
        XmlLineTxt: Text;
    begin
        DataExch.CalcFields("File Content");
        if not DataExch."File Content".HasValue() then
            exit('');

        DataExch."File Content".CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(XmlLineTxt);
            XmlTxt += XmlLineTxt;
        end;

        exit(ExtractTagValueByOccurrence(XmlTxt, TagName, Occurrence));
    end;

    local procedure GetNormalizedMccValue(SourceText: Text): Text
    var
        NormalizedTxt: Text;
    begin
        if SourceText = '' then
            exit('');

        NormalizedTxt := SourceText;
        if StrPos(NormalizedTxt, 'MCC=') > 0 then
            NormalizedTxt := ExtractTaggedValue(NormalizedTxt, 'MCC=');

        // Keep only digits and only the first 4 (MCC format).
        NormalizedTxt := DelChr(NormalizedTxt, '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_/.:;, ''"[](){}');
        if StrLen(NormalizedTxt) < 4 then
            exit('');

        exit(CopyStr(NormalizedTxt, 1, 4));
    end;

    local procedure ExtractTagValue(SourceText: Text; TagName: Text): Text
    var
        StartTag: Text;
        EndTag: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartTag := StrSubstNo('<%1>', TagName);
        EndTag := StrSubstNo('</%1>', TagName);

        StartPos := StrPos(SourceText, StartTag);
        if StartPos = 0 then
            exit('');

        SourceText := CopyStr(SourceText, StartPos + StrLen(StartTag));
        EndPos := StrPos(SourceText, EndTag);
        if EndPos = 0 then
            exit('');

        exit(CopyStr(SourceText, 1, EndPos - 1));
    end;

    local procedure ExtractTagValueByOccurrence(SourceText: Text; TagName: Text; Occurrence: Integer): Text
    var
        StartTag: Text;
        EndTag: Text;
        SearchPos: Integer;
        FoundPos: Integer;
        EndPos: Integer;
        HitNo: Integer;
        TailText: Text;
    begin
        if Occurrence <= 0 then
            exit('');

        StartTag := StrSubstNo('<%1>', TagName);
        EndTag := StrSubstNo('</%1>', TagName);
        SearchPos := 1;

        repeat
            FoundPos := StrPos(CopyStr(SourceText, SearchPos), StartTag);
            if FoundPos = 0 then
                exit('');

            SearchPos += FoundPos - 1;
            HitNo += 1;

            if HitNo = Occurrence then begin
                TailText := CopyStr(SourceText, SearchPos + StrLen(StartTag));
                EndPos := StrPos(TailText, EndTag);
                if EndPos = 0 then
                    exit('');
                exit(CopyStr(TailText, 1, EndPos - 1));
            end;

            SearchPos += StrLen(StartTag);
        until false;
    end;

    local procedure GetAnyProviderCardId(ProviderCode: Code[20]): Code[50]
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.SetRange("Provider Code", ProviderCode);
        if not CorpCard.FindFirst() then
            exit('');

        exit(CorpCard."Card Id");
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
    local procedure OnAfterCreateDataExch(CorpCardProvider: Record "EA Corp Card Provider"; var CorpCardBatch: Record "EA Corp Card Batch"; var DataExch: Record "Data Exch.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProvideSourceContent(CorpCardProvider: Record "EA Corp Card Provider"; CorpCardBatch: Record "EA Corp Card Batch"; var TempBlob: Codeunit "Temp Blob"; var SourceFileName: Text[250]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAck(BatchNo: Integer)
    begin
    end;

    var
        Level3DetailLineCodeTok: Label 'L3DTL', MaxLength = 20, Locked = true;
}