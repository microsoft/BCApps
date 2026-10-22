// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Telemetry;

codeunit 3325 "PA Telemetry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure FeatureName(): Text
    begin
        exit(CategoryTok);
    end;

    internal procedure GetCustomDimensions() CustomDimensions: Dictionary of [Text, Text]
    begin
        CustomDimensions.Set('category', CategoryTok);
    end;

    internal procedure GetTaskDimensions(PATask: Codeunit "Payables Agent Task") CustomDimensions: Dictionary of [Text, Text]
    var
        PASetup: Codeunit "PA Setup";
    begin
        PASetup.GetSetup();
        // 'Category' (capitalized) is kept for the task events that always used it.
        CustomDimensions.Set('Category', CategoryTok);
        CustomDimensions.Set('Version', Format(PATask.GetVersion(), 0, 9));
        CustomDimensions.Set('SystemId', LowerCase(Format(PATask.GetSourceId())).Replace('{', '').Replace('}', ''));
        CustomDimensions.Set('AgentTaskId', Format(PATask.GetAgentTaskId(), 0, 9));
        CustomDimensions.Set('SourceType', Format(PATask.GetSourceType(), 0, 9));
        CustomDimensions.Set('EmailReviewPolicy', Format(PASetup.GetEmailReviewPolicy(), 0, 9));
    end;

    internal procedure GetSourceDimensions(PATaskSource: Codeunit "PA Task Source") CustomDimensions: Dictionary of [Text, Text]
    var
        PASetup: Codeunit "PA Setup";
    begin
        PASetup.GetSetup();
        CustomDimensions.Set('Category', CategoryTok);
        CustomDimensions.Set('Version', Format(PATaskSource.GetVersion(), 0, 9));
        CustomDimensions.Set('SystemId', LowerCase(Format(PATaskSource.GetId())).Replace('{', '').Replace('}', ''));
        CustomDimensions.Set('SourceType', Format(PATaskSource.GetSourceType(), 0, 9));
        CustomDimensions.Set('EmailReviewPolicy', Format(PASetup.GetEmailReviewPolicy(), 0, 9));
    end;

    internal procedure LogTaskReceived(PATask: Codeunit "Payables Agent Task"; RequiresReview: Boolean)
    var
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions := GetTaskDimensions(PATask);
        CustomDimensions.Set('RequiresReview', Format(RequiresReview, 0, 9));
        Telemetry.LogMessage('0000PJA', 'Payables Agent Task Received', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    internal procedure LogTaskSkippedSenderRejected(PATaskSource: Codeunit "PA Task Source")
    var
        Telemetry: Codeunit Telemetry;
    begin
        Telemetry.LogMessage('0000QJ2', 'Payables Agent Task Skipped: sender rejected', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetSourceDimensions(PATaskSource));
    end;

    internal procedure LogTrialTaskCreated(TrialInvoiceCount: Integer; TrialInvoiceLimit: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions := GetCustomDimensions();
        CustomDimensions.Add('TrialInvoiceCount', Format(TrialInvoiceCount, 0, 9));
        CustomDimensions.Add('TrialInvoiceLimit', Format(TrialInvoiceLimit, 0, 9));
        CustomDimensions.Add('ExcludeBilling', Format(false, 0, 9)); // Logged before billing is excluded, as it always was.
        Session.LogMessage('0000SEE', 'Agent Task created in trial mode. Skipping billing for invoice.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    var
        CategoryTok: Label 'Payables Agent', Locked = true;
}
