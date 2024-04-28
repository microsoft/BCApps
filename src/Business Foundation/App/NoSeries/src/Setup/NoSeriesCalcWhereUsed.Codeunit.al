// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Reflection;
using System.Utilities;

codeunit 1 "Calc. No. Series Where-Used"
{

    var
        TempNoSeriesWhereUsed: Record "No. Series Where-Used" temporary;
        NextEntryNo: Integer;

    procedure ShowSetupForm(NoSeriesWhereUsed: Record "No. Series Where-Used")
    var
        // TODO: The "Find Record Management" codeunit is located in the W1 BaseApp Utilities
        // TODO: We would need to implement the Find Record Management into the System Application
        // PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
        RecordRefVariant: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSetupForm(NoSeriesWhereUsed, IsHandled);
        if IsHandled then
            exit;
        RecRef.Open(NoSeriesWhereUsed."Table ID");
        // TODO: The "Find Record Management" codeunit is located in the W1 BaseApp Utilities
        // TODO: We would need to implement the Find Record Management into the System Application
        // PageManagement.PageRun(RecRef);
        RecordRefVariant := RecRef;
        Page.Run(Page::"No. Series Where-Used List", RecordRefVariant);
    end;

    procedure CheckNoSeriesCode(NoSeriesCode: Code[20])
    begin
        CheckNoSeries(NoSeriesCode);
        ShowNoSeriesWhereUsed();
    end;

    local procedure ShowNoSeriesWhereUsed()
    begin
        OnBeforeShowNoSeriesWhereUsed(TempNoSeriesWhereUsed);

        TempNoSeriesWhereUsed.SetCurrentKey("Table Name");
        Page.RunModal(0, TempNoSeriesWhereUsed);
    end;

    procedure CheckNoSeries(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        TempTableBuffer: Record "Integer" temporary;
    begin
        NextEntryNo := 0;
        Clear(TempNoSeriesWhereUsed);
        TempNoSeriesWhereUsed.DeleteAll();
        NoSeries.Get(NoSeriesCode);
        TempNoSeriesWhereUsed."No. Series Code" := NoSeriesCode;
        TempNoSeriesWhereUsed."No. Series Description" := NoSeries.Description;

        if FillTableBuffer(TempTableBuffer) then
            repeat
                CheckTable(NoSeriesCode, TempTableBuffer.Number);
            until TempTableBuffer.Next() = 0;

        OnAfterCheckNoSeries(TempNoSeriesWhereUsed, NoSeriesCode);
    end;

    local procedure FillTableBuffer(var TableBuffer: Record "Integer"): Boolean
    var
        NoSeries: Record "No. Series";
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        TableRelationsMetadata.SetLoadFields("Related Table ID", "Related Field No.");
        TableRelationsMetadata.SetRange("Related Table ID", Database::"No. Series");
        TableRelationsMetadata.SetRange("Related Field No.", NoSeries.FieldNo(Code));
        if TableRelationsMetadata.FindSet() then
            repeat
                if not (TableRelationsMetadata."Table ID" in [Database::"No. Series", Database::"No. Series Relationship"]) then
                    AddTable(TableBuffer, TableRelationsMetadata."Table ID");
            until TableRelationsMetadata.Next() = 0;

        TableBuffer.Reset();

        OnAfterFillTableBuffer(TableBuffer);

        exit(TableBuffer.FindSet());
    end;

    procedure AddTable(var TableBuffer: Record "Integer"; TableID: Integer)
    begin
        if not TableBuffer.Get(TableID) then begin
            TableBuffer.Number := TableID;
            TableBuffer.Insert();
        end;
    end;

    local procedure CheckTable(NoSeriesCode: Code[20]; TableID: Integer)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        Field: Record Field;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        TempNoSeriesWhereUsed.Init();
        TempNoSeriesWhereUsed."Table ID" := TableID;
        TempNoSeriesWhereUsed."Table Name" := RecRef.Caption;

        TableRelationsMetadata.SetRange("Table ID", TableID);
        TableRelationsMetadata.SetRange("Related Table ID", Database::"No. Series");
        if TableRelationsMetadata.FindSet() then
            repeat
                Field.Get(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.");
                if (Field.Class = Field.Class::Normal) and (Field.ObsoleteState <> Field.ObsoleteState::Removed) then
                    CheckField(RecRef, TableRelationsMetadata, NoSeriesCode);
            until TableRelationsMetadata.Next() = 0;
    end;

    local procedure CheckField(var RecRef: RecordRef; TableRelationsMetadata: Record "Table Relations Metadata"; GLAccNo: Code[20])
    var
        FieldRef: FieldRef;
    begin
        RecRef.Reset();
        FieldRef := RecRef.Field(TableRelationsMetadata."Field No.");
        FieldRef.SetRange(GLAccNo);
        SetConditionFilter(RecRef, TableRelationsMetadata);
        if RecRef.FindSet() then
            repeat
                InsertGroupFromRecRef(RecRef, FieldRef.Caption);
            until RecRef.Next() = 0;
    end;

    local procedure SetConditionFilter(var RecRef: RecordRef; TableRelationsMetadata: Record "Table Relations Metadata")
    var
        FieldRef: FieldRef;
    begin
        if TableRelationsMetadata."Condition Field No." <> 0 then begin
            FieldRef := RecRef.Field(TableRelationsMetadata."Condition Field No.");
            FieldRef.SetFilter(TableRelationsMetadata."Condition Value");
        end;
    end;

    local procedure InsertGroupFromRecRef(var RecRef: RecordRef; FieldCaption: Text[80])
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
        FieldCaptionAndValue: Text;
    begin
        if NextEntryNo = 0 then
            NextEntryNo := TempNoSeriesWhereUsed.GetLastEntryNo() + 1;

        TempNoSeriesWhereUsed."Entry No." := NextEntryNo;
        TempNoSeriesWhereUsed."Field Name" := FieldCaption;
        TempNoSeriesWhereUsed.Line := '';
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            FieldCaptionAndValue := StrSubstNo('%1=%2', FieldRef.Caption, FieldRef.Value);
            if TempNoSeriesWhereUsed.Line = '' then
                TempNoSeriesWhereUsed.Line := CopyStr(FieldCaptionAndValue, 1, MaxStrLen(TempNoSeriesWhereUsed.Line))
            else
                TempNoSeriesWhereUsed.Line :=
                    CopyStr(TempNoSeriesWhereUsed.Line + ', ' + FieldCaptionAndValue, 1, MaxStrLen(TempNoSeriesWhereUsed.Line));

            case KeyFieldCount of
                1:
                    TempNoSeriesWhereUsed."Key 1" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(TempNoSeriesWhereUsed."Key 1"));
                2:
                    TempNoSeriesWhereUsed."Key 2" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(TempNoSeriesWhereUsed."Key 2"));
                3:
                    TempNoSeriesWhereUsed."Key 3" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(TempNoSeriesWhereUsed."Key 3"));
                4:
                    TempNoSeriesWhereUsed."Key 4" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(TempNoSeriesWhereUsed."Key 4"));
            end;
        end;
        NextEntryNo += 1;
        TempNoSeriesWhereUsed.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckNoSeries(var TempNoSeriesWhereUsed: Record "No. Series Where-Used" temporary; NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTableBuffer(var TableBuffer: Record "Integer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowNoSeriesWhereUsed(var NoSeriesWhereUsed: Record "No. Series Where-Used")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSetupForm(var NoSeriesWhereUsed: Record "No. Series Where-Used"; IsHandled: Boolean)
    begin
    end;

}