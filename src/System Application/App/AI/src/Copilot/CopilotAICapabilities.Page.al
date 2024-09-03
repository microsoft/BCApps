// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Environment;
using System.Privacy;

/// <summary>
/// This page is used to set the Copilot settings in the Environment.
/// </summary>
page 7775 "Copilot AI Capabilities"
{
    PageType = Document;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Copilot & AI capabilities';
    DataCaptionExpression = '';
    AboutTitle = 'About Copilot';
    AboutText = 'Copilot is the AI-powered assistant that helps people across your organization unlock their creativity and automate tedious tasks.';
    AdditionalSearchTerms = 'OpenAI,AI,Copilot,Co-pilot,Artificial Intelligence,GPT,GTP,Dynamics 365 Copilot,ChatGPT,Copilot settings,Copilot setup,enable Copilot,Copilot admin,Copilot and';
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(AllowedDataMovementOffInfo)
            {
                ShowCaption = false;
                Visible = ((not WithinGeo) or WithinEuropeGeo) and (not AllowDataMovement);
                InstructionalText = 'Copilot uses the Azure OpenAI Service, which isn’t available in your region. To activate Copilot capabilities, you must allow data movement.';
            }

            group(AllowedDataMovementOnInfo)
            {
                ShowCaption = false;
                Visible = ((not WithinGeo) or WithinEuropeGeo) and AllowDataMovement;
                InstructionalText = 'Copilot uses the Azure OpenAI Service, which isn’t available in your region. To keep using Copilot capabilities, you must allow data movement.';
            }

            group(AlwaysConnected)
            {
                ShowCaption = false;
                InstructionalText = 'Copilot and other generative AI capabilities use Azure OpenAI Service. Your environment connects to Azure OpenAI Service in your region.';
                Visible = WithinGeo and (not WithinEuropeGeo);

                field(GovernData; CopilotGovernDataLbl)
                {
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink('https://go.microsoft.com/fwlink/?linkid=2249575');
                    end;
                }
            }

            group(NotAlwaysConnected)
            {
                ShowCaption = false;
                InstructionalText = 'By allowing data movement, you agree to data being stored and processed by the Azure OpenAI Service outside of your environment''s geographic region or compliance boundary.';
                Visible = ((not WithinGeo) or WithinEuropeGeo) and AllowDataMovement;

                field(DataMovement; AllowDataMovement)
                {
                    ApplicationArea = All;
                    Caption = 'Allow data movement';
                    ToolTip = 'Specifies whether data movement across regions is allowed. This is required to enable Copilot in your environment.';
                    Editable = AllowDataMovementEditable;

                    trigger OnValidate()
                    begin
                        UpdateAllowDataMovement();
                    end;
                }

                field(AOAIServiceLocated; AOAIServiceLocatedLbl)
                {
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink('https://go.microsoft.com/fwlink/?linkid=2250267');
                    end;
                }
            }

            group(NotAlwaysConnected2)
            {
                ShowCaption = false;
                InstructionalText = 'Generative AI capabilities are deactivated because Azure OpenAI Service is not available in your region. By allowing data movement, you agree to data being stored and processed by the Azure OpenAI Service outside of your environment''s geographic region or compliance boundary.';
                Visible = ((not WithinGeo) or WithinEuropeGeo) and (not AllowDataMovement);

                field(DataMovement2; AllowDataMovement)
                {
                    ApplicationArea = All;
                    Caption = 'Allow data movement';
                    ToolTip = 'Specifies whether data movement across regions is allowed. This is required to enable Copilot in your environment.';
                    Editable = AllowDataMovementEditable;

                    trigger OnValidate()
                    begin
                        UpdateAllowDataMovement();
                    end;
                }

                field(AOAIServiceLocated2; AOAIServiceLocatedLbl)
                {
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink('https://go.microsoft.com/fwlink/?linkid=2250267');
                    end;
                }
            }

            part(PreviewCapabilities; "Copilot Capabilities Preview")
            {
                Caption = 'Production-ready previews';
                ApplicationArea = All;
                Editable = false;
            }
            part(GenerallyAvailableCapabilities; "Copilot Capabilities GA")
            {
                Caption = 'Generally available';
                ApplicationArea = All;
                Editable = false;
            }
            part(EarlyPreviewCapabilities; "Copilot Cap. Early Preview")
            {
                Caption = 'Early previews (not for production)';
                ApplicationArea = All;
                Editable = false;
                Visible = HasEarlyPreview;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Check service health")
            {
                ApplicationArea = All;
                Image = ValidateEmailLoggingSetup;
                ToolTip = 'Check the health of the Azure OpenAI service for your region.';
                Visible = false;

                trigger OnAction()
                begin
                    Hyperlink('https://aka.ms/azurestatus');
                end;
            }
        }

        area(Promoted)
        {
            actionref(PromotedServiceHealth; "Check service health")
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        OnRegisterCopilotCapability();

        CopilotCapabilityImpl.CheckGeo(WithinGeo, WithinEuropeGeo);

        case PrivacyNotice.GetPrivacyNoticeApprovalState(CopilotCapabilityImpl.GetAzureOpenAICategory(), false) of
            Enum::"Privacy Notice Approval State"::Agreed:
                AllowDataMovement := true;
            Enum::"Privacy Notice Approval State"::Disagreed:
                AllowDataMovement := false;
            else
                AllowDataMovement := true;
        end;

        AllowDataMovementEditable := CopilotCapabilityImpl.IsAdmin();

        CurrPage.GenerallyAvailableCapabilities.Page.SetDataMovement(AllowDataMovement);
        CurrPage.PreviewCapabilities.Page.SetDataMovement(AllowDataMovement);
        CurrPage.EarlyPreviewCapabilities.Page.SetDataMovement(AllowDataMovement);

        if not EnvironmentInformation.IsSaaSInfrastructure() then
            CopilotCapabilityImpl.ShowCapabilitiesNotAvailableOnPremNotification();

        if (WithinGeo and not WithinEuropeGeo) and (not AllowDataMovement) then
            CopilotCapabilityImpl.ShowPrivacyNoticeDisagreedNotification();

        CopilotCapabilityImpl.UpdateGuidedExperience(AllowDataMovement);

        HasEarlyPreview := HasEarlyPreviewCapabilities();
    end;

    local procedure HasEarlyPreviewCapabilities(): Boolean
    var
        CopilotSettings: Record "Copilot Settings";
    begin
        CopilotSettings.SetRange(Availability, Enum::"Copilot Availability"::"Early Preview");
        exit(not CopilotSettings.IsEmpty());
    end;

    local procedure UpdateAllowDataMovement()
    begin
        if AllowDataMovement then
            PrivacyNotice.SetApprovalState(CopilotCapabilityImpl.GetAzureOpenAICategory(), Enum::"Privacy Notice Approval State"::Agreed)
        else
            PrivacyNotice.SetApprovalState(CopilotCapabilityImpl.GetAzureOpenAICategory(), Enum::"Privacy Notice Approval State"::Disagreed);

        CurrPage.GenerallyAvailableCapabilities.Page.SetDataMovement(AllowDataMovement);
        CurrPage.PreviewCapabilities.Page.SetDataMovement(AllowDataMovement);
        CopilotCapabilityImpl.UpdateGuidedExperience(AllowDataMovement);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterCopilotCapability()
    begin

    end;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        PrivacyNotice: Codeunit "Privacy Notice";
        WithinGeo: Boolean;
        WithinEuropeGeo: Boolean;
        AllowDataMovement: Boolean;
        AllowDataMovementEditable: Boolean;
        HasEarlyPreview: Boolean;
        CopilotGovernDataLbl: Label 'How do I govern my Copilot data?';
        AOAIServiceLocatedLbl: Label 'In which region will my data be stored and processed?';
}