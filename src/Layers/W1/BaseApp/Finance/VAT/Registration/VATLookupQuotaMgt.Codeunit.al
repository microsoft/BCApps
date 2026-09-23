// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using System.Environment;
using System.Telemetry;

/// <summary>
/// Enforces the per-environment daily EU VIES lookup quota. Invoked as a dedicated codeunit run so the
/// counter read-modify-write and its commit form their own unit of work, keeping the increment durable
/// without committing the caller's transaction state as part of the quota logic.
/// </summary>
codeunit 247 "VAT Lookup Quota Mgt."
{
    Permissions = TableData "VAT Reg. No. Lookup Quota" = rimd;

    trigger OnRun()
    begin
        RegisterAndCheckQuota();
    end;

    var
        DailyQuotaExceededErr: Label 'VAT registration number validation against the EU VIES service has reached the daily limit for this environment. Try again tomorrow, and avoid verifying VAT registration numbers in bulk.';
        DailyQuotaReachedMsg: Label 'The daily EU VAT reg. no. validation limit was reached for this environment.', Locked = true;
        SecurityAuditDailyQuotaExceededTxt: Label 'An EU VAT Registration No. validation service (VIES) lookup was blocked because the environment reached its daily lookup limit.', Locked = true;
        EUVATRegNoValidationServiceTok: Label 'EUVATRegNoValidationServiceTelemetryCategoryTok', Locked = true;
        QuotaTestOverride: Boolean;
        QuotaTestMaxDailyCallCount: Integer;

    local procedure RegisterAndCheckQuota()
    var
        VATRegNoLookupQuota: Record "VAT Reg. No. Lookup Quota";
        EnvironmentInformation: Codeunit "Environment Information";
        AuditLog: Codeunit "Audit Log";
    begin
        // The unauthenticated EU VIES service deny-lists the shared outbound IP address of a cloud app service
        // when it receives high-volume validation, which then affects every co-located environment on that address.
        // Cap the number of VIES lookups per environment per day so a single environment cannot flood VIES - from
        // any session type (interactive, background or API) and from either the Base Application or a per-tenant
        // extension that reuses this codeunit - and get the shared address deny-listed. The count is kept in a
        // single row shared by all companies in the database (DataPerCompany = false) that is locked for the brief
        // read-modify-write, so concurrent sessions increment it atomically without lost updates. Enforced online
        // (SaaS) only; on-prem environments own their own outbound address and only affect themselves.
        if not EnvironmentInformation.IsSaaS() then
            exit;

        GetQuotaUnderLock(VATRegNoLookupQuota);

        // Reset the counter at the start of a new (UTC) day.
        if VATRegNoLookupQuota."Window Date" <> Today() then begin
            VATRegNoLookupQuota."Window Date" := Today();
            VATRegNoLookupQuota."Daily Call Count" := 0;
        end;

        // Block once the daily limit is reached. Blocked calls are not counted (they never reach the service).
        if VATRegNoLookupQuota."Daily Call Count" >= GetMaxDailyCallCount() then
            Error(DailyQuotaExceededErr);

        VATRegNoLookupQuota."Daily Call Count" += 1;

        // On the call that reaches the limit, record it once - after this, lookups are blocked for the rest of the day.
        if VATRegNoLookupQuota."Daily Call Count" = GetMaxDailyCallCount() then begin
            // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
            AuditLog.LogAuditMessage(SecurityAuditDailyQuotaExceededTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
            Session.LogMessage('0000VL7', DailyQuotaReachedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', EUVATRegNoValidationServiceTok);
        end;

        // Persist and commit the count in this dedicated run's unit of work before the outbound request: the
        // increment stays durable even if the subsequent VIES call or the caller transaction later fails, and the
        // row lock is released before the potentially slow VIES call.
        VATRegNoLookupQuota.Modify();
        Commit();
    end;

    local procedure GetQuotaUnderLock(var VATRegNoLookupQuota: Record "VAT Reg. No. Lookup Quota")
    begin
        VATRegNoLookupQuota.LockTable();
        if VATRegNoLookupQuota.Get() then
            exit;
        // Create the single row on first use. Do not rely on install/upgrade triggers - they are not guaranteed
        // to have run for every environment.
        VATRegNoLookupQuota.Init();
        VATRegNoLookupQuota."Primary Key" := '';
        VATRegNoLookupQuota.Insert();
    end;

    local procedure GetMaxDailyCallCount(): Integer
    begin
        if QuotaTestOverride then
            exit(QuotaTestMaxDailyCallCount);
        // Legitimate use is < ~200 lookups per environment per day (99th percentile). 2000 leaves generous headroom
        // while staying roughly 10x below the daily volume at which VIES deny-lists a shared outbound address.
        exit(2000);
    end;

    // The following members exist only so the automated tests can exercise the daily-quota decision logic
    // without calling the external VIES service. They are internal, so the Base Application test libraries can
    // reach them but per-tenant extensions cannot influence or bypass the quota.
    internal procedure SetVIESCallQuotaLimitForTest(MaxDailyCallCount: Integer)
    begin
        QuotaTestOverride := true;
        QuotaTestMaxDailyCallCount := MaxDailyCallCount;
    end;

    internal procedure InvokeVIESCallQuotaForTest()
    begin
        RegisterAndCheckQuota();
    end;

    internal procedure SeedVIESCallQuotaForTest(WindowDate: Date; CallCount: Integer)
    var
        VATRegNoLookupQuota: Record "VAT Reg. No. Lookup Quota";
    begin
        if not VATRegNoLookupQuota.Get() then begin
            VATRegNoLookupQuota.Init();
            VATRegNoLookupQuota."Primary Key" := '';
            VATRegNoLookupQuota.Insert();
        end;
        VATRegNoLookupQuota."Window Date" := WindowDate;
        VATRegNoLookupQuota."Daily Call Count" := CallCount;
        VATRegNoLookupQuota.Modify();
    end;

    internal procedure GetVIESCallCountForTest(): Integer
    var
        VATRegNoLookupQuota: Record "VAT Reg. No. Lookup Quota";
    begin
        if not VATRegNoLookupQuota.Get() then
            exit(0);
        if VATRegNoLookupQuota."Window Date" <> Today() then
            exit(0);
        exit(VATRegNoLookupQuota."Daily Call Count");
    end;

    internal procedure ClearVIESCallQuotaForTest()
    var
        VATRegNoLookupQuota: Record "VAT Reg. No. Lookup Quota";
    begin
        if VATRegNoLookupQuota.Get() then
            VATRegNoLookupQuota.Delete();
    end;
}
