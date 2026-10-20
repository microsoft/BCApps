// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Telemetry;

/// <summary>
/// The single place where the Payables Agent emits telemetry about its tasks. Events keep their tags whichever the
/// Payables Agent version: the version is a custom dimension ("PAVersion"), so queries keep working across v1 and v2.
/// Task dimensions come from "PA Task" (and "PA Detailed Setup" for the setup), never from the backing records directly.
/// </summary>
codeunit 3325 "PA Telemetry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Dimensions every Payables Agent telemetry event carries.
    /// </summary>
    internal procedure GetCustomDimensions() CustomDimensions: Dictionary of [Text, Text]
    begin
        CustomDimensions.Set('category', CategoryTok);
    end;

    /// <summary>
    /// Dimensions of an event about a task: the common ones plus the task and the setup it was handled with.
    /// </summary>
    internal procedure GetTaskDimensions(PATask: Codeunit "PA Task") CustomDimensions: Dictionary of [Text, Text]
    var
        TempPADetailedSetup: Record "PA Detailed Setup";
        PASetup: Codeunit "PA Setup";
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
    begin
        PASetup.GetSetup(TempPADetailedSetup);
        // 'Category' (capitalized) is kept for the task events that always used it.
        CustomDimensions.Set('Category', CategoryTok);
        CustomDimensions.Set('V2', Format(PAV1V2Flag.IsV2Active()));
        CustomDimensions.Set('SystemId', PATask.GetTelemetryId());
        CustomDimensions.Set('SourceType', Format(PATask.GetSourceType(), 0, 9));
        CustomDimensions.Set('EmailReviewPolicy', Format(TempPADetailedSetup."Email Review Policy", 0, 9));
    end;

    /// <summary>
    /// A task was handed to the agent.
    /// </summary>
    internal procedure LogTaskReceived(PATask: Codeunit "PA Task"; RequiresReview: Boolean)
    var
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions := GetTaskDimensions(PATask);
        CustomDimensions.Set('RequiresReview', Format(RequiresReview, 0, 9));
        Telemetry.LogMessage('0000PJA', 'Payables Agent Task Received', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    /// <summary>
    /// A task was not handed to the agent because its sender is rejected.
    /// </summary>
    internal procedure LogTaskSkippedSenderRejected(PATask: Codeunit "PA Task")
    var
        Telemetry: Codeunit Telemetry;
    begin
        Telemetry.LogMessage('0000QJ2', 'Payables Agent Task Skipped: sender rejected', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetTaskDimensions(PATask));
    end;

    /// <summary>
    /// A task was created in trial mode, so it is excluded from billing.
    /// </summary>
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
