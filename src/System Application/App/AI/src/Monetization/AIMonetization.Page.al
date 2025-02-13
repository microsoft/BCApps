namespace System.AI;
using System;

page 7757 "AI Monetization"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Details)
            {
                Caption = 'Details';
                field(Cost; Cost)
                {
                    ToolTip = 'Specifies the cost of using the capability';
                    Caption = 'Cost';
                }
                field(CapabilityName; CapabilityName)
                {
                    ToolTip = 'Specifies the name of the capability';
                    Caption = 'Capability Name';
                }

                group(NonMicrosoft)
                {
                    Caption = 'Non-Microsoft Capability';

                    field(NonMicrosoftTog; NonMicrosoft)
                    {
                        ToolTip = 'Specifies if the capability is from a non-Microsoft publisher';
                        Caption = 'Non-Microsoft';
                    }
                    field(PublisherName; PublisherName)
                    {
                        ToolTip = 'Specifies the name of the publisher';
                        Caption = 'Publisher Name';
                    }
                }
            }
            group(Status)
            {
                Caption = 'Status';
                Editable = false;

                field(CanConsume; CanConsume)
                {
                    ToolTip = 'Specifies if the capability can be consumed';
                    Caption = 'Can Consume';
                }
                field(HasBillingSetup; HasBillingSetup)
                {
                    ToolTip = 'Specifies if billing is setup for the capability';
                    Caption = 'Has Billing Setup';
                }
                field(QuotaUsed; QuotaUsed)
                {
                    ToolTip = 'Specifies the percentage of quota used';
                    Caption = 'Quota Used';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LogMicrosoftCap)
            {
                ApplicationArea = All;
                Caption = 'Log Usage';
                ToolTip = 'Log Usage';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    if NonMicrosoft then
                        LogNonMicrosoftUsage()
                    else
                        LogMicrosoftUsage();
                end;
            }
            action(UpdatePageVars)
            {
                ApplicationArea = All;
                Caption = 'Refresh data';
                ToolTip = 'Refresh data';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    UpdatePageVariables();
                end;
            }
        }
    }

    var
        CapabilityName: Text;
        PublisherName: Text;
        Cost: Integer;
        CanConsume: Boolean;
        HasBillingSetup: Boolean;
        QuotaUsed: Decimal;
        NonMicrosoft: Boolean;

    local procedure LogMicrosoftUsage()
    var
        ALCopilotCapability: DotNet ALCopilotCapability;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        CallerModuleInfo: ModuleInfo;
        LoggedLbl: Label 'Microsoft capability usage logged for %1, with cost %2', Locked = true;
    begin
        if CapabilityName.Trim() = '' then
            Error('Capability name is required.');

        NavApp.GetCurrentModuleInfo(CallerModuleInfo);
        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CapabilityName);
        ALCopilotFunctions.LogCopilotQuotaUsage(ALCopilotCapability, Cost);
        Message(StrSubstNo(LoggedLbl, CapabilityName, Format(Cost)));
        UpdatePageVariables();
    end;

    local procedure LogNonMicrosoftUsage()
    var
        ALCopilotCapability: DotNet ALCopilotCapability;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        CallerModuleInfo: ModuleInfo;
        LoggedLbl: Label 'Non-Microsoft (%1) capability usage logged for %2, with cost %3', Locked = true;
    begin
        if CapabilityName.Trim() = '' then
            Error('Capability name is required.');

        if PublisherName.Trim() = '' then
            Error('Publisher name is required.');

        NavApp.GetCurrentModuleInfo(CallerModuleInfo);
        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(PublisherName, CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CapabilityName);
        ALCopilotFunctions.LogCopilotQuotaUsage(ALCopilotCapability, Cost);
        Message(StrSubstNo(LoggedLbl, PublisherName, CapabilityName, Format(Cost)));
        UpdatePageVariables();
    end;

    local procedure UpdatePageVariables()
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        ALCopilotQuotaDetails: DotNet ALCopilotQuotaDetails;
    begin
        ALCopilotQuotaDetails := ALCopilotFunctions.GetCopilotQuotaDetails();
        CanConsume := ALCopilotQuotaDetails.CanConsume();
        HasBillingSetup := ALCopilotQuotaDetails.HasSetupBilling();
        QuotaUsed := ALCopilotQuotaDetails.QuotaUsedPercentage();
        CurrPage.Update();
    end;
}