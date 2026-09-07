// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.AI;
using System.Environment;
using System.Privacy;

codeunit 6951 "Exp. Privacy Notice Reg."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Expense Agent Setup" = rm;

    var
        AzureOpenAITok: Label 'Azure OpenAI', Locked = true;
#if not CLEAN29
        AnthropicProductNameTok: Label 'Anthropic', Locked = true;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", OnRegisterPrivacyNotices, '', false, false)]
    local procedure CreatePrivacyNoticeRegistrations(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := AzureOpenAITok;
        TempPrivacyNotice."Integration Service Name" := AzureOpenAITok;
        if not TempPrivacyNotice.Insert() then;

        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := GetExpenseAgentPrivacyNoticeId();
        TempPrivacyNotice."Integration Service Name" := GetExpenseAgentPrivacyNoticeId();
        if not TempPrivacyNotice.Insert() then;
    end;

    procedure GetExpenseAgentPrivacyNoticeId(): Text[50]
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        exit(CopyStr(ExpenseAgentSetup.GetFeatureName(), 1, 50));
    end;

#if not CLEAN29
    internal procedure GetAnthropicName(): Text[50]
    begin
        exit(AnthropicProductNameTok);
    end;
#endif

    procedure IsPrivacyNoticeApproved(): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        if PrivacyNotice.GetPrivacyNoticeApprovalState(AzureOpenAITok, false) <> "Privacy Notice Approval State"::Agreed then
            exit(false);

        if PrivacyNotice.GetPrivacyNoticeApprovalState(GetExpenseAgentPrivacyNoticeId(), false) <> "Privacy Notice Approval State"::Agreed then
            exit(false);

        exit(true);
    end;

    procedure ConfirmPrivacyNoticeApproval(): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        if not PrivacyNotice.ConfirmPrivacyNoticeApproval(AzureOpenAITok, false) then
            exit(false);

        if not PrivacyNotice.ConfirmPrivacyNoticeApproval(GetExpenseAgentPrivacyNoticeId(), false) then
            exit(false);

        exit(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Privacy Notice Approval", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyPrivacyNoticeApproval(var Rec: Record "Privacy Notice Approval")
    begin
        if not IsExpenseAgentPrivacyNotice(Rec.ID) then
            exit;
        if not Rec.Approved then
            DisableExpenseAgentInAllCompanies();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Privacy Notice Approval", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeletePrivacyNoticeApproval(var Rec: Record "Privacy Notice Approval")
    begin
        if not IsExpenseAgentPrivacyNotice(Rec.ID) then
            exit;
        if Rec.Approved then
            DisableExpenseAgentInAllCompanies();
    end;

    local procedure IsExpenseAgentPrivacyNotice(PrivacyNoticeId: Code[50]): Boolean
    begin
        if LowerCase(PrivacyNoticeId) = LowerCase(AzureOpenAITok) then
            exit(true);
        if LowerCase(PrivacyNoticeId) = LowerCase(GetExpenseAgentPrivacyNoticeId()) then
            exit(true);
        exit(false);
    end;

    local procedure DisableExpenseAgentInAllCompanies()
    var
        CompanyRec: Record Company;
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        CompanyRec.SetLoadFields(Name);
        if CompanyRec.FindSet() then
            repeat
                ExpenseAgentSetup.ChangeCompany(CompanyRec.Name);
                if ExpenseAgentSetup.Get() then
                    if ExpenseAgentSetup."Enable Agent" then begin
                        ExpenseAgentSetup.Validate("Enable Agent", false);
                        ExpenseAgentSetup.Modify();
                    end;
            until CompanyRec.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copilot Capability", OnGetRequiredPrivacyNotices, '', false, false)]
    local procedure OnGetRequiredPrivacyNotices(CopilotCapability: Enum "Copilot Capability"; AppId: Guid; var RequiredPrivacyNotices: List of [Code[50]])
    var
        CurrentModule: ModuleInfo;
    begin
        if CopilotCapability <> Enum::"Copilot Capability"::"Expense Agent" then
            exit;

        NavApp.GetCurrentModuleInfo(CurrentModule);
        if CurrentModule.Id <> AppId then
            exit;

        RequiredPrivacyNotices.Add(AzureOpenAITok);
        RequiredPrivacyNotices.Add(GetExpenseAgentPrivacyNoticeId());
    end;
}
