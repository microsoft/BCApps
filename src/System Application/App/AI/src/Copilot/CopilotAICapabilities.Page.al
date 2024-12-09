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
    Caption = 'Copilot & agent capabilities';
    DataCaptionExpression = '';
    AboutTitle = 'About Copilot';
    AboutText = 'Copilot is the AI-powered assistant that helps people across your organization unlock their creativity and automate tedious tasks.';
    AdditionalSearchTerms = 'OpenAI,AI,Copilot,Co-pilot,Artificial Intelligence,GPT,GTP,Dynamics 365 Copilot,ChatGPT,Copilot settings,Copilot setup,enable Copilot,Copilot admin,Copilot and,agents,agentic capabilities,autonomous agents';
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(AOAIServicesInRegionArea)
            {
                ShowCaption = false;
                Visible = WithinAOAIServicesInRegionArea;
                InstructionalText = 'Copilot and agents use the Azure OpenAI Service. Your environment connects to this service in your own region.';

                field(DataSecurityAndPrivacy; FAQForDataSecurityAndPrivacyLbl)
                {
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(FAQForDataSecurityAndPrivacyDocLinkLbl);
                    end;
                }
                field(GovernData; CopilotGovernDataLbl)
                {
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(CopilotGovernDataDocLinkLbl);
                    end;
                }
                field(DataProcessByAOAI; DataProcessByAOAILbl)
                {
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(DataProcessByAOAIDocLinkLbl);
                    end;
                }
            }

            group(EUDBArea)
            {
                ShowCaption = false;
                Visible = WithinEUDBArea;

                group(AllowedDataMovementOffInfo)
                {
                    ShowCaption = false;
                    Visible = WithinEUDBArea and (not AllowDataMovement);
                    InstructionalText = 'Copilot and agents use the Azure OpenAI Service available within the EU Data Boundary. To activate these capabilities, you must allow data movement within this boundary.';
                }
                group(AllowedDataMovementOnInfo)
                {
                    ShowCaption = false;
                    Visible = WithinEUDBArea and AllowDataMovement;
                    InstructionalText = 'Copilot and agents use the Azure OpenAI Service available within the EU Data Boundary. To keep using these capabilities, you must allow data movement within this boundary.';
                }
                field(EUDBAreaDataSecurityAndPrivacy; FAQForDataSecurityAndPrivacyLbl)
                {
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(FAQForDataSecurityAndPrivacyDocLinkLbl);
                    end;
                }
                group(EUDBAreaDataMovementGroup)
                {
                    ShowCaption = false;
                    label(EUDBAreaCaption)
                    {
                        ApplicationArea = All;
                        Caption = 'By allowing data movement, you agree to data being processed by the Azure OpenAI Service within the EU Data Boundary.';
                    }
                    field(EUDBAreaDataMovement; AllowDataMovement)
                    {
                        ApplicationArea = All;
                        Caption = 'Allow data movement';
                        ToolTip = 'Specifies whether data movement across regions is allowed. This is required to enable Copilot in your environment.';
                        Editable = WithinEUDBArea and AllowDataMovementEditable;

                        trigger OnValidate()
                        begin
                            UpdateAllowDataMovement();
                        end;
                    }
                    field(EUDBAreaAOAIServiceLocated; AOAIServiceLocatedLbl)
                    {
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(AOAIServiceLocatedDocLinkLbl);
                        end;
                    }
                    field(EUDBAreaDataProcess; DataProcessByAOAILbl)
                    {
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(DataProcessByAOAIDocLinkLbl);
                        end;
                    }
                }
            }

            group(AOAIOutOfRegionArea)
            {
                ShowCaption = false;
                Visible = WithinAOAIOutOfRegionArea;
                group(AllowedDataMovementOffInfo2)
                {
                    ShowCaption = false;
                    Visible = WithinAOAIOutOfRegionArea and (not AllowDataMovement);
                    InstructionalText = 'Copilot and agents use the Azure OpenAI Service, which isn''t available in your region. To activate these capabilities, you must allow data movement.';
                }
                group(AllowedDataMovementOnInfo2)
                {
                    ShowCaption = false;
                    Visible = WithinAOAIOutOfRegionArea and AllowDataMovement;
                    InstructionalText = 'Copilot and agents use the Azure OpenAI Service, which isn''t available in your region. To keep using these capabilities, you must allow data movement.';
                }
                field(AOAIOutOfRegionAreaDataSecurityAndPrivacy; FAQForDataSecurityAndPrivacyLbl)
                {
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(FAQForDataSecurityAndPrivacyDocLinkLbl);
                    end;
                }
                group(AOAIOutOfRegionAreaDataMovementGroup)
                {
                    ShowCaption = false;
                    label(AOAIOutOfRegionAreaCaption)
                    {
                        ApplicationArea = All;
                        Caption = 'By allowing data movement, you agree to data being processed by the Azure OpenAI Service outside of your environment''s geographic region or compliance boundary.';
                    }
                    field(AOAIOutOfRegionAreaDataMovement; AllowDataMovement)
                    {
                        ApplicationArea = All;
                        Caption = 'Allow data movement';
                        ToolTip = 'Specifies whether data movement across regions is allowed. This is required to enable Copilot in your environment.';
                        Editable = WithinAOAIOutOfRegionArea and AllowDataMovementEditable;

                        trigger OnValidate()
                        begin
                            UpdateAllowDataMovement();
                        end;
                    }
                    field(AOAIOutOfRegionAreaAOAIServiceLocated; AOAIServiceLocatedLbl)
                    {
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(AOAIServiceLocatedDocLinkLbl);
                        end;
                    }
                    field(AOAIOutOfRegionAreaDataProcess; DataProcessByAOAILbl)
                    {
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(DataProcessByAOAIDocLinkLbl);
                        end;
                    }
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
                    Hyperlink(CheckServiceHealthDocLinkLbl);
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
        WithinGeo: Boolean;
        WithinEUDB: Boolean;
    begin
        OnRegisterCopilotCapability();

        CopilotCapabilityImpl.CheckGeoAndEUDB(WithinGeo, WithinEUDB);

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

        if (WithinGeo and not WithinEUDB) and (not AllowDataMovement) then
            CopilotCapabilityImpl.ShowPrivacyNoticeDisagreedNotification();

        CopilotCapabilityImpl.UpdateGuidedExperience(AllowDataMovement);

        HasEarlyPreview := HasEarlyPreviewCapabilities();

        WithinEUDBArea := WithinEUDB;
        WithinAOAIServicesInRegionArea := WithinGeo and (not WithinEUDB);
        WithinAOAIOutOfRegionArea := (not WithinGeo) and (not WithinEUDB);
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
        WithinEUDBArea: Boolean;
        WithinAOAIServicesInRegionArea: Boolean;
        WithinAOAIOutOfRegionArea: Boolean;
        AllowDataMovement: Boolean;
        AllowDataMovementEditable: Boolean;
        HasEarlyPreview: Boolean;
        CopilotGovernDataLbl: Label 'How do I govern my Copilot data?';
        FAQForDataSecurityAndPrivacyLbl: Label 'FAQ for data security and privacy';
        DataProcessByAOAILbl: Label 'What data is processed by Azure OpenAI Service?';
        AOAIServiceLocatedLbl: Label 'In which region will my data be processed?';
        CopilotGovernDataDocLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2249575', Locked = true;
        FAQForDataSecurityAndPrivacyDocLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2298505', Locked = true;
        DataProcessByAOAIDocLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2298232', Locked = true;
        AOAIServiceLocatedDocLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2250267', Locked = true;
        CheckServiceHealthDocLinkLbl: Label 'https://aka.ms/azurestatus', Locked = true;
}