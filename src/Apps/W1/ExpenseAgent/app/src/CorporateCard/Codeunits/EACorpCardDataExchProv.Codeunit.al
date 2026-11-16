// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;
using System.Security.Encryption;
using System.Utilities;

codeunit 7434 "EA Corp Card Data Exch Prov" implements "EA Corp Card Provider"
{
    Access = Internal;
    Permissions = tabledata "Data Exch." = rimd,
                  tabledata "Data Exch. Column Def" = r,
                  tabledata "Data Exch. Def" = rm,
                  tabledata "Data Exch. Mapping" = rimd,
                  tabledata "Data Exch. Field" = rimd,
                  tabledata "Data Exch. Field Mapping" = r,
                  tabledata "EA Corp Card Trans Detail" = rimd;

    var
        FieldMustBeSetOnRecordErr: Label '%1 must be set on %2 %3.', Comment = '%1 = field caption, %2 = table caption, %3 = record identifier';
        DataExchImportFailedErr: Label 'Data Exchange import failed for provider %1 using definition %2.', Comment = '%1 = provider code, %2 = Data Exch Def Code';
        InvalidCsvLineErr: Label 'CSV input contains invalid quoting.';
        InternalCardIdColumnErr: Label 'CardId is internal to Business Central and cannot be supplied in a statement file. Use CardLast4 instead.';
        InvalidTransErr: Label 'Mandatory data is missing for provider transaction %1.', Comment = '%1 = Provider transaction ID';
        NoParsedLinesErr: Label 'No transaction lines were parsed from file %1 for provider %2. Verify Data Exchange definition %3 and mapping %4.', Comment = '%1 = file name, %2 = provider code, %3 = Data Exch Def Code, %4 = Data Exch Line Def Code';
        AllRowsRejectedErr: Label 'All %1 transaction lines from file %2 for provider %3 were rejected. Review the corporate card import exceptions.', Comment = '%1 = rejected line count, %2 = file name, %3 = provider code';
        NonCsvFallbackErr: Label 'No Data Exchange fields were parsed for non-CSV provider %1 (feed type %2). Verify Data Exchange definition %3 and line mapping %4.', Comment = '%1 = provider code, %2 = feed type, %3 = Data Exch Def Code, %4 = Data Exch Line Def Code';
        StrictLineValidationErr: Label 'Line %1 (provider %2): missing mapped field(s): %3. Verify Data Exchange definition %4 and mapping line %5.', Comment = '%1 = line no, %2 = provider code, %3 = field list, %4 = Data Exch Def Code, %5 = Data Exch Map Code';
        ProviderTransIdXmlTok: Label '<ProviderTransId>%1</ProviderTransId>', Locked = true, Comment = '%1 = Provider Trans Id';
        ShowItLbl: Label 'Show it';
        SourceFileRequiredErr: Label 'Select a statement file using Import statement for provider %1.', Comment = '%1 = provider code';
        EmptySourceFileErr: Label 'The selected statement file is empty. Select a file that contains transactions.';
        ColumnNoByName: Dictionary of [Text, Integer];

    procedure Download(var CorpCardStatement: Record "EA Corp Card Statement")
    var
        DataExch: Record "Data Exch.";
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        if CorpCardStatement."Data Exch Entry No." = 0 then
            CreateDataExchange(CorpCardStatement, DataExch);
        CorpCardProvider.Get(CorpCardStatement."Provider Code");
        DataExch.Get(CorpCardStatement."Data Exch Entry No.");
        DataExch.CalcFields("File Content");
        if not DataExch."File Content".HasValue() then
            InjectSourceContent(CorpCardProvider, CorpCardStatement, DataExch);

        CorpCardStatement."Source Ref" := CopyStr(
            DataExch."File Name",
            1,
            MaxStrLen(CorpCardStatement."Source Ref"));
        CorpCardStatement.Modify();

        OnAfterDownload(CorpCardProvider, CorpCardStatement, DataExch);
    end;

    internal procedure SetSourceFile(var CorpCardStatement: Record "EA Corp Card Statement"; SourceInStream: InStream; SourceFileName: Text)
    var
        DataExch: Record "Data Exch.";
    begin
        CreateDataExchange(CorpCardStatement, DataExch);
        SetFileContent(CorpCardStatement, DataExch, SourceInStream, SourceFileName);
    end;

    local procedure CreateDataExchange(var CorpCardStatement: Record "EA Corp Card Statement"; var DataExch: Record "Data Exch.")
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        CorpCardProvider.Get(CorpCardStatement."Provider Code");
        CreateCorpCardSetup.EnsureDataExchangeForProvider(CorpCardProvider);
        if CorpCardProvider."Data Exch Def Code" = '' then
            RaiseProviderSetupError(StrSubstNo(FieldMustBeSetOnRecordErr, CorpCardProvider.FieldCaption("Data Exch Def Code"), CorpCardProvider.TableCaption(), CorpCardProvider.Code), CorpCardProvider);

        DataExch.Init();
        DataExch."Data Exch. Def Code" := CorpCardProvider."Data Exch Def Code";
        DataExch."Data Exch. Line Def Code" := CorpCardProvider."Data Exch Map Code";
        DataExch."Related Record" := CorpCardProvider.RecordId;
        DataExch.Insert(true);

        CorpCardStatement."Data Exch Entry No." := DataExch."Entry No.";
        CorpCardStatement.Modify();
    end;

    procedure ParseToStaging(StatementEntryNo: Integer)
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardProvider: Record "EA Corp Card Provider";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        CorpCardMapMgt: Codeunit "EA Corp Card Map Mgt";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        CorpCardStatement.Get(StatementEntryNo);
        if CorpCardStatement."Data Exch Entry No." = 0 then
            exit;

        CorpCardProvider.Get(CorpCardStatement."Provider Code");
        CreateCorpCardSetup.EnsureDataExchangeForProvider(CorpCardProvider);
        DataExch.Get(CorpCardStatement."Data Exch Entry No.");
        DataExch.CalcFields("File Content");
        if DataExch."Data Exch. Line Def Code" = '' then begin
            DataExch."Data Exch. Line Def Code" := CorpCardProvider."Data Exch Map Code";
            DataExch.Modify(true);
        end;
        DataExchDef.Get(CorpCardProvider."Data Exch Def Code");
        CorpCardMapMgt.ValidateMandatoryFieldMappings(CorpCardProvider);
        if not DataExch.ImportToDataExch(DataExchDef) then begin
            CorpCardStatement.Status := CorpCardStatement.Status::Failed;
            CorpCardStatement.Rejected += 1;
            CorpCardStatement.Modify();
            RaiseProviderSetupError(
                StrSubstNo(DataExchImportFailedErr, CorpCardProvider.Code, CorpCardProvider."Data Exch Def Code"),
                CorpCardProvider);
        end;
        if HasParsedFields(DataExch) then
            MapDataExchToTrans(CorpCardStatement, CorpCardProvider, DataExch)
        else
            if CorpCardProvider."Feed Type" = CorpCardProvider."Feed Type"::CSV then
                ParseCsvPayloadToTrans(CorpCardStatement, CorpCardProvider, DataExch)
            else begin
                CorpCardStatement.Status := CorpCardStatement.Status::Failed;
                CorpCardStatement.Rejected += 1;
                CorpCardStatement.Modify();
                RaiseProviderSetupError(
                    StrSubstNo(NonCsvFallbackErr, CorpCardProvider.Code, CorpCardProvider."Feed Type", CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code"),
                    CorpCardProvider);
            end;
    end;

    procedure Ack(StatementEntryNo: Integer)
    begin
        OnAfterAck(StatementEntryNo);
    end;

    local procedure InjectSourceContent(CorpCardProvider: Record "EA Corp Card Provider"; var CorpCardStatement: Record "EA Corp Card Statement"; var DataExch: Record "Data Exch.")
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        SourceFileName: Text[250];
        Handled: Boolean;
    begin
        Handled := false;
        OnBeforeInjectSourceContent(CorpCardProvider, CorpCardStatement, TempBlob, SourceFileName, Handled);
        if not Handled then
            RaiseProviderSetupError(StrSubstNo(SourceFileRequiredErr, CorpCardProvider.Code), CorpCardProvider);

        TempBlob.CreateInStream(InStr);
        SetFileContent(CorpCardStatement, DataExch, InStr, SourceFileName);
    end;

    local procedure SetFileContent(var CorpCardStatement: Record "EA Corp Card Statement"; var DataExch: Record "Data Exch."; InStr: InStream; SourceFileName: Text)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInStr: InStream;
        OutStr: OutStream;
    begin
        DataExch."File Content".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        Clear(OutStr);
        if not DataExch."File Content".HasValue() then
            Error(EmptySourceFileErr);
        if SourceFileName <> '' then begin
            DataExch."File Name" := CopyStr(SourceFileName, 1, MaxStrLen(DataExch."File Name"));
            CorpCardStatement."Source File Name" := CopyStr(SourceFileName, 1, MaxStrLen(CorpCardStatement."Source File Name"));
            CorpCardStatement."Source Ref" := CopyStr(SourceFileName, 1, MaxStrLen(CorpCardStatement."Source Ref"));
        end;

        DataExch.Modify();

        DataExch."File Content".CreateInStream(HashInStr);
        CorpCardStatement."Source Payload Hash" := CopyStr(
            LowerCase(CryptographyManagement.GenerateHash(HashInStr, HashAlgorithmType::SHA256)),
            1,
            MaxStrLen(CorpCardStatement."Source Payload Hash"));
        CorpCardStatement.Modify();
    end;

    local procedure HasParsedFields(DataExch: Record "Data Exch."): Boolean
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        exit(not DataExchField.IsEmpty());
    end;

    local procedure ParseCsvPayloadToTrans(var CorpCardStatement: Record "EA Corp Card Statement"; CorpCardProvider: Record "EA Corp Card Provider"; DataExch: Record "Data Exch.")
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardDedupMgt: Codeunit "EA Corp Card Dedup Mgt";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
        InStr: InStream;
        LineTxt: Text;
        CsvFields: List of [Text];
        IsHeader: Boolean;
        ValidationReason: Text[250];
        IsValid: Boolean;
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
                if IsHeaderLine(LineTxt) then begin
                    if StrPos(LowerCase(LineTxt), 'cardid') > 0 then
                        Error(InternalCardIdColumnErr);
                    continue;
                end;
            end;

            Clear(CorpCardTrans);
            CorpCardTrans.Init();
            CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
            CorpCardTrans."Provider Code" := CorpCardProvider.Code;
            CorpCardTrans.Status := CorpCardTrans.Status::Imported;

            CsvFields := ParseCsvFields(LineTxt);
            ValidationReason := '';
            IsValid := MapCsvLineToTrans(CsvFields, CorpCardTrans, ValidationReason);
            if IsValid then
                IsValid := CorpCardValidateMgt.ValidateTrans(CorpCardTrans, ValidationReason);
            if not IsValid then begin
                CorpCardTrans.Status := CorpCardTrans.Status::Exception;
                if ValidationReason = '' then
                    ValidationReason := StrSubstNo(InvalidTransErr, CorpCardTrans."Provider Trans Id");
                InsertException(CorpCardStatement, CorpCardTrans, Enum::"EA Corp Card Exception Type"::Validation, ValidationReason);
                CorpCardStatement.Exceptions += 1;
                CorpCardStatement.Rejected += 1;
                continue;
            end;
            if CorpCardDedupMgt.IsDuplicate(CorpCardTrans) then begin
                CorpCardStatement.Duplicates += 1;
                continue;
            end;

            CorpCardTrans.Insert(true);
            CorpCardStatement.Imported += 1;
        end;

        CorpCardStatement.Modify();
        if (CorpCardStatement.Imported = 0) and (CorpCardStatement.Duplicates = 0) then begin
            if CorpCardStatement.Rejected > 0 then begin
                MarkAllRowsRejected(CorpCardStatement, DataExch."File Name");
                exit;
            end;
            CorpCardStatement.Status := CorpCardStatement.Status::Failed;
            CorpCardStatement.Rejected += 1;
            CorpCardStatement.Modify();
            RaiseProviderSetupError(
                StrSubstNo(NoParsedLinesErr, DataExch."File Name", CorpCardProvider.Code, CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code"),
                CorpCardProvider);
        end;
    end;

    local procedure MarkAllRowsRejected(var CorpCardStatement: Record "EA Corp Card Statement"; SourceFileName: Text)
    var
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        RejectedRowsErrorInfo: ErrorInfo;
    begin
        CorpCardStatement.Status := CorpCardStatement.Status::Failed;
        CorpCardStatement.Modify();
        RejectedRowsErrorInfo.Message := StrSubstNo(
            AllRowsRejectedErr, CorpCardStatement.Rejected, SourceFileName, CorpCardStatement."Provider Code");
        RejectedRowsErrorInfo.DataClassification := DataClassification::CustomerContent;
        RejectedRowsErrorInfo.ErrorType := ErrorType::Client;
        RejectedRowsErrorInfo.RecordId := CorpCardStatement.RecordId;
        RejectedRowsErrorInfo.PageNo := Page::"EA Corp Card Statement";
        RejectedRowsErrorInfo.AddNavigationAction(ShowItLbl);
        CorpCardErrorContext.SetErrorInfo(RejectedRowsErrorInfo);
    end;

    local procedure RaiseProviderSetupError(ErrorMessage: Text; CorpCardProvider: Record "EA Corp Card Provider")
    var
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        ProviderSetupErrorInfo: ErrorInfo;
    begin
        ProviderSetupErrorInfo := CreateProviderSetupErrorInfo(ErrorMessage, CorpCardProvider);
        CorpCardErrorContext.SetErrorInfo(ProviderSetupErrorInfo);
        Error(ProviderSetupErrorInfo);
    end;

    local procedure CreateProviderSetupErrorInfo(ErrorMessage: Text; CorpCardProvider: Record "EA Corp Card Provider"): ErrorInfo
    var
        ProviderSetupErrorInfo: ErrorInfo;
    begin
        ProviderSetupErrorInfo.Message := ErrorMessage;
        ProviderSetupErrorInfo.DataClassification := DataClassification::CustomerContent;
        ProviderSetupErrorInfo.ErrorType := ErrorType::Client;
        ProviderSetupErrorInfo.RecordId := CorpCardProvider.RecordId;
        ProviderSetupErrorInfo.PageNo := Page::"EA Corp Card Providers";
        ProviderSetupErrorInfo.AddNavigationAction(ShowItLbl);
        exit(ProviderSetupErrorInfo);
    end;

    local procedure IsHeaderLine(LineTxt: Text): Boolean
    begin
        exit((StrPos(LowerCase(LineTxt), 'providertransid') > 0) and (StrPos(LineTxt, ',') > 0));
    end;

    local procedure MapCsvLineToTrans(CsvFields: List of [Text]; var CorpCardTrans: Record "EA Corp Card Trans"; var ValidationReason: Text[250]): Boolean
    var
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
        DateTxt: Text;
        PostingDateTxt: Text;
        AmountTxt: Text;
    begin
        CorpCardTrans."Provider Trans Id" := CopyStr(GetCsvField(CsvFields, 1), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));

        DateTxt := GetCsvField(CsvFields, 3);
        if not ParseIsoDate(DateTxt, CorpCardTrans."Trans Date") then
            Evaluate(CorpCardTrans."Trans Date", DateTxt);

        PostingDateTxt := GetCsvField(CsvFields, 4);
        if not ParseIsoDate(PostingDateTxt, CorpCardTrans."Posting Date") then
            Evaluate(CorpCardTrans."Posting Date", PostingDateTxt);

        AmountTxt := NormalizeDecimalText(GetCsvField(CsvFields, 5));
        Evaluate(CorpCardTrans.Amount, AmountTxt);

        CorpCardTrans."Currency Code" := CopyStr(GetCsvField(CsvFields, 6), 1, MaxStrLen(CorpCardTrans."Currency Code"));
        CorpCardTrans."Merchant Raw" := CopyStr(GetCsvField(CsvFields, 7), 1, MaxStrLen(CorpCardTrans."Merchant Raw"));
        CorpCardTrans.MCC := CopyStr(GetCsvField(CsvFields, 8), 1, MaxStrLen(CorpCardTrans.MCC));
        CorpCardTrans.Country := CopyStr(GetCsvField(CsvFields, 9), 1, MaxStrLen(CorpCardTrans.Country));
        exit(CorpCardValidateMgt.TrySetCardLast4(GetCsvField(CsvFields, 2), CorpCardTrans, ValidationReason));
    end;

    internal procedure ParseCsvFields(LineTxt: Text): List of [Text]
    var
        CsvFields: List of [Text];
        FieldTxt: Text;
        CurrentChar: Text[1];
        Position: Integer;
        InQuotes: Boolean;
        AfterClosingQuote: Boolean;
    begin
        Position := 1;
        while Position <= StrLen(LineTxt) do begin
            CurrentChar := CopyStr(LineTxt, Position, 1);
            if CurrentChar = '"' then begin
                if InQuotes then begin
                    if CopyStr(LineTxt, Position + 1, 1) = '"' then begin
                        FieldTxt += '"';
                        Position += 1;
                    end else begin
                        InQuotes := false;
                        AfterClosingQuote := true;
                    end;
                end else
                    if (FieldTxt = '') and not AfterClosingQuote then
                        InQuotes := true
                    else
                        Error(InvalidCsvLineErr);
            end else
                if (CurrentChar = ',') and not InQuotes then begin
                    CsvFields.Add(FieldTxt);
                    FieldTxt := '';
                    AfterClosingQuote := false;
                end else begin
                    if AfterClosingQuote then
                        Error(InvalidCsvLineErr);
                    FieldTxt += CurrentChar;
                end;
            Position += 1;
        end;
        if InQuotes then
            Error(InvalidCsvLineErr);
        CsvFields.Add(FieldTxt);
        exit(CsvFields);
    end;

    local procedure GetCsvField(CsvFields: List of [Text]; FieldIndex: Integer): Text
    begin
        if FieldIndex > CsvFields.Count() then
            exit('');
        exit(CsvFields.Get(FieldIndex));
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

    local procedure MapDataExchToTrans(var CorpCardStatement: Record "EA Corp Card Statement"; CorpCardProvider: Record "EA Corp Card Provider"; DataExch: Record "Data Exch.")
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        DataExchField: Record "Data Exch. Field";
        TempDataExchFieldMapping: Record "Data Exch. Field Mapping" temporary;
        TempFieldIdsToNegate: Record Integer temporary;
        ProcessDataExch: Codeunit "Process Data Exch.";
        CorpCardDedupMgt: Codeunit "EA Corp Card Dedup Mgt";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
        FieldMappingRecordId: RecordId;
        CorpCardRecRef: RecordRef;
        FieldValueByColumnNo: Dictionary of [Integer, Text];
        FieldMappingRecordIdByColumnNo: Dictionary of [Integer, RecordId];
        CurrentLineNo: Integer;
        HasNextField: Boolean;
        StrictMappingProvider: Boolean;
        SourcePayloadTxt: Text;
        ValidationReason: Text[250];
        CardLast4: Text;
        IsValid: Boolean;
    begin
        Clear(ColumnNoByName);
        LoadFieldMappings(CorpCardProvider, TempDataExchFieldMapping, FieldMappingRecordIdByColumnNo);
        StrictMappingProvider := IsStrictMappingProvider(CorpCardProvider);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Line Def Code", CorpCardProvider."Data Exch Map Code");
        if not DataExchField.FindSet() then
            exit;
        if not StrictMappingProvider then
            SourcePayloadTxt := ReadSourcePayload(DataExch);
        repeat
            CurrentLineNo := DataExchField."Line No.";
            Clear(FieldValueByColumnNo);
            CardLast4 := '';
            TempFieldIdsToNegate.DeleteAll();

            Clear(CorpCardTrans);
            CorpCardTrans.Init();
            CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
            CorpCardTrans."Provider Code" := CorpCardProvider.Code;
            CorpCardTrans.Status := CorpCardTrans.Status::Imported;

            CorpCardRecRef.GetTable(CorpCardTrans);
            repeat
                if not StrictMappingProvider then
                    if not FieldValueByColumnNo.ContainsKey(DataExchField."Column No.") then
                        FieldValueByColumnNo.Add(DataExchField."Column No.", DataExchField.GetValue());
                if FieldMappingRecordIdByColumnNo.Get(DataExchField."Column No.", FieldMappingRecordId) then begin
                    TempDataExchFieldMapping.Get(FieldMappingRecordId);
                    if TempDataExchFieldMapping."Field ID" = CorpCardTrans.FieldNo("Card Last 4") then
                        CardLast4 := DataExchField.GetValue()
                    else begin
                        NormalizeMappedCurrencyCode(TempDataExchFieldMapping, DataExchField, CorpCardTrans, CorpCardValidateMgt);
                        ProcessDataExch.SetField(CorpCardRecRef, TempDataExchFieldMapping, DataExchField, TempFieldIdsToNegate);
                    end;
                end;
                HasNextField := DataExchField.Next() <> 0;
            until not HasNextField or (DataExchField."Line No." <> CurrentLineNo);

            ProcessDataExch.NegateAmounts(CorpCardRecRef, TempFieldIdsToNegate);
            CorpCardRecRef.SetTable(CorpCardTrans);
            NormalizeMappedTransFields(CorpCardTrans);
            if StrictMappingProvider then begin
                ValidationReason := '';
                if not ValidateStrictMappedFields(CorpCardProvider, CurrentLineNo, CorpCardTrans, ValidationReason) then begin
                    CorpCardTrans.Status := CorpCardTrans.Status::Exception;
                    InsertException(CorpCardStatement, CorpCardTrans, Enum::"EA Corp Card Exception Type"::Validation, ValidationReason);
                    CorpCardStatement.Exceptions += 1;
                    CorpCardStatement.Rejected += 1;
                    continue;
                end;
            end else
                BackfillMandatoryMappedFields(CorpCardProvider, FieldValueByColumnNo, SourcePayloadTxt, CurrentLineNo, CorpCardTrans, CardLast4);

            ValidationReason := '';
            if StrPos(UpperCase(CardLast4), 'CARDLAST4=') > 0 then
                CardLast4 := ExtractTaggedValue(UpperCase(CardLast4), 'CARDLAST4=');
            IsValid := CorpCardValidateMgt.TrySetCardLast4(CardLast4, CorpCardTrans, ValidationReason);
            if IsValid then
                IsValid := CorpCardValidateMgt.ValidateTrans(CorpCardTrans, ValidationReason);
            if not IsValid then begin
                CorpCardTrans.Status := CorpCardTrans.Status::Exception;
                if ValidationReason = '' then
                    ValidationReason := StrSubstNo(InvalidTransErr, CorpCardTrans."Provider Trans Id");
                InsertException(CorpCardStatement, CorpCardTrans, Enum::"EA Corp Card Exception Type"::Validation, ValidationReason);
                CorpCardStatement.Exceptions += 1;
                CorpCardStatement.Rejected += 1;
                continue;
            end;
            if CorpCardDedupMgt.IsDuplicate(CorpCardTrans) then begin
                CorpCardStatement.Duplicates += 1;
                continue;
            end;

            CorpCardTrans.Insert(true);
            CorpCardStatement.Imported += 1;
        until not HasNextField;

        CorpCardStatement.Modify();
    end;

    local procedure NormalizeMappedCurrencyCode(DataExchFieldMapping: Record "Data Exch. Field Mapping"; var DataExchField: Record "Data Exch. Field"; CorpCardTrans: Record "EA Corp Card Trans"; CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt")
    var
        CurrencyCode: Code[10];
    begin
        if DataExchFieldMapping."Field ID" <> CorpCardTrans.FieldNo("Currency Code") then
            exit;

        CurrencyCode := CopyStr(DataExchField.GetValue(), 1, MaxStrLen(CurrencyCode));
        CorpCardValidateMgt.NormalizeCurrencyCode(CurrencyCode);
        DataExchField.SetValueWithoutModifying(CurrencyCode);
    end;

    local procedure GetDataExchFieldValue(FieldValueByColumnNo: Dictionary of [Integer, Text]; ColumnNo: Integer): Text
    var
        FieldValue: Text;
    begin
        if not FieldValueByColumnNo.Get(ColumnNo, FieldValue) then
            exit('');

        exit(FieldValue);
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
            MissingFields := AppendFieldName(MissingFields, CorpCardTrans.FieldCaption("Provider Trans Id"));
        if CorpCardTrans."Trans Date" = 0D then
            MissingFields := AppendFieldName(MissingFields, CorpCardTrans.FieldCaption("Trans Date"));
        if CorpCardTrans.Amount = 0 then
            MissingFields := AppendFieldName(MissingFields, CorpCardTrans.FieldCaption(Amount));
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

    local procedure LoadFieldMappings(CorpCardProvider: Record "EA Corp Card Provider"; var TempDataExchFieldMapping: Record "Data Exch. Field Mapping" temporary; var FieldMappingRecordIdByColumnNo: Dictionary of [Integer, RecordId])
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Reset();
        DataExchFieldMapping.SetRange("Data Exch. Def Code", CorpCardProvider."Data Exch Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", CorpCardProvider."Data Exch Map Code");
        DataExchFieldMapping.SetRange("Table ID", Database::"EA Corp Card Trans");
        if DataExchFieldMapping.FindSet() then
            repeat
                TempDataExchFieldMapping := DataExchFieldMapping;
                TempDataExchFieldMapping.Insert();
                if not FieldMappingRecordIdByColumnNo.ContainsKey(DataExchFieldMapping."Column No.") then
                    FieldMappingRecordIdByColumnNo.Add(DataExchFieldMapping."Column No.", TempDataExchFieldMapping.RecordId());
            until DataExchFieldMapping.Next() = 0;
    end;

    local procedure InsertException(CorpCardStatement: Record "EA Corp Card Statement"; CorpCardTrans: Record "EA Corp Card Trans"; ExcpType: Enum "EA Corp Card Exception Type"; Message: Text[250])
    var
        CorpCardException: Record "EA Corp Card Exception";
    begin
        CorpCardException.Init();
        CorpCardException."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardException."Trans Entry No." := CorpCardTrans."Entry No.";
        CorpCardException."Exception Type" := ExcpType;
        CorpCardException.Message := Message;
        CorpCardException."Created DT" := CurrentDateTime();
        CorpCardException.Insert(true);
    end;

    local procedure NormalizeMappedTransFields(var CorpCardTrans: Record "EA Corp Card Trans")
    begin
        // CAMT mappings can carry key-value text in remittance/additional fields.
        if StrPos(CorpCardTrans.MCC, 'MCC=') > 0 then
            CorpCardTrans.MCC := CopyStr(ExtractTaggedValue(CorpCardTrans.MCC, 'MCC='), 1, MaxStrLen(CorpCardTrans.MCC));
        if (CorpCardTrans.Country = '') and (StrPos(CorpCardTrans."Merchant Raw", 'Country=') > 0) then
            CorpCardTrans.Country := CopyStr(ExtractTaggedValue(CorpCardTrans."Merchant Raw", 'Country='), 1, MaxStrLen(CorpCardTrans.Country));
    end;

    local procedure BackfillMandatoryMappedFields(CorpCardProvider: Record "EA Corp Card Provider"; FieldValueByColumnNo: Dictionary of [Integer, Text]; SourcePayloadTxt: Text; CurrentLineNo: Integer; var CorpCardTrans: Record "EA Corp Card Trans"; var CardLast4: Text)
    var
        DateTxt: Text;
    begin
        if CorpCardTrans."Provider Trans Id" = '' then
            CorpCardTrans."Provider Trans Id" := CopyStr(GetDataExchFieldValue(FieldValueByColumnNo, 1), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        if CorpCardTrans."Provider Trans Id" = '' then
            CorpCardTrans."Provider Trans Id" := CopyStr(GetDataExchFieldValueByColumnName(FieldValueByColumnNo, CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", 'ProviderTransId'), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        if CorpCardTrans."Provider Trans Id" = '' then
            CorpCardTrans."Provider Trans Id" := CopyStr(ReadProviderTransIdFromSourcePayload(SourcePayloadTxt, CurrentLineNo), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        if CardLast4 = '' then
            CardLast4 := GetDataExchFieldValueByColumnName(FieldValueByColumnNo, CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", 'CardLast4');
        if (CardLast4 = '') and (CorpCardTrans."Provider Trans Id" <> '') then
            CardLast4 := ReadCardLast4FromSourcePayload(SourcePayloadTxt, CorpCardTrans."Provider Trans Id");
        if CorpCardTrans.MCC = '' then
            CorpCardTrans.MCC := CopyStr(GetNormalizedMccValue(GetDataExchFieldValue(FieldValueByColumnNo, 8)), 1, MaxStrLen(CorpCardTrans.MCC));
        if CorpCardTrans.MCC = '' then
            CorpCardTrans.MCC := CopyStr(GetNormalizedMccValue(GetDataExchFieldValueByColumnName(FieldValueByColumnNo, CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", 'MCC')), 1, MaxStrLen(CorpCardTrans.MCC));
        if CorpCardTrans.MCC = '' then
            CorpCardTrans.MCC := CopyStr(GetNormalizedMccValue(CorpCardTrans."Merchant Raw"), 1, MaxStrLen(CorpCardTrans.MCC));
        if CorpCardTrans."Trans Date" = 0D then begin
            DateTxt := GetDataExchFieldValue(FieldValueByColumnNo, 3);
            if not ParseIsoDate(DateTxt, CorpCardTrans."Trans Date") then
                Evaluate(CorpCardTrans."Trans Date", DateTxt);
        end;
        if CorpCardTrans."Trans Date" = 0D then begin
            DateTxt := GetDataExchFieldValueByColumnName(FieldValueByColumnNo, CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", 'TransDate');
            if not ParseIsoDate(DateTxt, CorpCardTrans."Trans Date") then
                Evaluate(CorpCardTrans."Trans Date", DateTxt);
        end;
        if CorpCardTrans."Trans Date" = 0D then begin
            DateTxt := ReadTagValueByOccurrenceFromSourcePayload(SourcePayloadTxt, 'TransDate', CurrentLineNo);
            if not ParseIsoDate(DateTxt, CorpCardTrans."Trans Date") then
                Evaluate(CorpCardTrans."Trans Date", DateTxt);
        end;
        if CorpCardTrans."Posting Date" = 0D then begin
            DateTxt := GetDataExchFieldValue(FieldValueByColumnNo, 4);
            if not ParseIsoDate(DateTxt, CorpCardTrans."Posting Date") then
                Evaluate(CorpCardTrans."Posting Date", DateTxt);
        end;
        if CorpCardTrans."Posting Date" = 0D then begin
            DateTxt := GetDataExchFieldValueByColumnName(FieldValueByColumnNo, CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", 'PostingDate');
            if not ParseIsoDate(DateTxt, CorpCardTrans."Posting Date") then
                Evaluate(CorpCardTrans."Posting Date", DateTxt);
        end;
        if CorpCardTrans."Posting Date" = 0D then begin
            DateTxt := ReadTagValueByOccurrenceFromSourcePayload(SourcePayloadTxt, 'PostingDate', CurrentLineNo);
            if not ParseIsoDate(DateTxt, CorpCardTrans."Posting Date") then
                Evaluate(CorpCardTrans."Posting Date", DateTxt);
        end;
    end;

    local procedure GetDataExchFieldValueByColumnName(FieldValueByColumnNo: Dictionary of [Integer, Text]; DataExchDefCode: Code[20]; LineDefCode: Code[20]; ColumnName: Text): Text
    var
        ColumnNo: Integer;
    begin
        ColumnNo := GetColumnNoByName(DataExchDefCode, LineDefCode, ColumnName);
        if ColumnNo = 0 then
            exit('');

        exit(GetDataExchFieldValue(FieldValueByColumnNo, ColumnNo));
    end;

    local procedure GetColumnNoByName(DataExchDefCode: Code[20]; LineDefCode: Code[20]; ColumnName: Text): Integer
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        CacheKey: Text;
        ColumnNo: Integer;
    begin
        CacheKey := DataExchDefCode + '|' + LineDefCode + '|' + ColumnName;
        if ColumnNoByName.Get(CacheKey, ColumnNo) then
            exit(ColumnNo);

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", LineDefCode);
        DataExchColumnDef.SetRange(Name, ColumnName);
        if DataExchColumnDef.FindFirst() then
            ColumnNo := DataExchColumnDef."Column No.";

        ColumnNoByName.Add(CacheKey, ColumnNo);
        exit(ColumnNo);
    end;

    local procedure ReadSourcePayload(DataExch: Record "Data Exch."): Text
    var
        InStr: InStream;
        XmlBuilder: TextBuilder;
        XmlLineTxt: Text;
    begin
        DataExch.CalcFields("File Content");
        if not DataExch."File Content".HasValue() then
            exit('');

        DataExch."File Content".CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(XmlLineTxt);
            XmlBuilder.Append(XmlLineTxt);
        end;

        exit(XmlBuilder.ToText());
    end;

    local procedure ReadCardLast4FromSourcePayload(SourcePayloadTxt: Text; ProviderTransId: Code[100]): Text
    var
        TransactionStartPos: Integer;
        TransactionEndPos: Integer;
        TransactionXmlTxt: Text;
    begin
        if SourcePayloadTxt = '' then
            exit('');

        TransactionStartPos := StrPos(SourcePayloadTxt, StrSubstNo(ProviderTransIdXmlTok, ProviderTransId));
        if TransactionStartPos = 0 then
            exit('');

        TransactionXmlTxt := CopyStr(SourcePayloadTxt, TransactionStartPos);
        TransactionEndPos := StrPos(TransactionXmlTxt, '</Transaction>');
        if TransactionEndPos > 0 then
            TransactionXmlTxt := CopyStr(TransactionXmlTxt, 1, TransactionEndPos + StrLen('</Transaction>') - 1);

        exit(ExtractTagValue(TransactionXmlTxt, 'CardLast4'));
    end;

    local procedure ReadProviderTransIdFromSourcePayload(SourcePayloadTxt: Text; TransactionOccurrence: Integer): Text
    begin
        exit(ReadTagValueByOccurrenceFromSourcePayload(SourcePayloadTxt, 'ProviderTransId', TransactionOccurrence));
    end;

    local procedure ReadTagValueByOccurrenceFromSourcePayload(SourcePayloadTxt: Text; TagName: Text; Occurrence: Integer): Text
    begin
        if SourcePayloadTxt = '' then
            exit('');

        exit(ExtractTagValueByOccurrence(SourcePayloadTxt, TagName, Occurrence));
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
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure OnAfterDownload(CorpCardProvider: Record "EA Corp Card Provider"; var CorpCardStatement: Record "EA Corp Card Statement"; var DataExch: Record "Data Exch.")
    begin
    end;

    [IntegrationEvent(false, false)]
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure OnBeforeInjectSourceContent(CorpCardProvider: Record "EA Corp Card Provider"; CorpCardStatement: Record "EA Corp Card Statement"; var TempBlob: Codeunit "Temp Blob"; var SourceFileName: Text[250]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure OnAfterAck(StatementEntryNo: Integer)
    begin
    end;
}