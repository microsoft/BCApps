// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Agents;
using System.AI;
using System.Reflection;
using System.Security;

codeunit 3311 "PA Billing"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "E-Document Purchase Line" = r;

    var
        PayablesAgentDailyCountTok: Label 'PayablesAgentDailyCount', Locked = true;
        PayablesAgentDailyCountDateTok: Label 'date', Locked = true;
        PayablesAgentNoLinesDocumentCountTok: Label 'documentsWithoutLines', Locked = true;
        PayablesAgentAAChargedTok: Label 'autonomousActionsCharged', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Purchase Draft Utility", OnInsertedEDocumentPurchaseLines, '', false, false)]
    local procedure LogPurchaseDocumentDraftLinesProcessed(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        AgentSession: Codeunit "Agent Session";
        DraftBasedTelemetry: Codeunit "PA Draft Based Telemetry";
        AgentTaskID: BigInteger;
        SessionEDocumentEntryNo: Integer;
        NumberOfLines: Integer;
        NumberOfDocumentsWithoutLines: Integer;
    begin
        SessionEDocumentEntryNo := GetCurrentSessionEDocumentEntryNo();
        if EDocumentPurchaseHeader.IsTemporary() then begin
            DraftBasedTelemetry.LogBillingTemporaryHeader(SessionEDocumentEntryNo);
            exit;
        end;
        if (SessionEDocumentEntryNo <> EDocument."Entry No") then begin
            DraftBasedTelemetry.LogBillingUnmatchedDocument(SessionEDocumentEntryNo);
            exit;
        end;

        AgentTaskID := AgentSession.GetCurrentSessionAgentTaskId();
        NumberOfLines := 0;
        if not VerifyNumberOfLinesExtracted(EDocument, NumberOfLines) then begin
            NumberOfDocumentsWithoutLines := IncrementNoLinesDocumentsDailyCount();
            if NumberOfDocumentsWithoutLines > GetAllowedNumberOfDocumentsWithoutLinesPerDay() then
                DraftBasedTelemetry.LogBillingTooManyDocumentsWithoutLines(SessionEDocumentEntryNo, NumberOfDocumentsWithoutLines);
            exit;
        end else
            DraftBasedTelemetry.LogBillingLinesExtracted(GetLinesRange(NumberOfLines));

        LogPurchaseDocumentDraftCreated(EDocument, EDocumentPurchaseHeader, AgentTaskID);
        LogLinesExpense(EDocument, EDocumentPurchaseHeader, AgentTaskID, NumberOfLines);
    end;

    local procedure GetCurrentSessionEDocumentEntryNo(): Integer
    var
        EDocument: Record "E-Document";
        Task: Codeunit "Payables Agent Task";
    begin
        if not Task.LoadCurrentSession() then
            exit(0);
        if Task.GetVersion() <> "PA Version"::V1 then
            exit(0);
        if EDocument.GetBySystemId(Task.GetSourceId()) then
            exit(EDocument."Entry No");
        exit(0);
    end;

    local procedure GetLinesRange(NumberOfLines: Integer): Integer
    begin
        if NumberOfLines <= 1 then
            exit(1);
        if NumberOfLines <= 5 then
            exit(5);
        if NumberOfLines <= 10 then
            exit(10);
        if NumberOfLines <= 20 then
            exit(20);
        if NumberOfLines <= 50 then
            exit(50);
        if NumberOfLines <= 100 then
            exit(100);
        if NumberOfLines <= 500 then
            exit(500);

        exit(1000);
    end;

    local procedure LogPurchaseDocumentDraftCreated(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header"; AgentTaskID: BigInteger)
    var
        DraftBasedTelemetry: Codeunit "PA Draft Based Telemetry";
        CreateHeaderPrice: Integer;
        DescriptionText: Text;
        ProcessedHeaderForEDocumentLbl: Label 'E-Document: %1', Comment = '%1 - Number of E-Document for example 231', Locked = true;
        InvoiceLbl: Label 'Invoice: %1', Comment = '%1 - Invoice Number, for example INV-100';
        VendorLbl: Label 'Vendor: %1', Comment = '%1 - Name of the vendor';
        SeparatorTok: Label ' - ', Locked = true;
        CommaTok: Label ', ', Locked = true;
    begin
        CreateHeaderPrice := 10;
        DescriptionText := StrSubstNo(ProcessedHeaderForEDocumentLbl, EDocument."Entry No");
        if EDocumentPurchaseHeader."Sales Invoice No." <> '' then
            DescriptionText += SeparatorTok + StrSubstNo(InvoiceLbl, EDocumentPurchaseHeader."Sales Invoice No.")
        else
            DraftBasedTelemetry.LogBillingMissingInvoiceNumber();
        if EDocumentPurchaseHeader."Vendor Company Name" <> '' then
            DescriptionText += CommaTok + StrSubstNo(VendorLbl, EDocumentPurchaseHeader."Vendor Company Name")
        else
            DraftBasedTelemetry.LogBillingMissingVendorName();

        LogPATrackingRecord(AgentTaskID, Enum::"PA Billing Operation"::"Invoice Document Processed", DescriptionText, EDocument.SystemId, Database::"E-Document", CreateHeaderPrice);
    end;

    local procedure LogLinesExpense(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header"; AgentTaskID: BigInteger; NumberOfLines: Integer)
    var
        DescriptionText: Text;
        ProcessedLinesForEDocumentLbl: Label 'E-Document: %1 - Processed %2 lines', Comment = '%1 - Number of E-Document for example 231, %2 - Number of lines processed', Locked = true;
    begin
        DescriptionText := StrSubstNo(ProcessedLinesForEDocumentLbl, EDocument."Entry No", NumberOfLines);
        LogPATrackingRecord(AgentTaskID, Enum::"PA Billing Operation"::"Invoice Lines Processed", DescriptionText, EDocumentPurchaseHeader.SystemId, Database::"E-Document Purchase Header", NumberOfLines);
    end;

    local procedure VerifyNumberOfLinesExtracted(var EDocument: Record "E-Document"; var NumberOfLinesExtracted: Integer): Boolean
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        DraftBasedTelemetry: Codeunit "PA Draft Based Telemetry";
    begin
        EDocumentPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        NumberOfLinesExtracted := EDocumentPurchaseLine.Count();
        if NumberOfLinesExtracted = 0 then begin
            DraftBasedTelemetry.LogBillingNoLinesExtracted();
            exit(false);
        end;

        exit(true);
    end;

    local procedure LogPATrackingRecord(AgentTaskID: BigInteger; Operation: Enum "PA Billing Operation"; Description: Text; RecordSystemID: Guid; RecordTable: Integer; Usage: Integer)
    var
        AgentTask: Record "Agent Task";
        DraftBasedTelemetry: Codeunit "PA Draft Based Telemetry";
        CopilotQuota: Codeunit "Copilot Quota";
        UniqueID: Text[1024];
        NewUsageConsumed: Decimal;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
        ExcludeFromBilling: Boolean;
    begin
        if not AgentTask.Get(AgentTaskID) then begin
            DraftBasedTelemetry.LogBillingAgentTaskNotFound();
            exit;
        end;

        // Is tasks excluded from billing
        ExcludeFromBilling := AgentTask."Billing Context" = Enum::"Agent Task Billing Context"::Excluded;

        UniqueID := GetUniqueID(AgentTaskID, Operation, RecordSystemID, RecordTable);
        if CopilotQuota.IsAgentUserAIConsumptionLogged(UniqueID) and not ExcludeFromBilling then begin
            DraftBasedTelemetry.LogBillingDuplicateOperation();
            exit;
        end;

        CopilotQuotaUsageType := Enum::"Copilot Quota Usage Type"::"Autonomous Action";
        NewUsageConsumed := UpdateTotalAmountDailyCount(Usage);
        if (NewUsageConsumed > GetMaximumNumberOfChargeableAutonomousActionsPerDay()) and not ExcludeFromBilling then begin
            DraftBasedTelemetry.LogBillingDailyLimitReached(NewUsageConsumed);
            exit;
        end;

        DraftBasedTelemetry.LogBillingOperationCreated(Format(Operation, 0, 9), ExcludeFromBilling);

        CopilotQuota.LogAgentUserAIConsumption(Enum::"Copilot Capability"::"Payables Agent", Usage, CopilotQuotaUsageType, AgentTaskID, Format(Operation), Description, UniqueID, ExcludeFromBilling);
    end;

    local procedure GetUniqueID(AgentTaskID: BigInteger; Operation: Enum "PA Billing Operation"; RecordSystemID: Guid; RecordTable: Integer): Text[1024]
    var
        UniqueID: Text[1024];
    begin
        UniqueID := Format(Enum::"Agent Metadata Provider"::"Payables Agent", 0, 9) + '-' + Format(AgentTaskID, 0, 9) + '-' + Format(Operation, 0, 9) + '-' + Format(RecordTable, 0, 9) + '-' + RecordSystemID;
        exit(UniqueID);
    end;

    local procedure IncrementNoLinesDocumentsDailyCount() TotalNonDocuments: Integer
    var
        IsolatedStorageRec: Record "Isolated Storage";
        UsageJsonObject: JsonObject;
        NewUsageJsonText: Text;
    begin
        IsolatedStorageRec.LockTable();
        UsageJsonObject := GetTodayUsageJsonObject();
        TotalNonDocuments := UsageJsonObject.GetInteger(PayablesAgentNoLinesDocumentCountTok, true) + 1;
        UsageJsonObject.Replace(PayablesAgentNoLinesDocumentCountTok, TotalNonDocuments);
        UsageJsonObject.WriteTo(NewUsageJsonText);
        IsolatedStorage.Set(PayablesAgentDailyCountTok, NewUsageJsonText);
        exit(TotalNonDocuments);
    end;

    local procedure UpdateTotalAmountDailyCount(NewAutonomousActions: Integer) TotalDailyAutonomousActions: Integer
    var
        IsolatedStorageRec: Record "Isolated Storage";
        UsageJsonObject: JsonObject;
        NewUsageJsonText: Text;
    begin
        IsolatedStorageRec.LockTable();
        UsageJsonObject := GetTodayUsageJsonObject();
        TotalDailyAutonomousActions := UsageJsonObject.GetInteger(PayablesAgentAAChargedTok, true) + NewAutonomousActions;
        UsageJsonObject.Replace(PayablesAgentAAChargedTok, TotalDailyAutonomousActions);
        UsageJsonObject.WriteTo(NewUsageJsonText);
        IsolatedStorage.Set(PayablesAgentDailyCountTok, NewUsageJsonText);
        exit(TotalDailyAutonomousActions);
    end;

    local procedure GetTodayUsageJsonObject() TodayUsageJsonObject: JsonObject;
    var
        UsageJsonText: Text;
    begin
        if not IsolatedStorage.Get(PayablesAgentDailyCountTok, UsageJsonText) then begin
            TodayUsageJsonObject.ReadFrom(InitializeTodayUsageJsonText());
            exit;
        end;

        TodayUsageJsonObject.ReadFrom(UsageJsonText);
        if TodayUsageJsonObject.GetText(PayablesAgentDailyCountDateTok) = GetCurrentUTCDateText() then
            exit(TodayUsageJsonObject);

        TodayUsageJsonObject.ReadFrom(InitializeTodayUsageJsonText());
    end;

    local procedure GetCurrentUTCDateText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(Format(TypeHelper.GetCurrUTCDateTime().Date, 0, 9));
    end;

    local procedure GetAllowedNumberOfDocumentsWithoutLinesPerDay(): Integer
    begin
        exit(1000);
    end;

    local procedure GetMaximumNumberOfChargeableAutonomousActionsPerDay(): Integer
    begin
        exit(4000);
    end;

    local procedure InitializeTodayUsageJsonText(): Text
    begin
        exit(StrSubstNo('{"%1":"%2","%3":%4,"%5":%6}', PayablesAgentDailyCountDateTok, GetCurrentUTCDateText(), PayablesAgentNoLinesDocumentCountTok, 0, PayablesAgentAAChargedTok, 0));
    end;
}