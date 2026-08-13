// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits;

using System.Automation;

/// <summary>
/// API codeunit exposing workflow approval operations as non-data-bound (unbound) actions.
/// Wraps codeunit "Workflow Webhook Subscription" (1544).
/// </summary>
/// <remarks>TODO(AB#641822): decorate with the API codeunit subtype (microsoft/codeunits) when the platform ships it.</remarks>
codeunit 6008 "Approvals API"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>Approves the specified workflow step instance.</summary>
    /// <param name="WorkflowStepInstanceId">The workflow step instance to approve.</param>
    procedure Approve(WorkflowStepInstanceId: Guid)
    var
        WorkflowWebhookSubscription: Codeunit "Workflow Webhook Subscription";
    begin
        WorkflowWebhookSubscription.Approve(WorkflowStepInstanceId);
    end;

    /// <summary>Rejects the specified workflow step instance.</summary>
    /// <param name="WorkflowStepInstanceId">The workflow step instance to reject.</param>
    procedure Reject(WorkflowStepInstanceId: Guid)
    var
        WorkflowWebhookSubscription: Codeunit "Workflow Webhook Subscription";
    begin
        WorkflowWebhookSubscription.Reject(WorkflowStepInstanceId);
    end;

    /// <summary>Cancels the specified workflow step instance.</summary>
    /// <param name="WorkflowStepInstanceId">The workflow step instance to cancel.</param>
    procedure Cancel(WorkflowStepInstanceId: Guid)
    var
        WorkflowWebhookSubscription: Codeunit "Workflow Webhook Subscription";
    begin
        WorkflowWebhookSubscription.Cancel(WorkflowStepInstanceId);
    end;

    /// <summary>Returns the email address of the direct approver for the given requestor.</summary>
    /// <param name="RequestorEmailAddress">The requestor's email address.</param>
    /// <returns>The direct approver's email address.</returns>
    procedure GetDirectApprover(RequestorEmailAddress: Text): Text
    var
        WorkflowWebhookSubscription: Codeunit "Workflow Webhook Subscription";
    begin
        exit(WorkflowWebhookSubscription.GetDirectApprover(RequestorEmailAddress));
    end;
}
