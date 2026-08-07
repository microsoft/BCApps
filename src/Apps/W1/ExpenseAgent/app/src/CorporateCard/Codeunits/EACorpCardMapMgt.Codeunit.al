// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;
using System.Utilities;

codeunit 7227 EACorpCardMapMgt
{
    Access = Internal;

    var
        MandatoryFieldMapMissingErr: Label 'Missing Data Exchange field mapping for %1 on provider %2 (Definition: %3).', Comment = '%1 = Field caption, %2 = Provider code, %3 = Data Exchange Definition Code';

    internal procedure InitTransForBatch(var CorpCardTrans: Record EACorpCardTrans; BatchNo: Integer; ProviderCode: Code[20])
    begin
        CorpCardTrans.Init();
        CorpCardTrans."Batch No." := BatchNo;
        CorpCardTrans."Provider Code" := ProviderCode;
        CorpCardTrans.Status := CorpCardTrans.Status::Imported;
    end;

    internal procedure ValidateMandatoryFieldMappings(CorpCardProvider: Record EACorpCardProvider)
    var
        CorpCardTrans: Record EACorpCardTrans;
    begin
        EnsureFieldMappingExists(CorpCardProvider, CorpCardTrans.FieldNo("Card Id"), CorpCardTrans.FieldCaption("Card Id"));
        EnsureFieldMappingExists(CorpCardProvider, CorpCardTrans.FieldNo("Provider Trans Id"), CorpCardTrans.FieldCaption("Provider Trans Id"));
        EnsureFieldMappingExists(CorpCardProvider, CorpCardTrans.FieldNo("Trans Date"), CorpCardTrans.FieldCaption("Trans Date"));
        EnsureFieldMappingExists(CorpCardProvider, CorpCardTrans.FieldNo(Amount), CorpCardTrans.FieldCaption(Amount));
    end;

    local procedure EnsureFieldMappingExists(CorpCardProvider: Record EACorpCardProvider; FieldId: Integer; FieldCaption: Text)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.SetRange("Data Exch. Def Code", CorpCardProvider."Data Exch Def Code");
        DataExchFieldMapping.SetRange("Table ID", Database::EACorpCardTrans);
        DataExchFieldMapping.SetRange("Field ID", FieldId);

        if CorpCardProvider."Data Exch Map Code" <> '' then
            DataExchFieldMapping.SetRange("Data Exch. Line Def Code", CorpCardProvider."Data Exch Map Code");

        if DataExchFieldMapping.IsEmpty() then
            Error(MandatoryFieldMapMissingErr, FieldCaption, CorpCardProvider.Code, CorpCardProvider."Data Exch Def Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EACorpCardDataExchProv, 'OnProvideSourceContent', '', false, false)]
    local procedure OnProvideSourceContent(CorpCardProvider: Record EACorpCardProvider; CorpCardBatch: Record EACorpCardBatch; var TempBlob: Codeunit "Temp Blob"; var SourceFileName: Text[250]; var Handled: Boolean)
    var
        ProviderRefreshed: Record EACorpCardProvider;
        SourceInStr: InStream;
        TempOutStr: OutStream;
    begin
        if Handled then
            exit;

        if CorpCardProvider."Feed Type" = CorpCardProvider."Feed Type"::API then
            exit;

        if not ProviderRefreshed.Get(CorpCardProvider.Code) then
            exit;

        ProviderRefreshed.CalcFields("Source Payload");
        if not ProviderRefreshed."Source Payload".HasValue() then
            exit;

        ProviderRefreshed."Source Payload".CreateInStream(SourceInStr);
        TempBlob.CreateOutStream(TempOutStr);
        CopyStream(TempOutStr, SourceInStr);

        if ProviderRefreshed."Source File Name" <> '' then
            SourceFileName := ProviderRefreshed."Source File Name";

        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Process Data Exch.", 'OnSetFieldOnBeforeFieldRefValidate', '', false, false)]
    local procedure OnSetFieldOnBeforeFieldRefValidate(TransformedValue: Text; var DataExchField: Record "Data Exch. Field"; DataExchFieldMapping: Record "Data Exch. Field Mapping"; FieldRef: FieldRef; DataExchColumnDef: Record "Data Exch. Column Def"; var IsHandled: Boolean)
    var
        CorpCardTrans: Record EACorpCardTrans;
        NormalizedCardId: Text;
    begin
        if DataExchFieldMapping."Table ID" <> Database::EACorpCardTrans then
            exit;

        if DataExchFieldMapping."Field ID" <> CorpCardTrans.FieldNo("Card Id") then
            exit;

        if StrPos(UpperCase(TransformedValue), 'CARDID=') = 0 then
            exit;

        NormalizedCardId := ExtractTaggedValueCaseInsensitive(TransformedValue, 'CARDID=');
        if NormalizedCardId = '' then
            exit;

        FieldRef.Value := CopyStr(NormalizedCardId, 1, FieldRef.Length);
        FieldRef.Validate();
        IsHandled := true;
    end;

    local procedure ExtractTaggedValueCaseInsensitive(SourceText: Text; TagUpper: Text): Text
    var
        SourceUpper: Text;
        TagPos: Integer;
        ValuePos: Integer;
        EndPos: Integer;
        ValueTxt: Text;
    begin
        SourceUpper := UpperCase(SourceText);
        TagPos := StrPos(SourceUpper, TagUpper);
        if TagPos = 0 then
            exit('');

        ValuePos := TagPos + StrLen(TagUpper);
        if ValuePos > StrLen(SourceText) then
            exit('');

        ValueTxt := CopyStr(SourceText, ValuePos);
        EndPos := StrPos(ValueTxt, ';');
        if EndPos > 0 then
            ValueTxt := CopyStr(ValueTxt, 1, EndPos - 1);

        exit(DelChr(ValueTxt, '<>', ' "'));
    end;
}