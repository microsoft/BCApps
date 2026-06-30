// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Picture;

using System.Environment;
using System.Privacy;
using System.Utilities;

page 7497 "Item From Picture Wizard"
{
    PageType = NavigatePage;
    Caption = 'Set up item from picture analysis';

    layout
    {
        area(content)
        {
            group(TopBannerGroup)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible;

                field(TopBanner; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(FirstPage)
            {
                Caption = '';
                Visible = FirstStepVisible;

                group("Welcome to the Wizard")
                {
                    Caption = 'Welcome';

                    label(TourGroup)
                    {
                        ApplicationArea = All;
                        Caption = 'New from Picture uses the Computer Vision API from Azure Cognitive Services to match the images you upload in the New from Picture page with item categories. This makes it easy and fast for you to create items when you have their pictures available.';
                    }
                    field(CognitiveServicesLink; CognitiveServicesLinkTxt)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(CognitiveServicesLinkLinkTxt);
                        end;
                    }
                    label(ConfirmTermsLabel)
                    {
                        ApplicationArea = All;
                        Caption = 'The consent in the following pages only applies to the New from Picture feature.';
                    }
                }
            }
            group(SecondPage)
            {
                Caption = '';
                Visible = SecondStepVisible;

                group(PrivacyNotice)
                {
                    Caption = 'Privacy Notice and Terms of Use';

                    label(PrivacyNoticeLabel)
                    {
                        ApplicationArea = All;
                        CaptionClass = '3,' + PrivacyLabel;
                    }
                    field(PrivacyNoticeLink; PrivacyStatementTxt)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(PrivacyStatementLinkTxt);
                        end;
                    }
                    label(TermsPart)
                    {
                        ApplicationArea = All;
                        Caption = 'Your use of this feature may be subject to the additional licensing terms in the Azure Cognitive Services section of the Online Services Terms.';
                    }
                    field(TermsPartLink; OnlineServicesTermLinkTxt)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(OnlineServicesTermLinkLinkTxt);
                        end;
                    }
                }
                field(EnableFeature; IsFeatureEnabled)
                {
                    ApplicationArea = All;
                    Editable = true;
                    Caption = 'I understand and accept these terms';
                    ToolTip = 'Specifies if the feature is consented to and enabled.';

                    trigger OnValidate()
                    begin
                        ShowSecondStep();
                    end;
                }
            }

            group(FinalPage)
            {
                Caption = '';
                Visible = FinalStepVisible;

                group("That's it!")
                {
                    Caption = 'That''s it!';

                    label(ChooseFinish1)
                    {
                        ApplicationArea = All;
                        Caption = 'Next time you upload an item image in the New from Picture action, we will analyze it for you. You can opt out at any time from the Image Analysis Setup page.';
                    }
                    label(ChooseFinish2)
                    {
                        ApplicationArea = All;
                        Caption = 'Choose ''Finish'' to enable image analysis on New from Picture.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Visible = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinishAndEnable)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = FinalStepVisible;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    ItemFromPicture: Codeunit "Item From Picture";
                begin
                    Session.LogMessage('0000JYV', WizardAcceptedTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ItemFromPicture.GetTelemetryCategory());
                    ItemFromPicture.EnableImageAnalysisScenario();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        LocalPrivacyNotice: Codeunit "Privacy Notice";
    begin
        LoadTopBanners();
        PrivacyLabel := StrSubstNo(LocalPrivacyNotice.GetDefaultPrivacyAgreementTxt(), AcsNameLbl, ProductName.Full());
    end;

    trigger OnOpenPage()
    begin
        Step := Step::Start;
        EnableControls();
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        Step: Option Start,Second,Finish;
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        SecondStepVisible: Boolean;
        FinalStepVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        PrivacyLabel: Text;
        PrivacyStatementTxt: Label 'Privacy and cookies';
        AcsNameLbl: Label 'Azure Cognitive Services', Comment = 'The name of the product Azure Cognitive Services';
        PrivacyStatementLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=831305', Locked = true;
        CognitiveServicesLinkTxt: Label 'Learn more about Azure Cognitive Services';
        OnlineServicesTermLinkLinkTxt: Label 'https://www.microsoft.com/en-us/licensing/product-licensing/products.aspx', Locked = true;
        OnlineServicesTermLinkTxt: Label 'Online Services Terms (OST)';
        CognitiveServicesLinkLinkTxt: Label 'http://go.microsoft.com/fwlink/?LinkID=829046', Locked = true;
        WizardAcceptedTelemetryMsg: Label 'Wizard was successfully completed and approved.', Locked = true;
        IsFeatureEnabled: Boolean;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();

            Step::Second:
                ShowSecondStep();

            Step::Finish:
                ShowFinalStep();
        end;
    end;

    local procedure NextStep(Backwards: Boolean)
    begin

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;
        SecondStepVisible := false;
        BackActionEnabled := false;
    end;

    local procedure ShowSecondStep()
    begin
        FirstStepVisible := false;
        SecondStepVisible := true;
        BackActionEnabled := true;
        NextActionEnabled := IsFeatureEnabled;
    end;

    local procedure ShowFinalStep()
    begin
        FinalStepVisible := true;
        BackActionEnabled := true;
        NextActionEnabled := false;
    end;

    local procedure ResetControls()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        SecondStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('ImageAnalysis-Setup-NoText.png', Format(CurrentClientType())) then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue();
    end;
}
