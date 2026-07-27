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
                  tabledata "Data Exch. Field" = rimd,
                  tabledata "Data Exch. Field Mapping" = r;

    var
        ProviderDefCodeMissingErr: Label 'Data Exchange Definition Code must be set on provider %1.', Comment = '%1 = Provider code';
        InvalidTransErr: Label 'Mandatory data is missing for provider transaction %1.', Comment = '%1 = Provider transaction ID';

    procedure Download(var CorpCardBatch: Record EACorpCardBatch)
    var
        CorpCardProvider: Record EACorpCardProvider;
        DataExch: Record "Data Exch.";
    begin
        CorpCardProvider.Get(CorpCardBatch."Provider Code");
        if CorpCardProvider."Data Exch Def Code" = '' then
            Error(ProviderDefCodeMissingErr, CorpCardProvider.Code);

        DataExch.Init();
        DataExch."Data Exch. Def Code" := CorpCardProvider."Data Exch Def Code";
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
    begin
        CorpCardBatch.Get(BatchNo);
        if CorpCardBatch."Data Exch Entry No." = 0 then
            exit;

        CorpCardProvider.Get(CorpCardBatch."Provider Code");
        DataExch.Get(CorpCardBatch."Data Exch Entry No.");
        DataExchDef.Get(CorpCardProvider."Data Exch Def Code");
        CorpCardMapMgt.ValidateMandatoryFieldMappings(CorpCardProvider);

        if not DataExch.ImportToDataExch(DataExchDef) then begin
            CorpCardBatch.Status := CorpCardBatch.Status::Failed;
            CorpCardBatch.Rejected += 1;
            CorpCardBatch.Modify();
            exit;
        end;

        MapDataExchToTrans(CorpCardBatch, CorpCardProvider, DataExch);
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

            if not CorpCardValidateMgt.ValidateTrans(CorpCardTrans) then begin
                CorpCardTrans.Status := CorpCardTrans.Status::Exception;
                InsertException(CorpCardBatch, CorpCardTrans, Enum::EACorpCardExcpType::Validation, StrSubstNo(InvalidTransErr, CorpCardTrans."Provider Trans Id"));
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