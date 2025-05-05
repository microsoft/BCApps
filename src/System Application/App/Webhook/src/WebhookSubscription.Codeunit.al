// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

/// <summary>
/// Provides methods to handle webhook subscriptions to external resources
/// </summary>
codeunit 9331 "Webhook Subscription"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        WebhookSubscriptionImpl: Codeunit "Webhook Subscription Impl.";
        CallerModuleInfo: ModuleInfo;

    /// <summary>
    /// Initializes the webhook subscription with the given subscription ID and endpoint.
    /// </summary>
    /// <param name="SubscriptionId">The subscription ID to be used.</param>
    /// <param name="Endpoint">The endpoint to be used.</param>
    /// <returns>True if the subscription is initialized successfully, false otherwise.</returns>
    procedure Initialize(SubscriptionId: Text[150]; Endpoint: Text[250]): Boolean
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        WebhookSubscriptionImpl.AssertInternalCall(CallerModuleInfo);
        exit(WebhookSubscriptionImpl.Initialize(SubscriptionId, Endpoint));
    end;

    /// <summary>
    /// Gets the company name associated with the webhook subscription.
    /// </summary>
    /// <returns>The company name.</returns>
    procedure CompanyName(): Text[30]
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        WebhookSubscriptionImpl.AssertInternalCall(CallerModuleInfo);
        exit(WebhookSubscriptionImpl.CompanyName());
    end;

    /// <summary>
    /// Gets the user ID of the user which runs notifications associated with the webhook subscription.
    /// </summary>
    /// <returns>The user ID.</returns>
    procedure NotificationUserId(): Guid
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        WebhookSubscriptionImpl.AssertInternalCall(CallerModuleInfo);
        exit(WebhookSubscriptionImpl.NotificationUserId());
    end;

    /// <summary>
    /// Updates the company name associated with the webhook subscription.
    /// </summary> 
    /// <param name="NewCompanyName">The new company name to be set.</param>
    procedure UpdateCompanyName(NewCompanyName: Text[30])
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        WebhookSubscriptionImpl.AssertInternalCall(CallerModuleInfo);
        WebhookSubscriptionImpl.UpdateCompanyName(NewCompanyName);
    end;

    /// <summary>
    /// Creates a new webhook subscription with the given parameters and initializes it.
    /// </summary>
    /// <param name="SubscriptionId">The subscription ID to be used.</param>
    /// <param name="Endpoint">The endpoint to be used.</param>
    /// <param name="CreatedBy">The user who created the subscription.</param>
    /// <param name="Company">The company name associated with the subscription.</param>
    /// <param name="UserId">The user ID of the user which runs notifications.</param>
    procedure Create(SubscriptionId: Text[150]; Endpoint: Text[250]; CreatedBy: Code[50]; Company: Text[30]; UserId: Guid)
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        WebhookSubscriptionImpl.AssertInternalCall(CallerModuleInfo);
        WebhookSubscriptionImpl.Create(SubscriptionId, Endpoint, CreatedBy, Company, UserId);
    end;

    /// <summary>
    /// Deletes the webhook subscription.
    /// </summary>
    procedure Delete()
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        WebhookSubscriptionImpl.AssertInternalCall(CallerModuleInfo);
        WebhookSubscriptionImpl.Delete();
    end;

    /// <summary>
    /// Updates all webhook subscriptions with the given old endpoint to the new endpoint.
    /// </summary>
    /// <param name="OldEndpoint">The old endpoint to be replaced.</param>
    /// <param name="NewEndpoint">The new endpoint to be set.</param>
    procedure UpdateAllEndpoints(OldEndpoint: Text; NewEndpoint: Text)
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        WebhookSubscriptionImpl.AssertInternalCall(CallerModuleInfo);
        WebhookSubscriptionImpl.UpdateAllEndpoints(OldEndpoint, NewEndpoint);
    end;
}