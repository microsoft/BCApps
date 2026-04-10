// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.CRM.Outlook;
using System.Reflection;
using System.Utilities;

codeunit 5336 "Integration Record Synch."
{

    trigger OnRun()
    begin
        TransferFields();
    end;

    var
        TempParameterTempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        TempTempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        ParameterSourceRecordRef: RecordRef;
        ParameterDestinationRecordRef: RecordRef;
        ParameterOnlyModified: Boolean;
        AnyFieldModified: Boolean;
        BidirectionalFieldModified: Boolean;
        CannotSplitTxt: Label 'Cannot split list of IDs.', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;

    procedure SetFieldMapping(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary)
    begin
        if TempParameterTempIntegrationFieldMapping.IsEmpty() then
            TempParameterTempIntegrationFieldMapping.Reset();
        TempParameterTempIntegrationFieldMapping.Copy(TempIntegrationFieldMapping, true);
        ResetFieldModifiedFlags();
    end;

    procedure SetParameters(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; OnlyTransferModifiedFields: Boolean)
    begin
        ParameterSourceRecordRef := SourceRecordRef;
        ParameterDestinationRecordRef := DestinationRecordRef;
        ParameterOnlyModified := OnlyTransferModifiedFields;
        ResetFieldModifiedFlags();
    end;

    procedure GetWasModified(): Boolean
    begin
        exit(AnyFieldModified);
    end;

    [Scope('OnPrem')]
    procedure GetWasBidirectionalFieldModified(): Boolean
    begin
        exit(BidirectionalFieldModified);
    end;

    [Scope('OnPrem')]
    procedure GetBidirectionalFieldModifiedContext(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary)
    begin
        TempIntegrationFieldMapping.Init();
        TempIntegrationFieldMapping.TransferFields(TempTempIntegrationFieldMapping);
        TempIntegrationFieldMapping.Insert();
    end;

    local procedure SetBidirectionalFieldModifiedContext(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary)
    begin
        TempTempIntegrationFieldMapping.Init();
        TempTempIntegrationFieldMapping.TransferFields(TempIntegrationFieldMapping);
        TempTempIntegrationFieldMapping.Insert();
    end;

    local procedure IsConstantDiffToDestination(ConstantValue: Text; DestinationFieldRef: FieldRef): Boolean
    var
        ConstantOptionIndex: Integer;
        CurrentOptionIndex: Integer;
    begin
        if DestinationFieldRef.Type() = FieldType::Option then begin
            ConstantOptionIndex := TextToOptionValue(ConstantValue, DestinationFieldRef);
            CurrentOptionIndex := TextToOptionValue(Format(DestinationFieldRef.Value()), DestinationFieldRef);
            exit(CurrentOptionIndex <> ConstantOptionIndex);
        end;
        exit(GetTextValue(DestinationFieldRef) <> ConstantValue);
    end;

    local procedure TextToOptionValue(InputText: Text; var FieldRef: FieldRef): Integer
    var
        IntVar: Integer;
    begin
        IntVar := OutlookSynchTypeConv.TextToOptionValue(InputText, FieldRef.OptionCaption());
        if IntVar < 0 then
            IntVar := OutlookSynchTypeConv.TextToOptionValue(InputText, FieldRef.OptionMembers());
        exit(IntVar);
    end;

    local procedure EvaluateTextToFieldRef(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    begin
        if FieldRef.Type = FieldType::Option then
            exit(EvaluateTextToOptionFieldRef(InputText, FieldRef, ToValidate));
        if FieldRef.Type = FieldType::Blob then begin
            SetTextValue(FieldRef, InputText);
            exit(true);
        end;
        exit(OutlookSynchTypeConv.EvaluateTextToFieldRef(InputText, FieldRef, ToValidate));
    end;

    local procedure EvaluateTextToOptionFieldRef(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        NewValue: Integer;
        OldValue: Integer;
    begin
        if FieldRef.Type <> FieldType::Option then
            exit(false);

        if FieldRef.Class in [FieldClass::FlowField, FieldClass::FlowFilter] then
            exit(true);

        if not Evaluate(NewValue, InputText) then
            NewValue := TextToOptionValue(InputText, FieldRef);

        if NewValue < 0 then
            exit(false);

        if ToValidate then begin
            OldValue := FieldRef.Value();
            if OldValue <> NewValue then
                FieldRef.Validate(NewValue);
        end else
            FieldRef.Value := NewValue;

        exit(true);
    end;

    local procedure IsFieldModified(var SourceFieldRef: FieldRef; var DestinationFieldRef: FieldRef): Boolean
    var
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeIsFieldModified(SourceFieldRef, DestinationFieldRef, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if DestinationFieldRef.Type = FieldType::Code then
            exit(Format(DestinationFieldRef.Value) <> UpperCase(DelChr(Format(SourceFieldRef.Value), '<>')));

        if (SourceFieldRef.Type = FieldType::Blob) or (DestinationFieldRef.Type = FieldType::Blob) then
            exit(GetTextValue(DestinationFieldRef) <> GetTextValue(SourceFieldRef));

        if DestinationFieldRef.Length <> SourceFieldRef.Length then begin
            if DestinationFieldRef.Length < SourceFieldRef.Length then
                exit(Format(DestinationFieldRef.Value) <> CopyStr(Format(SourceFieldRef), 1, DestinationFieldRef.Length));
            exit(CopyStr(Format(DestinationFieldRef.Value), 1, SourceFieldRef.Length) <> Format(SourceFieldRef));
        end;

        exit(Format(DestinationFieldRef.Value) <> Format(SourceFieldRef.Value));
    end;

    procedure GetIdFilterList(var IdDictionary: Dictionary of [Guid, Boolean]; var IdFilterList: List of [Text])
    var
        IdList: List of [Guid];
    begin
        IdList := IdDictionary.Keys();
        GetIdFilterList(IdList, IdFilterList);
    end;

    internal procedure GetMaxNumberOfConditions(): Integer
    var
        Handled: Boolean;
        MaxNumberOfConditions: Integer;
    begin
        OnGetMaxNumberOfConditions(Handled, MaxNumberOfConditions);
        if Handled then
            exit(MaxNumberOfConditions);

        exit(400);
    end;

    procedure GetIdFilterList(var IdList: List of [Guid]; var IdFilterList: List of [Text])
    var
        IdFilter: Text;
        I: Integer;
        Id: Guid;
        MaxCount: Integer;
    begin
        MaxCount := GetMaxNumberOfConditions();
        foreach Id in IdList do begin
            IdFilter += '|' + Id;
            I += 1;
            if I = MaxCount then begin
                IdFilter := IdFilter.TrimStart('|');
                IdFilterList.Add(IdFilter);
                IdFilter := '';
                I := 0;
            end;
        end;
        if IdFilter <> '' then begin
            IdFilter := IdFilter.TrimStart('|');
            IdFilterList.Add(IdFilter);
        end;
    end;

    procedure FindModifiedLocalRecords(var RecRef: RecordRef; TableFilter: Text; IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        SystemModifiedAtFieldRef: FieldRef;
    begin
        if TableFilter <> '' then
            RecRef.SetView(TableFilter);
        if IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." <> 0DT then begin
            SystemModifiedAtFieldRef := RecRef.Field(RecRef.SystemModifiedAtNo());
            SystemModifiedAtFieldRef.SetFilter('>%1', IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.");
        end;

        exit(RecRef.FindSet());
    end;

    internal procedure SplitLocalTableFilter(var IntegrationTableMapping: Record "Integration Table Mapping"; var TableFilterList: List of [Text]): Boolean
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(IntegrationTableMapping."Table ID", true);
        exit(SplitTableFilter(IntegrationTableMapping."Table ID", RecordRef.SystemIdNo(), IntegrationTableMapping.GetTableFilter(), TableFilterList));
    end;

    internal procedure SplitIntegrationTableFilter(var IntegrationTableMapping: Record "Integration Table Mapping"; var TableFilterList: List of [Text]): Boolean
    begin
        exit(SplitTableFilter(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", IntegrationTableMapping.GetIntegrationTableFilter(), TableFilterList));
    end;

    procedure SplitTableFilter(TableId: Integer; FieldNo: Integer; TableFilter: Text; var TableFilterList: List of [Text]): Boolean
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldFilter: Text;
        FieldFilterList: List of [Text];
    begin
        RecordRef.Open(TableId, true);
        RecordRef.SetView(TableFilter);
        FieldRef := RecordRef.Field(FieldNo);
        FieldFilter := FieldRef.GetFilter();
        if not SplitFieldFilter(FieldFilter, FieldFilterList) then begin
            TableFilterList.Add(TableFilter);
            exit(false);
        end;
        foreach FieldFilter in FieldFilterList do begin
            FieldRef.SetFilter(FieldFilter);
            TableFilter := RecordRef.GetView();
            TableFilterList.Add(TableFilter);
        end;
        exit(true);
    end;

    local procedure SplitFieldFilter(FieldFilter: Text; var FilterList: List of [Text]): Boolean
    var
        ConditionList: List of [Text];
        Condition: Text;
        PartFilter: Text;
        Length: Integer;
        Id: Guid;
        MaxCount: Integer;
        I: Integer;
        CannotSplit: Boolean;
    begin
        if DelChr(FieldFilter, '=', '.&<>=*@') <> FieldFilter then begin
            Session.LogMessage('0000GI3', CannotSplitTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(false);
        end;

        MaxCount := GetMaxNumberOfConditions();
        ConditionList := FieldFilter.Replace('(', '').Replace(')', '').Split('|');
        if ConditionList.Count() > MaxCount then begin
            foreach Condition in ConditionList do begin
                I += 1;
                if I = 1 then
                    Length := StrLen(Condition)
                else
                    if Length <> StrLen(Condition) then begin
                        CannotSplit := true;
                        Session.LogMessage('0000GGX', CannotSplitTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        break;
                    end;
                if not Evaluate(Id, Condition) then begin
                    CannotSplit := true;
                    Session.LogMessage('0000GGY', CannotSplitTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    break;
                end;
                if PartFilter <> '' then
                    PartFilter += '|' + Condition
                else
                    PartFilter := Condition;
                if I = MaxCount then begin
                    FilterList.Add(PartFilter);
                    PartFilter := '';
                    I := 0;
                end;
            end;
            if PartFilter <> '' then
                FilterList.Add(PartFilter);
        end else
            FilterList.Add(FieldFilter);

        if not CannotSplit then
            exit(true);

        Clear(FilterList);
        exit(false);
    end;

    internal procedure GetTableViewForSystemIds(TableNo: Integer; SystemIds: List of [Guid]) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        SystemIdFilter: Text;
    begin
        SystemIdFilter := JoinIDs(SystemIds, '|');
        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(RecordRef.SystemIdNo());
        FieldRef.SetFilter(SystemIdFilter);
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    procedure GetTableViewForRecordID(RecordID: RecordID) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Get(RecordID);
        FieldRef := RecordRef.Field(RecordRef.SystemIdNo());
        FieldRef.SetRange(FieldRef.Value());
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    internal procedure GetTableViewForRecordIDAndFlowFilters(IntegrationTableMapping: Record "Integration Table Mapping"; RecordID: RecordID) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        I: Integer;
        Pos: Integer;
        StartPos: Integer;
        EndPos: Integer;
        MappingTableFilter: Text;
        CurrentFieldFilter: Text;
    begin
        RecordRef.Get(RecordID);
        FieldRef := RecordRef.Field(RecordRef.SystemIdNo());
        FieldRef.SetRange(FieldRef.Value());

        MappingTableFilter := IntegrationTableMapping.GetTableFilter();
        for I := 1 to RecordRef.FieldCount() do begin
            FieldRef := RecordRef.FieldIndex(I);
            if FieldRef.Class = FieldClass::FlowFilter then begin
                Pos := StrPos(MappingTableFilter, 'Field' + Format(FieldRef.Number()) + '=');
                if Pos <> 0 then begin
                    CurrentFieldFilter := CopyStr(MappingTableFilter, Pos);
                    StartPos := StrPos(CurrentFieldFilter, '(');
                    EndPos := StrPos(CurrentFieldFilter, ')');
                    FieldRef.SetFilter(CopyStr(CurrentFieldFilter, StartPos, EndPos - StartPos + 1));
                end;
            end;
        end;
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    internal procedure GetTableViewForLocalRecords(var RecRef: RecordRef) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        IdFieldNo: Integer;
        IdFieldValue: Guid;
        TableNo: Integer;
        FilterText: Text;
    begin
        if not RecRef.FindSet() then
            exit;

        TableNo := RecRef.Number();
        IdFieldNo := RecRef.SystemIdNo();

        repeat
            IdFieldValue := RecRef.Field(IdFieldNo).Value();
            FilterText += '|' + IdFieldValue;
        until RecRef.Next() = 0;

        FilterText := FilterText.TrimStart('|');
        if FilterText = '' then
            exit;

        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(IdFieldNo);
        FieldRef.SetFilter(FilterText);
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    procedure JoinIDs(var IdList: List of [Guid]; Delimiter: Text[1]): Text
    var
        IdValue: Guid;
        tb: TextBuilder;
        isFirst: Boolean;
    begin
        isFirst := true;

        foreach IdValue in IdList do begin
            if (isFirst) then
                isFirst := false
            else
                tb.Append(Delimiter);

            tb.Append(IdValue);
        end;

        exit(tb.ToText())
    end;

    local procedure ResetFieldModifiedFlags()
    begin
        AnyFieldModified := false;
        BidirectionalFieldModified := false;
        TempTempIntegrationFieldMapping.DeleteAll();
    end;

    local procedure TransferFields()
    var
        IsBidirectional: Boolean;
    begin
        ResetFieldModifiedFlags();
        TempParameterTempIntegrationFieldMapping.FindSet();
        repeat
            IsBidirectional := TempParameterTempIntegrationFieldMapping.Bidirectional;
            if TransferField(
              TempParameterTempIntegrationFieldMapping."Source Field No.",
              TempParameterTempIntegrationFieldMapping."Destination Field No.",
              TempParameterTempIntegrationFieldMapping."Constant Value",
              TempParameterTempIntegrationFieldMapping."Not Null",
              TempParameterTempIntegrationFieldMapping."Validate Destination Field") then begin
                AnyFieldModified := true;
                if IsBidirectional and (not BidirectionalFieldModified) then begin
                    BidirectionalFieldModified := true;
                    SetBidirectionalFieldModifiedContext(TempParameterTempIntegrationFieldMapping);
                end;
            end;
        until TempParameterTempIntegrationFieldMapping.Next() = 0;
    end;

    local procedure TransferField(SourceFieldNo: Integer; DestinationFieldNo: Integer; ConstantValue: Text; SkipNullValue: Boolean; ValidateDestinationField: Boolean): Boolean
    var
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        CurrValue: Text;
        IsModified: Boolean;
        UseConstantValue: Boolean;
    begin
        DestinationFieldRef := ParameterDestinationRecordRef.Field(DestinationFieldNo);
        UseConstantValue := SourceFieldNo < 1;
        UseConstantValue := UseConstantValue or ((ConstantValue <> '') and (ParameterDestinationRecordRef.Number() = ParameterSourceRecordRef.Number()) and (SourceFieldNo = DestinationFieldNo));

        if UseConstantValue then begin
            if (not ParameterOnlyModified) or IsConstantDiffToDestination(ConstantValue, DestinationFieldRef) then begin
                CurrValue := GetTextValue(DestinationFieldRef);
                if EvaluateTextToFieldRef(ConstantValue, DestinationFieldRef, true) then
                    IsModified := (CurrValue <> GetTextValue(DestinationFieldRef)) or not ParameterOnlyModified;
            end;
        end else begin
            SourceFieldRef := ParameterSourceRecordRef.Field(SourceFieldNo);
            if (SourceFieldRef.Class = FieldClass::FlowField) or
               ((SourceFieldRef.Type = FieldType::Blob) and (not IsExternalTable(SourceFieldRef.Record().Number()))) then
                SourceFieldRef.CalcField();
            if (not ParameterOnlyModified) or IsFieldModified(SourceFieldRef, DestinationFieldRef) then begin
                CurrValue := GetTextValue(DestinationFieldRef);
                if TransferFieldData(SourceFieldRef, DestinationFieldRef, ValidateDestinationField, SkipNullValue) then
                    IsModified := (CurrValue <> GetTextValue(DestinationFieldRef)) or not ParameterOnlyModified;
            end;
        end;
        exit(IsModified);
    end;

    local procedure TransferFieldData(var SourceFieldRef: FieldRef; var DestinationFieldRef: FieldRef; ValidateDestinationField: Boolean; SkipNullGUID: Boolean): Boolean
    var
        NewValue: Variant;
        CurrValue: Text;
        IsModified: Boolean;
        IsValueFound: Boolean;
        NeedsConversion: Boolean;
    begin
        // OnTransferFieldData is an event for handling an exceptional mapping that is not implemented by integration records
        OnTransferFieldData(SourceFieldRef, DestinationFieldRef, NewValue, IsValueFound, NeedsConversion);
        if not IsValueFound then
            if SourceFieldRef.Type = FieldType::Blob then
                NewValue := GetTextValue(SourceFieldRef)
            else
                NewValue := SourceFieldRef.Value
        else
            if not NeedsConversion then begin
                if SkipNullGUID and NewValue.IsGuid() then
                    if IsNullGuid(NewValue) then
                        exit(false);
                IsModified := SetDestinationValue(DestinationFieldRef, NewValue, ValidateDestinationField);
                exit(IsModified);
            end;

        if DestinationFieldRef.Type in [FieldType::Date, FieldType::DateTime] then
            if Format(NewValue) = '' then
                NeedsConversion := true;

        if not NeedsConversion and
           (SourceFieldRef.Type = DestinationFieldRef.Type) and (DestinationFieldRef.Length >= SourceFieldRef.Length)
        then begin
            IsModified := SetDestinationValue(DestinationFieldRef, NewValue, ValidateDestinationField);
            exit(IsModified);
        end;
        CurrValue := GetTextValue(DestinationFieldRef);
        if EvaluateTextToFieldRef(Format(NewValue), DestinationFieldRef, ValidateDestinationField) then
            IsModified := (CurrValue <> GetTextValue(DestinationFieldRef)) or not ParameterOnlyModified;
        exit(IsModified);
    end;

    local procedure SetDestinationValue(var DestinationFieldRef: FieldRef; NewValue: Variant; ValidateDestinationField: Boolean): Boolean
    var
        CurrValue: Text;
        IsModified: Boolean;
        NewValueGuid: Guid;
    begin
        CurrValue := GetTextValue(DestinationFieldRef);
        IsModified := (CurrValue <> Format(NewValue)) or not ParameterOnlyModified;
        case DestinationFieldRef.Type of
            FieldType::Blob:
                SetTextValue(DestinationFieldRef, Format(NewValue));
            FieldType::Media:
                begin
                    Evaluate(NewValueGuid, Format(NewValue));
                    DestinationFieldRef.Value(NewValueGuid);
                end;
            else
                if IsModified and ValidateDestinationField then
                    DestinationFieldRef.Validate(NewValue)
                else
                    DestinationFieldRef.Value := NewValue;
        end;
        exit(IsModified);
    end;

    internal procedure GetTextValue(var FieldRef: FieldRef): Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        FieldValue: Text;
    begin
        if FieldRef.Type <> FieldType::Blob then
            exit(Format(FieldRef.Value));
        TempBlob.FromFieldRef(FieldRef);
        if TempBlob.HasValue() then begin
            TempBlob.CreateInStream(InStream, GetBlobFieldEncoding(FieldRef));
            InStream.Read(FieldValue);
        end;
        exit(FieldValue);
    end;

    internal procedure SetTextValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        if FieldRef.Type <> FieldType::Blob then begin
            FieldRef.Value := FieldValue;
            exit;
        end;

        if FieldValue <> '' then begin
            TempBlob.CreateOutStream(OutStream, GetBlobFieldEncoding(FieldRef));
            OutStream.Write(FieldValue);
        end;
        TempBlob.ToFieldRef(FieldRef);
    end;

    local procedure GetBlobFieldEncoding(var FieldRef: FieldRef): TextEncoding
    var
        Encoding: TextEncoding;
        Handled: Boolean;
    begin
        OnGetBlobFieldEncoding(FieldRef.Record().Number(), FieldRef.Number(), Encoding, Handled);
        if Handled then
            exit(Encoding);
        if IsExternalTable(FieldRef.Record().Number()) then
            exit(TextEncoding::UTF16);
        exit(TextEncoding::UTF8);
    end;

    local procedure IsExternalTable(TableId: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableId) then
            exit(TableMetadata.TableType <> TableMetadata.TableType::Normal);
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBlobFieldEncoding(TableNo: Integer; FieldNo: Integer; var Encoding: TextEncoding; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMaxNumberOfConditions(var Handled: Boolean; var Value: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsFieldModified(var SourceFieldRef: FieldRef; var DestinationFieldRef: FieldRef; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

