namespace System.IO;

using Microsoft.Bank.Payment;
using System.Reflection;

codeunit 1269 "Export Mapping"
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExchMapping: Record "Data Exch. Mapping";
        TempDataExchFlowFieldGrBuff: Record "Data Exch. FlowField Gr. Buff." temporary;
        PaymentExportMgt: Codeunit "Payment Export Mgt";
        SourceRecRef: RecordRef;
        Window: Dialog;
        LineNo: Integer;
    begin
        FindMapping(DataExchMapping, Rec."Data Exch. Def Code", Rec."Data Exch. Line Def Code");
        GetSourceRecRefBuffer(SourceRecRef, TempDataExchFlowFieldGrBuff, DataExchMapping, ReadTableFilters(Rec));
        Window.Open(ProgressMsg);
        repeat
            LineNo += 1;
            Window.Update(1, LineNo);
            PaymentExportMgt.ProcessColumnMapping(Rec, SourceRecRef, TempDataExchFlowFieldGrBuff, LineNo, Rec."Data Exch. Line Def Code", SourceRecRef.Number);
        until SourceRecRef.Next() = 0;

        Window.Close();
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Processing line no. #1######.';
        MappingNotFoundErr: Label 'No mapping was found for format definition %1 and line definition %2.';
        RecordsNotFoundErr: Label 'No records were found for source table %1 using the filters: %2.';
#pragma warning restore AA0470

    local procedure FindMapping(var DataExchMapping: Record "Data Exch. Mapping"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20])
    begin
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);

        if not DataExchMapping.FindFirst() then
            Error(MappingNotFoundErr, DataExchDefCode, DataExchLineDefCode);
    end;

    procedure GetSourceRecRefBuffer(var RecRef: RecordRef; var DataExchFlowFieldGrBuff: Record "Data Exch. FlowField Gr. Buff."; DataExchMapping: Record "Data Exch. Mapping"; Filters: Text)
    var
        DataExchFieldGrouping: Record "Data Exch. Field Grouping";
        TempField, TempField2 : Record "Field" temporary;
        SourceRecRef: RecordRef;
        FieldRef, SourceFieldRef : FieldRef;
        GroupingExists: Boolean;
        DecValue, SourceDecValue : Decimal;
        IsHandled: Boolean;
    begin
        DataExchFieldGrouping.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldGrouping.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        GroupingExists := not DataExchFieldGrouping.IsEmpty();

        RecRef.Open(DataExchMapping."Table ID", GroupingExists);

        if GroupingExists then begin
            GetContextFields(DataExchMapping, TempField);
            GetCountableFields(DataExchMapping, TempField2);

            SourceRecRef.Open(DataExchMapping."Table ID");
            SourceRecRef.SetView(Filters);
            if SourceRecRef.FindSet() then
                repeat
                    DataExchFieldGrouping.FindSet();
                    repeat
                        SourceFieldRef := SourceRecRef.Field(DataExchFieldGrouping."Field ID");
                        FieldRef := RecRef.Field(DataExchFieldGrouping."Field ID");
                        FieldRef.SetRange(SourceFieldRef.Value);
                    until DataExchFieldGrouping.Next() = 0;

                    if RecRef.FindFirst() then begin
                        if TempField2.FindSet() then
                            repeat
                                SourceFieldRef := SourceRecRef.Field(TempField2."No.");
                                FieldRef := RecRef.Field(TempField2."No.");

                                if SourceFieldRef.Class = SourceFieldRef.Class::FlowField then
                                    SourceFieldRef.CalcField();
                                SourceDecValue := SourceFieldRef.Value();

                                if SourceFieldRef.Class = SourceFieldRef.Class::FlowField then begin
                                    DataExchFlowFieldGrBuff.Get(RecRef.RecordId, SourceFieldRef.Number);
                                    DataExchFlowFieldGrBuff.Value += SourceDecValue;
                                    DataExchFlowFieldGrBuff.Modify();
                                end else begin
                                    DecValue := FieldRef.Value();
                                    FieldRef.Value := DecValue + SourceDecValue;
                                end;
                            until TempField2.Next() = 0;
                        RecRef.Modify();
                    end else begin
                        if TempField.FindSet() then
                            repeat
                                SourceFieldRef := SourceRecRef.Field(TempField."No.");
                                FieldRef := RecRef.Field(TempField."No.");
                                if (SourceFieldRef.Class = SourceFieldRef.Class::FlowField) and
                                    (SourceFieldRef.Type in [SourceFieldRef.Type::Decimal, SourceFieldRef.Type::Integer])
                                then begin
                                    SourceFieldRef.CalcField();
                                    DataExchFlowFieldGrBuff.Init();
                                    DataExchFlowFieldGrBuff."Record ID" := SourceRecRef.RecordId;
                                    DataExchFlowFieldGrBuff."Field ID" := SourceFieldRef.Number;
                                    DataExchFlowFieldGrBuff.Value := SourceFieldRef.Value();
                                    DataExchFlowFieldGrBuff.Insert();
                                end else
                                    FieldRef.Value := SourceFieldRef.Value();
                            until TempField.Next() = 0;
                        RecRef.Insert();
                    end;
                    RecRef.Reset();
                until SourceRecRef.Next() = 0;
        end else
            RecRef.SetView(Filters);

        if DataExchMapping."Key Index" <> 0 then
            RecRef.CurrentKeyIndex(DataExchMapping."Key Index");

        if not RecRef.FindSet() then begin
            OnBeforeCheckRecRefCount(IsHandled, DataExchMapping);
            if not IsHandled then
                Error(RecordsNotFoundErr, RecRef.Number(), RecRef.GetView());
        end;
    end;

    local procedure ReadTableFilters(DataExch: Record "Data Exch.") TableFilters: Text
    var
        TableFiltersInStream: InStream;
    begin
        if not DataExch."Table Filters".HasValue() then
            exit('');

        DataExch.CalcFields("Table Filters");
        DataExch."Table Filters".CreateInStream(TableFiltersInStream);
        TableFiltersInStream.ReadText(TableFilters);
    end;

    local procedure GetContextFields(DataExchMapping: Record "Data Exch. Mapping"; var TempField: Record "Field")
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchFieldGrouping: Record "Data Exch. Field Grouping";
        "Field": Record "Field";
    begin
        TempField.Reset();
        TempField.DeleteAll();

        Field.SetRange(TableNo, DataExchMapping."Table ID");
        Field.SetRange(IsPartOfPrimaryKey, true);
        if Field.FindSet() then
            repeat
                TempField := Field;
                TempField.Insert();
            until Field.Next() = 0;

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        if DataExchFieldMapping.FindSet() then
            repeat
                AddFieldToTemp(DataExchMapping."Table ID", DataExchFieldMapping."Field ID", TempField);
            until DataExchFieldMapping.Next() = 0;

        DataExchFieldGrouping.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldGrouping.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        if DataExchFieldGrouping.FindSet() then
            repeat
                AddFieldToTemp(DataExchMapping."Table ID", DataExchFieldGrouping."Field ID", TempField);
            until DataExchFieldGrouping.Next() = 0;
    end;

    local procedure GetCountableFields(DataExchMapping: Record "Data Exch. Mapping"; var TempField: Record "Field")
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        "Field": Record "Field";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
    begin
        TempField.Reset();
        TempField.DeleteAll();

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        if DataExchFieldMapping.FindSet() then
            repeat
                if Field.Get(DataExchMapping."Table ID", DataExchFieldMapping."Field ID") and
                    (Field.Type in [Field.Type::Integer, Field.Type::Decimal])
                then
                    if (not ConfigValidateMgt.IsKeyField(Field.TableNo, Field."No.")) and (not TempField.Get(Field.TableNo, Field."No.")) then begin
                        TempField := Field;
                        TempField.Insert();
                    end;
            until DataExchFieldMapping.Next() = 0;
    end;

    local procedure AddFieldToTemp(TableID: Integer; FieldID: Integer; var TempField: Record Field)
    var
        "Field": Record Field;
    begin
        if Field.Get(TableID, FieldID) and
            (Field.ObsoleteState <> Field.ObsoleteState::Removed) and
            (not TempField.Get(TableID, FieldID))
        then begin
            TempField := Field;
            TempField.Insert();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRecRefCount(var IsHandled: Boolean; DataExchMapping: Record "Data Exch. Mapping")
    begin
    end;

}
