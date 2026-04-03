// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using System.Environment;
using System.Utilities;
page 6414 "ForNAV Peppol Setup Wizard"
{
    PageType = NavigatePage;
    SourceTable = "ForNAV Peppol Setup";
    SourceTableTemporary = true;
    Caption = 'ForNAV Peppol Setup Wizard';
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(TopBanner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinalStepVisible;
                field(MediaRepositoryStandardImage; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(TopBannerFinal)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and FinalStepVisible;
                field(MediaRepositoryDoneImage; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Caption = 'Setup the ForNAV Peppol connector.';
                Visible = Step1Visible;
                InstructionalText = 'Set up the ForNAV Peppol connection.';
                group(welcome)
                {
                    ShowCaption = false;
                    InstructionalText = 'This wizard will help you to connect to the ForNAV Peppol network.';
                }
            }
            group(Step2)
            {
                Visible = Step2Visible;
                Caption = 'Grant Access';
                InstructionalText = 'Step 1 - Grant Access.';
                group(Go1)
                {
                    ShowCaption = false;
                    InstructionalText = 'In order to publish you need to give concent to allow for Incoming Pepol documents';
                }
                group(AdminNote)
                {
                    ShowCaption = false;
                    InstructionalText = 'NOTE: You will be asked to log in as an ADMIN user on AZURE. It is not enough to be admin in Business Central.';
                }
            }
            group(Step3)
            {
                Visible = Step3Visible;
                Caption = 'Oauth Setup';
                InstructionalText = 'Step 2 - Oauth Setup.';
                group(Go2)
                {
                    ShowCaption = false;
                    InstructionalText = 'We need some additional information so we can connect you to the ForNAV Peppol network.';
                }
                field(CompanyName; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Identification Code"; Rec."Identification Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Identification Value"; Rec."Identification Value")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(ContactPerson; ContactPerson)
                {
                    ApplicationArea = All;
                    Caption = 'Contact Person';
                    ToolTip = 'Specifies the contact person of the company.';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Contact Person", ContactPerson);
                    end;
                }
                field(EMail; EMail)
                {
                    ApplicationArea = All;
                    Caption = 'E-Mail';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the email of the contact person.';
                    trigger OnValidate()
                    begin
                        Rec.Validate("E-Mail", EMail);
                    end;
                }
                field(Endpoint; Rec.Endpoint)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Peppol Endpoint. You can get this from your ForNAV partner.';
                }
                group(AutoOauthSetup)
                {
                    ShowCaption = false;
                    InstructionalText = 'We will now add the Oauth keys so you can connect to the ForNAV Peppol network. This may take a while.';
                }
                group(ManualOauthSetup)
                {
                    ShowCaption = false;
                    InstructionalText = 'We will now send your information to ForNAV. When you have been approved you will receive an Oauth setup file so you can connect to the ForNAV Peppol network.';
                }
            }
            group(FinalStep)
            {
                Visible = FinalStepVisible;
                InstructionalText = 'Done - Test Setup.';
                Caption = 'Done';
                group(Go4)
                {
                    ShowCaption = false;
                    Visible = Rec.Authorized;
                    InstructionalText = 'That''s it, you are now ready to connect to the ForNAV Peppol network.';
                }
                group(Fault)
                {
                    ShowCaption = false;
                    Visible = not Rec.Authorized;
                    InstructionalText = 'We were unable to connect to the ForNAV Peppol network. Contact your ForNAV Partner for help.';
                }
                field(ClientId; GetClientID())
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Client Id';
                    ToolTip = 'Specifies the Oauth Client Id. You can get this from your ForNAV partner.';
                }
                field(Authorized; Rec.Authorized)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Setup Message"; Rec."Setup Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(true)
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(false)
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    var
        Setup: Record "ForNAV Peppol Setup";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        Setup.InitSetup();
        Rec := Setup;
        ContactPerson := Rec."Contact Person";
        EMail := Rec."E-Mail";
        Rec.Endpoint := PeppolOauth.GetDefaultEndpoint();
        Rec.Modify();
        Step := Step::Step1;
        EnableControls();
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        Step: Option Step1,Step2,Step3,Finish;
        ContactPerson: Text[50];
        EMail: Text[80];
        TopBannerVisible: Boolean;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        FinalStepVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and
            MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
                MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Step1:
                ShowStep1();
            Step::Step2:
                ShowStep2();
            Step::Step3:
                ShowStep3();
            Step::Finish:
                ShowFinishStep();
        end;
    end;

    local procedure ProcessStepAction()
    var
        Setup: Record "ForNAV Peppol Setup";
        PeppolAadApp: Codeunit "ForNAV Peppol Aad App";
    begin
        case Step of
            Step::Step1:
                ;
            Step::Step2:
                begin
                    PeppolAadApp.CreateAADApplication(false);
                    PeppolAadApp.GrantAccess();
                end;
            Step::Step3:
                begin
                    Rec.TestField(Name);
                    Rec.TestField("Identification Code");
                    Rec.TestField("Identification Value");
                    Rec.TestField("Contact Person");
                    Rec.TestField("E-Mail");
                    Setup.FindFirst();
                    Setup."Contact Person" := Rec."Contact Person";
                    Setup."E-Mail" := Rec."E-Mail";
                    Setup.Modify();
                    Setup.SetupOauth(Rec.Endpoint);
                    Rec := Setup;
                    CurrPage.Update();
                end;
            Step::Finish:
                ;
        end;
    end;

    local procedure ShowStep1()
    begin
        Step := Step::Step1;
        Step1Visible := true;
        BackActionEnabled := false;
        NextActionEnabled := true;
    end;

    local procedure ShowStep2()
    begin
        Step := Step::Step2;
        Step2Visible := true;
        NextActionEnabled := true;
    end;

    local procedure ShowStep3()
    begin
        Step := Step::Step3;
        Step3Visible := true;
        NextActionEnabled := true;
    end;

    local procedure ShowFinishStep()
    begin
        Step := Step::Finish;
        NextActionEnabled := false;
        FinalStepVisible := true;
        FinishActionEnabled := Rec.Authorized;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        Step1Visible := false;
        Step2Visible := false;
        Step3Visible := false;
        FinalStepVisible := false;
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        ProcessStepAction();
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;
        EnableControls();
    end;

    local procedure FinishAction()
    begin
        CurrPage.Close();
    end;

    local procedure GetClientID(): Text
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        exit(PeppolOauth.GetClientID());
    end;
}