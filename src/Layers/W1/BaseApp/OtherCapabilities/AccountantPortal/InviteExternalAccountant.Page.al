namespace Microsoft.AccountantPortal;

using System;
using System.Azure.Identity;
using System.Email;
using System.Environment;
using System.Security.AccessControl;
using System.Utilities;

page 9033 "Invite External Accountant"
{
    Caption = 'Invite External Accountant';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            group(Control10)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to assisted setup for inviting an external accountant.")
                {
                    Caption = 'Welcome to assisted setup for inviting an external accountant.';
                    Visible = FirstStepVisible;
                    group(Control12)
                    {
                        InstructionalText = 'This guide will help you invite an external accountant to login to your company.';
                        ShowCaption = false;
                        Visible = FirstStepVisible;
                        group(Control24)
                        {
                            InstructionalText = 'This Invite External Accountant feature allows your organization to share its data with an external party either through the use of a separate portal or through the external party''s access to your organization''s online services account. Microsoft has no control over the third-party''s use of your data. You are responsible for ensuring that you have separate agreements in place with any such external user governing such external user''s access to and use of your data.';
                            ShowCaption = false;
                            Visible = FirstStepVisible;
                            group("By clicking 'I Accept', you consent to share your organization's data with external parties you designate.")
                            {
                                InstructionalText = 'By clicking ''I Accept'', you consent to share your organization''s data with external parties you designate.';
                                ShowCaption = false;
                                Visible = FirstStepVisible;
                                field(DataPrivacy; DataPrivacyAccepted)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = 'I Accept';
                                    ToolTip = 'Specifies your consent to share your organization''s data with external parties you designate.';

                                    trigger OnValidate()
                                    begin
                                        NextActionEnabled := DataPrivacyAccepted;
                                    end;
                                }
                                group(Control7)
                                {
                                    InstructionalText = 'Choose Next to get started.';
                                    ShowCaption = false;
                                    Visible = FirstStepVisible;
                                }
                            }
                        }
                    }
                }
            }
            group(Control13)
            {
                ShowCaption = false;
                Visible = DefineInformationStepVisible;
                group(Control20)
                {
                    ShowCaption = false;
                    Visible = DefineInformationStepVisible;
                    field(NewUserEmailAddress; NewUserEmailAddress)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email Address';
                        ShowCaption = true;
                        ShowMandatory = true;
                        ToolTip = 'Microsoft Entra email address of accountant.';
                    }
                }
                group(Control25)
                {
                    ShowCaption = false;
                    Visible = DefineInformationStepVisible;
                    field(NewFirstName; NewFirstName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'First Name';
                        ShowCaption = true;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            DefineInitialEmailBody();
                        end;
                    }
                }
                group(Control15)
                {
                    ShowCaption = false;
                    Visible = DefineInformationStepVisible;
                    field(NewLastName; NewLastName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Name';
                        ShowCaption = true;
                        ShowMandatory = true;
                    }
                }
                group("Welcome Email")
                {
                    Caption = 'Welcome Email';
                    Visible = DefineInformationStepVisible;
                    field(NewUserWelcomeEmail; NewUserWelcomeEmail)
                    {
                        ApplicationArea = Basic, Suite;
                        MultiLine = true;
                        ShowCaption = false;
                        RowSpan = 8;
                    }
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = CloseActionVisible;
                field(InvitationResult; InvitationResult)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                    ShowCaption = false;
                    Style = Strong;
                    StyleExpr = true;
                }
                field(InviteProgress; InviteProgress)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                    MultiLine = true;
                    ShowCaption = false;
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
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if Step = Step::DefineInformation then begin
                        if (NewUserEmailAddress <> '') and (NewFirstName <> '') and (NewLastName <> '') and (NewUserWelcomeEmail <> '') then begin
                            Invite();
                            OnInvitationEnd(WasInvitationSuccessful, InvitationResult, TargetLicense);
                            NextStep(false);
                        end else
                            Error(NotAllFieldsEnteredErrorErr);
                    end else
                        NextStep(false);
                end;
            }
            action(ActionClose)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Close';
                Enabled = true;
                Image = NextRecord;
                InFooterBar = true;
                Visible = CloseActionVisible;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        DefineInitialEmailBody();
    end;

    trigger OnOpenPage()
    var
        DummyEmailAccount: Record "Email Account";
        EmailScenario: Codeunit "Email Scenario";
        EnvironmentInfo: Codeunit "Environment Information";
        InviteExternalAccountant: Codeunit "Invite External Accountant";
        NavUserAccountHelper: DotNet NavUserAccountHelper;
        ProgressWindow: Dialog;
        ErrorMessage: Text;
    begin
        OnInvitationStart();
        if not EnvironmentInfo.IsSaaS() then
            Error(SaaSOnlyErrorErr);

        ProgressWindow.Open(WizardOpenValidationMsg);
        if not EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Invite External Accountant", DummyEmailAccount) then
            Error(NoEmailAccountDefinedErr, Enum::"Email Scenario"::"Invite External Accountant");

        if not InviteExternalAccountant.InvokeIsExternalAccountantLicenseAvailable(ErrorMessage, TargetLicense) then begin
            OnInvitationNoExternalAccountantLicenseFail();
            Error(NoExternalAccountantLicenseAvailableErr);
        end;

        if not InviteExternalAccountant.InvokeIsUserAdministrator() then begin
            OnInvitationNoAADPermissionsFail();
            Error(NoAADPermissionsErr);
        end;

        if not (NavUserAccountHelper.IsSessionAdminSession() or NavUserAccountHelper.IsUserSuperInAllCompanies()) then begin
            OnInvitationNoUserTablePermissionsFail();
            Error(NoUserTableWritePermissionErr);
        end;

        ProgressWindow.Close();
        Step := Step::Start;
        EnableControls();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then
            if not UserInvited then
                if not Confirm(SetupNotCompletedQst, false) then
                    Error('');
    end;

    var
        InviteExternalAccountant: Codeunit "Invite External Accountant";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        Step: Option Start,DefineInformation,Finish;
        FirstStepVisible: Boolean;
        DefineInformationStepVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        SetupNotCompletedQst: Label 'The user was not yet invited. Are you sure that you want to exit?';
        DataPrivacyAccepted: Boolean;
        CloseActionVisible: Boolean;
        NewUserEmailAddress: Text;
        NewFirstName: Text;
        NewLastName: Text;
        NewUserWelcomeEmail: Text;
        UserInvited: Boolean;
        EmailGreetingTxt: Label 'Hello ';
        EmailBodyTxt: Label 'Please accept this invitation to get access to my %1.', Comment = '%1 - product name';
        EmailClosingTxt: Label 'Best Regards,';
        SaaSOnlyErrorErr: Label 'This functionality is not intended for on premises.';
        InviteProgress: Text;
        InvitationErrorTxt: Label 'Inviting the external accountant failed while doing the %1.\\You can invite accountant manually instead. For more information, see this Help article:\https://go.microsoft.com/fwlink/?linkid=2114063', Comment = '%1=part of the invite process, e.g. invite, profile update, license assignment.';
        InviteTxt: Label 'invite';
        ProfileUpdateTxt: Label 'profile update';
        LicenseAssignmentTxt: Label 'license assignment';
        EmailTxt: Label 'email';
        InvitationSuccessTxt: Label '%1 %2 was successfully invited!', Comment = '%1=first name.  %2 =last name.';
        NoExternalAccountantLicenseAvailableErr: Label 'No External Accountant license available. Contact your administrator.';
        NoAADPermissionsErr: Label 'You do not have permission to invite the user. You must either be a global administrator or a user administrator in Microsoft Entra ID. Please contact your administrator.';
        WizardOpenValidationMsg: Label 'Verifying permissions and license availability.';
        InviteProgressWindowMsg: Label 'Inviting external accountant.  This process could take a little while.';
        EmailSubjectTxt: Label 'You have been invited to %1', Comment = '%1 - product name';
        OpenTheFollowingLinkTxt: Label 'Open the following link to verify that you can log in.';
        LicenseAlreadyAssignedTxt: Label 'A license is already assigned to %1.', Comment = '%1 - user email';
        InvitationResult: Text;
        FailureTxt: Label 'Failure';
        SuccessTxt: Label 'Success';
        EmailErrorTxt: Label 'Error occurred while sending email.';
        NotAllFieldsEnteredErrorErr: Label 'To continue, enter all required fields.';
        WasInvitationSuccessful: Boolean;
        NoEmailAccountDefinedErr: Label 'Email is not set up for the action you are trying to take. Ask your administrator to either add the %1 scenario to your email account, or to specify a default account for email scenarios.', Comment = '%1 = email scenario, e.g. "Email Printer"';
        NoUserTableWritePermissionErr: Label 'This step adds a user to your company, and only your administrator can do that. Please contact your administrator.';
        TargetLicense: Text;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::DefineInformation:
                ShowDefineInformationStep();
            Step::Finish:
                ShowFinishStep();
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

        BackActionEnabled := false;
    end;

    local procedure ShowDefineInformationStep()
    begin
        DefineInformationStepVisible := true;
    end;

    local procedure ShowFinishStep()
    begin
        NextActionEnabled := false;
        CloseActionVisible := true;
    end;

    local procedure Invite()
    var
        AzureADGraph: Codeunit "Azure AD Graph";
        GuestGraphUser: DotNet UserInfo;
        TenantDetail: DotNet TenantInfo;
        ProgressWindow: Dialog;
        InvitedUserId: Guid;
        InviteRedeemUrl: Text;
        ErrorMessage: Text;
    begin
        UserInvited := true;
        ProgressWindow.Open(InviteProgressWindowMsg);

        if not InviteExternalAccountant.InvokeInvitationsRequest(NewFirstName + NewLastName,
             NewUserEmailAddress, GetWebClientUrl(), InvitedUserId, InviteRedeemUrl, ErrorMessage)
        then begin
            InvitationResult := FailureTxt;
            InviteProgress := StrSubstNo(InvitationErrorTxt, InviteTxt);
            InviteExternalAccountant.SendTelemetryForWizardFailure(InviteTxt, ErrorMessage);
            ProgressWindow.Close();
            exit;
        end;

        if not InviteExternalAccountant.TryGetGuestGraphUser(InvitedUserId, GuestGraphUser) then begin
            InvitationResult := FailureTxt;
            InviteProgress := StrSubstNo(InvitationErrorTxt, InviteTxt);
            InviteExternalAccountant.SendTelemetryForWizardFailure(InviteTxt, ErrorMessage);
            ProgressWindow.Close();
            exit;
        end;

        if not InviteExternalAccountant.IsLicenseAlreadyAssigned(GuestGraphUser) then begin
            AzureADGraph.GetTenantDetail(TenantDetail);

            if not InviteExternalAccountant.InvokeUserProfileUpdateRequest(GuestGraphUser,
                TenantDetail.CountryLetterCode, ErrorMessage)
            then begin
                InvitationResult := FailureTxt;
                InviteProgress := StrSubstNo(InvitationErrorTxt, ProfileUpdateTxt);
                InviteExternalAccountant.SendTelemetryForWizardFailure(ProfileUpdateTxt, ErrorMessage);
                ProgressWindow.Close();
                exit;
            end;

            if not InviteExternalAccountant.InvokeUserAssignLicenseRequest(GuestGraphUser, TargetLicense, ErrorMessage) then begin
                InvitationResult := FailureTxt;
                InviteProgress := StrSubstNo(InvitationErrorTxt, LicenseAssignmentTxt);
                InviteExternalAccountant.SendTelemetryForWizardFailure(LicenseAssignmentTxt, ErrorMessage);
                ProgressWindow.Close();
                exit;
            end;

            InviteExternalAccountant.CreateNewUser(InvitedUserId);
        end else
            Message(StrSubstNo(LicenseAlreadyAssignedTxt, NewUserEmailAddress));

        if not SendInvitationEmail(NewUserEmailAddress) then begin
            InvitationResult := FailureTxt;
            InviteProgress := StrSubstNo(InvitationErrorTxt, EmailTxt);
            InviteExternalAccountant.SendTelemetryForWizardFailure(EmailTxt, EmailErrorTxt);
            ProgressWindow.Close();
            exit;
        end;

        ProgressWindow.Close();

        InvitationResult := SuccessTxt;
        WasInvitationSuccessful := true;
        InviteProgress := StrSubstNo(InvitationSuccessTxt, NewFirstName, NewLastName);
        InviteExternalAccountant.UpdateAssistedSetup();

        CurrPage.Update(false);
    end;

    local procedure SendInvitationEmail(SendTo: Text): Boolean
    var
        EmailAccount: Record "Email Account";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        EmailScenario: Codeunit "Email Scenario";
        SendToList: List of [Text];
    begin
        SendToList.Add(SendTo);
        EmailMessage.Create(SendToList, StrSubstNo(EmailSubjectTxt, PRODUCTNAME.Marketing()),
                DefineFullEmailBody(NewUserWelcomeEmail), true);
        EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Invite External Accountant", EmailAccount);
        exit(Email.Send(EmailMessage, EmailAccount."Account Id", EmailAccount.Connector));
    end;

    local procedure ResetControls()
    begin
        FirstStepVisible := false;
        DefineInformationStepVisible := false;
        NextActionEnabled := DataPrivacyAccepted;

        BackActionEnabled := true;

        CloseActionVisible := false;
    end;

    local procedure DefineInitialEmailBody()
    var
        User: Record User;
        Company: Record Company;
        EmailGreeting: Text;
        EmailBody: Text;
        EmailClosing: Text;
    begin
        User.Get(UserSecurityId());
        Company.Get(CompanyName);
        EmailGreeting := EmailGreetingTxt + NewFirstName + ',' + NewLineForTextControl();
        EmailBody := StrSubstNo(EmailBodyTxt, PRODUCTNAME.Marketing()) + NewLineForTextControl() + NewLineForTextControl();
        EmailClosing := EmailClosingTxt + NewLineForTextControl() + User."User Name" + NewLineForTextControl() + Company."Display Name";
        NewUserWelcomeEmail := EmailGreeting + EmailBody + EmailClosing;
        CurrPage.Update();
    end;

    local procedure DefineFullEmailBody(InitialEmailMessage: Text): Text
    var
        EmailBody: Text;
    begin
        EmailBody := ReplaceNewLinesWithHtmlLineBreak(InitialEmailMessage);
        EmailBody := EmailBody + LineBreakForEmail() + LineBreakForEmail();
        EmailBody := EmailBody + OpenTheFollowingLinkTxt + LineBreakForEmail();
        EmailBody := EmailBody + GetWebClientUrl() + LineBreakForEmail();
        EmailBody := EmailBody + LineBreakForEmail() + LineBreakForEmail();
        EmailBody := EmailBody + LineBreakForEmail() + LineBreakForEmail();
        exit(EmailBody)
    end;

    local procedure NewLineForTextControl() Newline: Text
    begin
        Newline[1] := 13;
        Newline[2] := 10;
    end;

    local procedure LineBreakForEmail(): Text
    begin
        exit('</br>');
    end;

    local procedure ReplaceNewLinesWithHtmlLineBreak(InputText: Text): Text
    var
        String: DotNet String;
        TextToReplace: Text;
    begin
        String := InputText;
        TextToReplace[1] := 10;
        exit(String.Replace(TextToReplace, LineBreakForEmail()));
    end;

    local procedure GetWebClientUrl(): Text
    var
        UrlHelper: Codeunit "Url Helper";
        AzureADGraph: Codeunit "Azure AD Graph";
        TenantDetail: DotNet TenantInfo;
        ClientUrl: Text;
        TenantDomainName: Text;
        TenantObjectId: Text;
    begin
        ClientUrl := UrlHelper.GetFixedClientEndpointBaseUrl();

        TenantDomainName := AzureADMgt.GetInitialTenantDomainName();
        AzureADGraph.GetTenantDetail(TenantDetail);
        TenantObjectId := TenantDetail.ObjectId;

        if StrLen(TenantDomainName) > 0 then
            ClientUrl := ClientUrl + TenantDomainName
        else
            ClientUrl := ClientUrl + TenantObjectId;

        ClientUrl := ClientUrl + '?redirectedfromsignup=1';

        exit(ClientUrl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvitationStart()
    begin
        // This event is called the invitation process is started.
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvitationNoExternalAccountantLicenseFail()
    begin
        // This event is called when the invitation process can not proceed due to a lack of external accountant licenses.
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvitationNoAADPermissionsFail()
    begin
        // This event is called when the invitation process can not proceed due to a lack of user Microsoft Entra ID permissions.
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvitationEnd(WasInvitationSuccessful: Boolean; Result: Text; TargetLicense: Text)
    begin
        // This event is called when the invitation process is finished.
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvitationNoUserTablePermissionsFail()
    begin
        // This event is called when the invitation process can not proceed because session is not admin or user is not super in all companies.
    end;
}

