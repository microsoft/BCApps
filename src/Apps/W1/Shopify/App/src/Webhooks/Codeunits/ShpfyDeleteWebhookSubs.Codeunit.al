// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30458 "Shpfy Delete Webhook Subs."
{
    Access = Internal;
    TableNo = "Shpfy Shop";

    var
        SubscriptionId: Text;

    trigger OnRun()
    var
        WebhooksAPI: Codeunit "Shpfy Webhooks API";
    begin
        WebhooksAPI.DeleteWebhookSubscription(Rec, SubscriptionId);
    end;

    internal procedure SetSubscriptionId(NewSubscriptionId: Text)
    begin
        SubscriptionId := NewSubscriptionId;
    end;
}
