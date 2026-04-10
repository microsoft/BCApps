// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using System.Azure.Identity;

codeunit 9003 "Team Member Action Manager"
{

    trigger OnRun()
    begin
    end;

    var
        TeamMemberErr: Label 'You are logged in as a Team Member role, so you cannot complete this task.';

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeSalesHeaderInsert(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        CheckTeamMemberPermissionOnSalesHeaderTable(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeSalesHeaderDelete(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        CheckTeamMemberPermissionOnSalesHeaderTable(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforeSalesDocPost(var Sender: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
        // Team member is not allowed to invoice a sales document.
        if IsCurrentUserAssignedTeamMemberPlan() and SalesHeader.Invoice then
            Error(TeamMemberErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePurchaseDocPost(var Sender: Codeunit "Purch.-Post"; var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
        // Team member is not allowed to invoice a purchase document.
        if IsCurrentUserAssignedTeamMemberPlan() and PurchaseHeader.Invoice then
            Error(TeamMemberErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforePurchaseHeaderInsert(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        CheckTeamMemberPermissionOnPurchaseHeaderTable(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforePurchaseHeaderDelete(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        CheckTeamMemberPermissionOnPurchaseHeaderTable(Rec);
    end;

    local procedure CheckTeamMemberPermissionOnSalesHeaderTable(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.IsTemporary() then
            exit;

        if IsCurrentUserAssignedTeamMemberPlan() and (SalesHeader."Document Type" <> SalesHeader."Document Type"::Quote) then
            Error(TeamMemberErr);
    end;

    local procedure CheckTeamMemberPermissionOnPurchaseHeaderTable(var PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader.IsTemporary() then
            exit;

        if IsCurrentUserAssignedTeamMemberPlan() and (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Quote) then
            Error(TeamMemberErr);
    end;

    local procedure IsCurrentUserAssignedTeamMemberPlan(): Boolean
    var
        AzureADPlan: Codeunit "Azure AD Plan";
        PlanIds: Codeunit "Plan Ids";
    begin
        exit(AzureADPlan.IsPlanAssignedToUser(PlanIds.GetTeamMemberPlanId()) or
            AzureADPlan.IsPlanAssignedToUser(PlanIds.GetTeamMemberISVPlanId()));
    end;
}

