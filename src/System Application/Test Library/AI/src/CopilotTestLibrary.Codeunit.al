// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.AI;

using System.AI;

codeunit 132932 "Copilot Test Library"
{
    EventSubscriberInstance = Manual;

    Permissions = tabledata "Copilot Settings" = rm;

    var
        CopilotCapability: Codeunit "Copilot Capability";
        NewMonetization: Boolean;
        QuotaIsSet: Boolean;
        MockQuota: Record "AI Consumption Quota" temporary;
        LastPrincipalId: Guid;

    procedure SetNewMonetizationEnabled(Enabled: Boolean)
    begin
        NewMonetization := Enabled;
    end;

    procedure SetAIConsumptionQuota(CanConsume: Boolean; BillingEnabled: Boolean; CreditLimit: Decimal; ConsumedCredits: Decimal)
    begin
        MockQuota.Init();
        MockQuota."Can Consume" := CanConsume;
        MockQuota."Billing Enabled" := BillingEnabled;
        MockQuota."AI Credit Limit" := CreditLimit;
        MockQuota."Consumed AI Credits" := ConsumedCredits;
        QuotaIsSet := true;
    end;

    procedure GetLastQuotaPrincipalId(): Guid
    begin
        exit(LastPrincipalId);
    end;

    procedure GetQuotaResults(var Results: Dictionary of [Text, Text])
    var
        QuotaImpl: Codeunit "Copilot Quota Impl.";
    begin
        QuotaImpl.GetQuotaResults(Results);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copilot Quota", OnIsNewMonetizationEnabled, '', false, false)]
    local procedure OnIsNewMonetizationEnabled(var Enabled: Boolean)
    begin
        if NewMonetization then
            Enabled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copilot Quota Impl.", OnBeforeGetAIConsumptionQuota, '', false, false)]
    local procedure OnBeforeGetAIConsumptionQuota(PrincipalId: Guid; var Quota: Record "AI Consumption Quota" temporary; var Handled: Boolean)
    begin
        if not QuotaIsSet then
            exit;
        LastPrincipalId := PrincipalId;
        Quota := MockQuota;
        Handled := true;
    end;

    procedure RegisterCopilotCapability(Capability: Enum "Copilot Capability")
    begin
        CopilotCapability.RegisterCapability(Capability, '');
    end;

    procedure RegisterCopilotCapability(Capability: Enum "Copilot Capability"; var CurrentModule: Guid)
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        CurrentModule := ModuleInfo.Id();

        CopilotCapability.RegisterCapability(Capability, '');
    end;

    procedure RegisterCopilotCapabilityWithAppId(Capability: Enum "Copilot Capability"; AppId: Guid)
    var
        CopilotSettings: Record "Copilot Settings";
        ModuleInfo: ModuleInfo;
    begin
        if CopilotSettings.Get(Capability, AppId) then
            if CopilotSettings.Status = CopilotSettings.Status::Active then
                exit
            else begin
                CopilotSettings.Status := CopilotSettings.Status::Active;
                CopilotSettings.Modify();
                exit;
            end;

        RegisterCopilotCapability(Capability);

        NavApp.GetCurrentModuleInfo(ModuleInfo);
        if CopilotSettings.Get(Capability, ModuleInfo.Id) then begin
            CopilotSettings.Rename(Capability, AppId);
            Commit();
        end;
    end;

    procedure UnregisterCopilotCapability(Capability: Enum "Copilot Capability")
    begin
        CopilotCapability.UnregisterCapability(Capability);
    end;

    procedure SetCopilotStatus(Capability: Enum "Copilot Capability"; PackageId: Guid; Status: Enum "Copilot Status")
    var
        CopilotSettings: Record "Copilot Settings";
    begin
        CopilotSettings.Get(Capability, PackageId);
        CopilotSettings.Status := Status;
        CopilotSettings.Modify();
    end;

}