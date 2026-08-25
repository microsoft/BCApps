// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Agents;
using System.Telemetry;

codeunit 3319 "PA Matching Telemetry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata Agent = r,
        tabledata "Agent Task Log Entry" = r,
        tabledata "Agent Task Memory Entry" = r,
        tabledata "E-Document" = r,
        tabledata "E-Document Purchase Line" = r,
        tabledata "PA Matching Telemetry Log" = rimd;

    [EventSubscriber(ObjectType::Table, Database::"Agent Task", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyAgentTask(var Rec: Record "Agent Task"; var xRec: Record "Agent Task"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec.Status <> Rec.Status::Completed then
            exit;
        if xRec.Status = Rec.Status then
            exit;

        EmitMatchingTelemetry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Agent Task", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteAgentTask(var Rec: Record "Agent Task"; RunTrigger: Boolean)
    var
        MatchingTelemetryLog: Record "PA Matching Telemetry Log";
    begin
        if Rec.IsTemporary() then
            exit;
        if MatchingTelemetryLog.Get(Rec.ID) then
            MatchingTelemetryLog.Delete();
    end;

    local procedure EmitMatchingTelemetry(AgentTask: Record "Agent Task")
    var
        Agent: Record Agent;
        EDocument: Record "E-Document";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempMatchingSummaryLine: Record "PA Matching Summary Line" temporary;
        MatchingTelemetryLog: Record "PA Matching Telemetry Log";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        SummaryText: Text;
        Status: Text;
        EDocumentEntryNo: Integer;
        ExpectedLineCount: Integer;
        EmptyGuid: Guid;
    begin
        if MatchingTelemetryLog.Get(AgentTask.ID) then
            exit;

        if not Agent.Get(AgentTask."Agent User Security ID") then
            exit;
        if Agent."Agent Metadata Provider" <> "Agent Metadata Provider"::"Payables Agent" then
            exit;
        if not Evaluate(EDocumentEntryNo, AgentTask."External ID") then begin
            LogProcessingStatus(AgentTask, EDocumentNotFoundStatusTok, EmptyGuid, 0, 0);
            exit;
        end;
        if not EDocument.Get(EDocumentEntryNo) then begin
            LogProcessingStatus(AgentTask, EDocumentNotFoundStatusTok, EmptyGuid, 0, 0);
            exit;
        end;
        if not PayablesAgentSetup.WasEDocumentCreatedByAgent(EDocument) then
            exit;

        if not TryGetMatchingSummary(AgentTask.ID, SummaryText) then begin
            LogProcessingStatus(AgentTask, MissingSummaryStatusTok, EDocument.SystemId, 0, 0);
            exit;
        end;

        if not ParseSummary(SummaryText, TempMatchingSummaryLine, Status) then begin
            LogProcessingStatus(AgentTask, Status, EDocument.SystemId, 0, 0);
            exit;
        end;

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        ExpectedLineCount := EDocumentPurchaseLine.Count();
        if ExpectedLineCount <> TempMatchingSummaryLine.Count() then begin
            LogProcessingStatus(AgentTask, CountMismatchStatusTok, EDocument.SystemId, ExpectedLineCount, TempMatchingSummaryLine.Count());
            exit;
        end;

        if TempMatchingSummaryLine.FindSet() then
            repeat
                if not EDocumentPurchaseLine.Get(EDocument."Entry No", TempMatchingSummaryLine."Line No.") then begin
                    LogProcessingStatus(AgentTask, LineNotFoundStatusTok, EDocument.SystemId, ExpectedLineCount, TempMatchingSummaryLine.Count());
                    exit;
                end;
            until TempMatchingSummaryLine.Next() = 0;

        MatchingTelemetryLog.LockTable();
        if MatchingTelemetryLog.Get(AgentTask.ID) then
            exit;

        LogProcessingStatus(AgentTask, SuccessStatusTok, EDocument.SystemId, ExpectedLineCount, TempMatchingSummaryLine.Count());
        LogSummaryLines(AgentTask, EDocument, TempMatchingSummaryLine);

        MatchingTelemetryLog."Agent Task ID" := AgentTask.ID;
        MatchingTelemetryLog."E-Document System ID" := EDocument.SystemId;
        MatchingTelemetryLog."Emitted At" := CurrentDateTime();
        MatchingTelemetryLog.Insert();
    end;

    internal procedure ParseSummary(SummaryText: Text; var TempMatchingSummaryLine: Record "PA Matching Summary Line" temporary; var Status: Text): Boolean
    var
        RootObject: JsonObject;
        LinesArray: JsonArray;
        LinesToken: JsonToken;
        LineToken: JsonToken;
        LineObject: JsonObject;
        SchemaVersion: Integer;
    begin
        TempMatchingSummaryLine.Reset();
        TempMatchingSummaryLine.DeleteAll();

        if not RootObject.ReadFrom(SummaryText) then begin
            Status := InvalidJsonStatusTok;
            exit(false);
        end;
        if not TryGetInteger(RootObject, VersionTok, SchemaVersion) then begin
            Status := InvalidJsonStatusTok;
            exit(false);
        end;
        if SchemaVersion <> 1 then begin
            Status := UnsupportedSchemaStatusTok;
            exit(false);
        end;
        if not RootObject.Get(LinesTok, LinesToken) or not LinesToken.IsArray() then begin
            Status := InvalidJsonStatusTok;
            exit(false);
        end;

        LinesArray := LinesToken.AsArray();
        foreach LineToken in LinesArray do begin
            if not LineToken.IsObject() then begin
                Status := InvalidJsonStatusTok;
                exit(false);
            end;
            LineObject := LineToken.AsObject();
            if not TryReadSummaryLine(LineObject, TempMatchingSummaryLine, Status) then
                exit(false);
        end;

        Status := SuccessStatusTok;
        exit(true);
    end;

    local procedure TryReadSummaryLine(LineObject: JsonObject; var TempMatchingSummaryLine: Record "PA Matching Summary Line" temporary; var Status: Text): Boolean
    var
        LineNo: Integer;
        MatchMethod: Text;
        Confidence: Text;
        DeferralSource: Text;
        HasConflict: Boolean;
        NewPattern: Boolean;
    begin
        if not TryGetInteger(LineObject, LineNoTok, LineNo) or (LineNo <= 0) then begin
            Status := InvalidLineStatusTok;
            exit(false);
        end;
        if TempMatchingSummaryLine.Get(LineNo) then begin
            Status := DuplicateLineStatusTok;
            exit(false);
        end;
        if not TryGetText(LineObject, MatchMethodTok, MatchMethod) then begin
            Status := InvalidLineStatusTok;
            exit(false);
        end;
        if not TryGetText(LineObject, ConfidenceTok, Confidence) then begin
            Status := InvalidLineStatusTok;
            exit(false);
        end;
        if not TryGetText(LineObject, DeferralSourceTok, DeferralSource) then begin
            Status := InvalidLineStatusTok;
            exit(false);
        end;
        if not TryGetBoolean(LineObject, HasConflictTok, HasConflict) then begin
            Status := InvalidLineStatusTok;
            exit(false);
        end;
        if not TryGetBoolean(LineObject, NewPatternTok, NewPattern) then begin
            Status := InvalidLineStatusTok;
            exit(false);
        end;
        if not IsAllowedMatchMethod(MatchMethod) or not IsAllowedConfidence(Confidence) or not IsAllowedDeferralSource(DeferralSource) then begin
            Status := InvalidValueStatusTok;
            exit(false);
        end;

        TempMatchingSummaryLine.Init();
        TempMatchingSummaryLine."Line No." := LineNo;
        TempMatchingSummaryLine."Match Method" := CopyStr(MatchMethod, 1, MaxStrLen(TempMatchingSummaryLine."Match Method"));
        TempMatchingSummaryLine.Confidence := CopyStr(Confidence, 1, MaxStrLen(TempMatchingSummaryLine.Confidence));
        TempMatchingSummaryLine."Deferral Source" := CopyStr(DeferralSource, 1, MaxStrLen(TempMatchingSummaryLine."Deferral Source"));
        TempMatchingSummaryLine."Has Conflict" := HasConflict;
        TempMatchingSummaryLine."New Pattern" := NewPattern;
        TempMatchingSummaryLine.Insert();
        exit(true);
    end;

    local procedure TryGetMatchingSummary(AgentTaskID: BigInteger; var SummaryText: Text): Boolean
    var
        AgentTaskLogEntry: Record "Agent Task Log Entry";
        ContextText: Text;
    begin
        AgentTaskLogEntry.SetRange("Task ID", AgentTaskID);
        AgentTaskLogEntry.SetCurrentKey(ID);
        if not AgentTaskLogEntry.FindLast() then
            exit(false);

        repeat
            ContextText := ReadContext(AgentTaskLogEntry);
            if TryGetSummaryFromContext(ContextText, SummaryText) then
                exit(true);
        until AgentTaskLogEntry.Next(-1) = 0;
        exit(false);
    end;

    local procedure ReadContext(var AgentTaskLogEntry: Record "Agent Task Log Entry") ContextText: Text
    var
        AgentTaskMemoryEntry: Record "Agent Task Memory Entry";
        ContentInStream: InStream;
    begin
        AgentTaskLogEntry.CalcFields("Troubleshooting Info");
        if AgentTaskLogEntry."Troubleshooting Info".HasValue() then begin
            AgentTaskLogEntry."Troubleshooting Info".CreateInStream(ContentInStream, TextEncoding::UTF8);
            ContentInStream.Read(ContextText);
            exit;
        end;

        if not AgentTaskMemoryEntry.Get(AgentTaskLogEntry."Task ID", AgentTaskLogEntry."Memory Entry ID") then
            exit;
#pragma warning disable AL0432
        AgentTaskMemoryEntry.CalcFields(Context);
        if not AgentTaskMemoryEntry.Context.HasValue() then
            exit;
        AgentTaskMemoryEntry.Context.CreateInStream(ContentInStream, TextEncoding::UTF8);
        ContentInStream.Read(ContextText);
#pragma warning restore AL0432
    end;

    local procedure TryGetSummaryFromContext(ContextText: Text; var SummaryText: Text): Boolean
    var
        RootObject: JsonObject;
        MemorizedDataObject: JsonObject;
        MemorizedDataToken: JsonToken;
        SummaryToken: JsonToken;
    begin
        if (ContextText = '') or not RootObject.ReadFrom(ContextText) then
            exit(false);
        if not RootObject.Get(MemorizedDataTok, MemorizedDataToken) or not MemorizedDataToken.IsObject() then
            exit(false);
        MemorizedDataObject := MemorizedDataToken.AsObject();
        if not MemorizedDataObject.Get(SummaryKeyTok, SummaryToken) or not SummaryToken.IsValue() then
            exit(false);
        if SummaryToken.AsValue().IsNull() then
            exit(false);

        SummaryText := SummaryToken.AsValue().AsText();
        exit(SummaryText <> '');
    end;

    local procedure LogProcessingStatus(AgentTask: Record "Agent Task"; Status: Text; EDocumentSystemId: Guid; ExpectedLineCount: Integer; SummaryLineCount: Integer)
    var
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add(CategoryTok, PayablesAgentCategoryTok);
        CustomDimensions.Add(AgentTaskIdTok, Format(AgentTask.ID, 0, 9));
        CustomDimensions.Add(SchemaVersionTok, '1');
        CustomDimensions.Add(StatusTok, Status);
        CustomDimensions.Add(ExpectedLineCountTok, Format(ExpectedLineCount, 0, 9));
        CustomDimensions.Add(SummaryLineCountTok, Format(SummaryLineCount, 0, 9));
        if not IsNullGuid(EDocumentSystemId) then
            CustomDimensions.Add(EDocumentSystemIdTok, EDocImpSessionTelemetry.CreateSystemIdText(EDocumentSystemId));

        Telemetry.LogMessage('0000V7M', MatchingSummaryTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    local procedure LogSummaryLines(AgentTask: Record "Agent Task"; EDocument: Record "E-Document"; var TempMatchingSummaryLine: Record "PA Matching Summary Line" temporary)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not TempMatchingSummaryLine.FindSet() then
            exit;

        repeat
            EDocumentPurchaseLine.Get(EDocument."Entry No", TempMatchingSummaryLine."Line No.");
            Clear(CustomDimensions);
            CustomDimensions.Add(CategoryTok, PayablesAgentCategoryTok);
            CustomDimensions.Add(AgentTaskIdTok, Format(AgentTask.ID, 0, 9));
            CustomDimensions.Add(EDocumentSystemIdTok, EDocImpSessionTelemetry.CreateSystemIdText(EDocument.SystemId));
            CustomDimensions.Add(EDocumentLineSystemIdTok, EDocImpSessionTelemetry.CreateSystemIdText(EDocumentPurchaseLine.SystemId));
            CustomDimensions.Add(EDocumentLineNoTok, Format(TempMatchingSummaryLine."Line No.", 0, 9));
            CustomDimensions.Add(SchemaVersionTok, '1');
            CustomDimensions.Add(MatchMethodDimensionTok, TempMatchingSummaryLine."Match Method");
            CustomDimensions.Add(ConfidenceDimensionTok, TempMatchingSummaryLine.Confidence);
            CustomDimensions.Add(DeferralSourceDimensionTok, TempMatchingSummaryLine."Deferral Source");
            CustomDimensions.Add(HasConflictDimensionTok, Format(TempMatchingSummaryLine."Has Conflict", 0, 9));
            CustomDimensions.Add(NewPatternDimensionTok, Format(TempMatchingSummaryLine."New Pattern", 0, 9));

            Telemetry.LogMessage('0000V7N', MatchingSummaryLineTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        until TempMatchingSummaryLine.Next() = 0;
    end;

    local procedure IsAllowedMatchMethod(Value: Text): Boolean
    begin
        exit(Value in [PrepareDraftTok, ItemReferenceTok, TextToAccountTok, HistoricalTok, ChartOfAccountsTok, ItemsTok, PurchaseOrderTok, UserAssignedTok, UnmatchedTok]);
    end;

    local procedure IsAllowedConfidence(Value: Text): Boolean
    begin
        exit(Value in [HighTok, MediumTok, LowTok, NoneTok]);
    end;

    local procedure IsAllowedDeferralSource(Value: Text): Boolean
    begin
        exit(Value in [NoneTok, HistoryTok, TemplateTok, HistoryAndTemplateTok]);
    end;

    [TryFunction]
    local procedure TryGetInteger(JsonObject: JsonObject; PropertyName: Text; var Value: Integer)
    begin
        Value := JsonObject.GetInteger(PropertyName);
    end;

    [TryFunction]
    local procedure TryGetText(JsonObject: JsonObject; PropertyName: Text; var Value: Text)
    begin
        Value := JsonObject.GetText(PropertyName);
    end;

    [TryFunction]
    local procedure TryGetBoolean(JsonObject: JsonObject; PropertyName: Text; var Value: Boolean)
    begin
        Value := JsonObject.GetBoolean(PropertyName);
    end;

    var
        SummaryKeyTok: Label 'PAYABLES_AGENT_MATCHING_TELEMETRY', Locked = true;
        MemorizedDataTok: Label 'memorizedData', Locked = true;
        VersionTok: Label 'v', Locked = true;
        LinesTok: Label 'lines', Locked = true;
        LineNoTok: Label 'lineNo', Locked = true;
        MatchMethodTok: Label 'matchMethod', Locked = true;
        ConfidenceTok: Label 'confidence', Locked = true;
        DeferralSourceTok: Label 'deferralSource', Locked = true;
        HasConflictTok: Label 'hasConflict', Locked = true;
        NewPatternTok: Label 'newPattern', Locked = true;
        PrepareDraftTok: Label 'PrepareDraft', Locked = true;
        ItemReferenceTok: Label 'ItemReference', Locked = true;
        TextToAccountTok: Label 'TextToAccount', Locked = true;
        HistoricalTok: Label 'Historical', Locked = true;
        ChartOfAccountsTok: Label 'ChartOfAccounts', Locked = true;
        ItemsTok: Label 'Items', Locked = true;
        PurchaseOrderTok: Label 'PurchaseOrder', Locked = true;
        UserAssignedTok: Label 'UserAssigned', Locked = true;
        UnmatchedTok: Label 'Unmatched', Locked = true;
        HighTok: Label 'High', Locked = true;
        MediumTok: Label 'Medium', Locked = true;
        LowTok: Label 'Low', Locked = true;
        NoneTok: Label 'None', Locked = true;
        HistoryTok: Label 'History', Locked = true;
        TemplateTok: Label 'Template', Locked = true;
        HistoryAndTemplateTok: Label 'HistoryAndTemplate', Locked = true;
        SuccessStatusTok: Label 'Success', Locked = true;
        MissingSummaryStatusTok: Label 'MissingSummary', Locked = true;
        InvalidJsonStatusTok: Label 'InvalidJson', Locked = true;
        UnsupportedSchemaStatusTok: Label 'UnsupportedSchema', Locked = true;
        InvalidLineStatusTok: Label 'InvalidLine', Locked = true;
        InvalidValueStatusTok: Label 'InvalidValue', Locked = true;
        DuplicateLineStatusTok: Label 'DuplicateLineNo', Locked = true;
        LineNotFoundStatusTok: Label 'LineNotFound', Locked = true;
        CountMismatchStatusTok: Label 'CountMismatch', Locked = true;
        EDocumentNotFoundStatusTok: Label 'EDocumentNotFound', Locked = true;
        CategoryTok: Label 'Category', Locked = true;
        PayablesAgentCategoryTok: Label 'Payables Agent', Locked = true;
        AgentTaskIdTok: Label 'Agent Task Id', Locked = true;
        SchemaVersionTok: Label 'Schema Version', Locked = true;
        StatusTok: Label 'Summary Status', Locked = true;
        ExpectedLineCountTok: Label 'Expected Line Count', Locked = true;
        SummaryLineCountTok: Label 'Summary Line Count', Locked = true;
        EDocumentSystemIdTok: Label 'E-Document System Id', Locked = true;
        EDocumentLineSystemIdTok: Label 'E-Document Line System Id', Locked = true;
        EDocumentLineNoTok: Label 'E-Document Line No.', Locked = true;
        MatchMethodDimensionTok: Label 'Match Method', Locked = true;
        ConfidenceDimensionTok: Label 'Confidence', Locked = true;
        DeferralSourceDimensionTok: Label 'Deferral Source', Locked = true;
        HasConflictDimensionTok: Label 'Has Conflict', Locked = true;
        NewPatternDimensionTok: Label 'New Pattern', Locked = true;
        MatchingSummaryTelemetryMsg: Label 'Payables Agent Matching Summary', Locked = true;
        MatchingSummaryLineTelemetryMsg: Label 'Payables Agent Matching Summary Line', Locked = true;
}
