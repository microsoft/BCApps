// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

codeunit 5435 "Automation - API Management"
{
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SaaS Log In Management", 'OnSuppressApprovalForTrial', '', false, false)]
    local procedure OnSuppressApprovalForTrial(var GetSuppressApprovalForTrial: Boolean)
    begin
        GetSuppressApprovalForTrial := true;
    end;
}

