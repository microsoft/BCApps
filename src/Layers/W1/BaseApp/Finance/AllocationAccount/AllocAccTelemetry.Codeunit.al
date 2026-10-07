// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using System.Telemetry;

codeunit 2676 "Alloc. Acc. Telemetry"
{
    SingleInstance = true;
    Access = Internal;

    internal procedure LogGeneralJournalPostingUsage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if LoggedGeneralJournalPosting then
            exit;

        FeatureTelemetry.LogUptake('0000KY1', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000KY5', GetFeatureTelemetryName(), 'Posted General Journal line with Allocation Account');
        LoggedGeneralJournalPosting := true;
    end;

    internal procedure LogSalesInvoicePostingUsage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if LoggedSalesInvoicePosting then
            exit;

        FeatureTelemetry.LogUptake('0000KY2', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000KY6', GetFeatureTelemetryName(), 'Posted Sales Invoice with Allocation Account');
        LoggedSalesInvoicePosting := true;
    end;

    internal procedure LogPurchaseInvoicePostingUsage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if LoggedPurchaseInvoicePosting then
            exit;

        FeatureTelemetry.LogUptake('0000KY3', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000KY7', GetFeatureTelemetryName(), 'Posted Purchase Invoice with Allocation Account');
        LoggedPurchaseInvoicePosting := true;
    end;

    internal procedure LogDefinedOverride()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if LoggedOverrideUsage then
            exit;

        FeatureTelemetry.LogUptake('0000KY4', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000KY8', GetFeatureTelemetryName(), 'Defined an override line');
        LoggedOverrideUsage := true;
    end;

    internal procedure GetFeatureTelemetryName(): Text
    begin
        exit('Allocation Accounts');
    end;

    var
        LoggedGeneralJournalPosting: Boolean;
        LoggedSalesInvoicePosting: Boolean;
        LoggedPurchaseInvoicePosting: Boolean;
        LoggedOverrideUsage: Boolean;
}
