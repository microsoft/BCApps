// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Environment;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;
#pragma warning disable AS0018
#pragma warning disable AS0032
page 9192 "Company Creation Wizard"
{
    Caption = 'Create New Company';
    PageType = NavigatePage;
    SourceTable = User;
    SourceTableTemporary = true;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(Control6)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control8)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control10)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to assisted setup for creating a company")
                {
                    Caption = 'Welcome to assisted setup for creating a company';
                    Visible = FirstStepVisible;
                    group(Control12)
                    {
                        InstructionalText = 'This guide will help you create a new company.';
                        ShowCaption = false;
                        Visible = FirstStepVisible;
                    }
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to get started.';
                }
            }
            group(Control13)
            {
                ShowCaption = false;
                Visible = CreationStepVisible;
                group("Specify some basic information")
                {
                    Caption = 'Specify some basic information';
                    Visible = CreationStepVisible;
                    group(Control20)
                    {
                        InstructionalText = 'Enter a name for the company.';
                        ShowCaption = false;
                        field(CompanyName; NewCompanyName)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            ShowMandatory = true;

                            trigger OnValidate()
                            var
                                Company: Record Company;
                            begin
                                NewCompanyName := DelChr(NewCompanyName, '<>');
                                Company.SetFilter(Name, '%1', '@' + NewCompanyName);
                                if not Company.IsEmpty() then
                                    Error(CompanyAlreadyExistsErr);

                                OnAfterValidateCompanyName(NewCompanyName);
                            end;
                        }
                    }
                    group("Select the data and setup to get started.")
                    {
                        Caption = 'Select the data and setup to get started.';
                        group(Control26)
                        {
                            ShowCaption = false;
                            field(CompanyData; NewCompanyData)
                            {
                                ApplicationArea = Basic, Suite;
                                ShowCaption = false;

                                trigger OnValidate()
                                var
                                    CompanyCreationDemoData: Codeunit "Company Creation Demo Data";
                                begin
                                    if NewCompanyData in [NewCompanyData::"Evaluation - Contoso Sample Data", NewCompanyData::"Production - Setup Data Only"] then
                                        CompanyCreationDemoData.CheckDemoDataAppsAvailability();

                                    UpdateDataDescription();
                                end;
                            }
                        }
#pragma warning restore AS0032
#pragma warning restore AS0072
                        field(NewCompanyDataDescription; NewCompanyDataDescription)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            MultiLine = true;
                            ShowCaption = false;
                        }
                    }
                }
            }
            group(DemoData)
            {
                ShowCaption = false;
                Visible = DemoDataStepVisible;
                group("Available Modules")
                {
                    Caption = 'Available Modules';
                }
            }
            group(Control32)
            {
                ShowCaption = false;
                Visible = AddUsersVisible;
                group("Manage users of the new company.")
                {
                    Caption = 'Manage users of the new company.';
                    Visible = CanManageUser;
                    group(Control30)
                    {
                        InstructionalText = 'Add users to or remove users from the new company.';
                        ShowCaption = false;
                        field(ManageUserLabel; ManageUsersLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Manage Users';
                            Editable = false;
                            ShowCaption = false;
                            Style = AttentionAccent;
                            StyleExpr = true;

                            trigger OnDrillDown()
                            var
                                UserSelection: Codeunit "User Selection";
                            begin
                                Clear(Rec);
                                UserSelection.Open(Rec);
                                ContainUsers := not Rec.IsEmpty();
                                CurrPage.Update(false);
                            end;
                        }
                        group(Users)
                        {
                            Caption = 'Users';
                            Editable = false;
                            Enabled = false;
                            Visible = ContainUsers;
                            repeater(Control38)
                            {
                                ShowCaption = false;
                                field("User Name"; Rec."User Name")
                                {
                                    ApplicationArea = Basic, Suite;
                                    TableRelation = User;
                                    ToolTip = 'Specifies the name that the user must present when signing in. ';
                                }
                                field("Full Name"; Rec."Full Name")
                                {
                                    ApplicationArea = Basic, Suite;
                                    Editable = false;
                                    ToolTip = 'Specifies the full name of the user.';
                                }
                            }
                        }
                    }
                }
                group("The new company will be created without users")
                {
                    Caption = 'The new company will be created without users';
                    Visible = not CanManageUser;
                    field(OnlySuperCanLabel; OnlySuperCanManageUsersLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = AttentionAccent;
                        StyleExpr = true;
                    }
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Control19)
                    {
                        InstructionalText = 'Choose Finish to create the company. This can take a few minutes to complete.';
                        ShowCaption = false;
                    }
                    group(Control22)
                    {
                        InstructionalText = 'The company is created and included in the companies list, but before you use it we need time to set up some data and settings for you.';
                        ShowCaption = false;
                        Visible = ConfigurationPackageExists;
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
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        UserPermissions: Codeunit "User Permissions";
    begin
        if not UserPermissions.IsSuper(UserSecurityId()) then
            Error(OnlySuperCanCreateNewCompanyErr);

        LoadTopBanners();
        IsSandbox := EnvironmentInfo.IsSandbox();
        CanManageUser := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
    end;

    trigger OnOpenPage()
    begin
        Step := Step::Start;
        NewCompanyData := NewCompanyData::"Create New - No Data";
        UpdateDataDescription();
        EnableControls();
        CurrPage.Update(false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then
            if not CompanyCreated then
                if not Confirm(SetupNotCompletedQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Creation,"Demo Data","Add Users",Finish;
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        CreationStepVisible: Boolean;
        DemoDataStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        SetupNotCompletedQst: Label 'The company has not yet been created.\\Are you sure that you want to exit?';
        ConfigurationPackageExists: Boolean;
        NewCompanyName: Text[30];
        NewCompanyData: Enum "Company Demo Data Type";
        CompanyAlreadyExistsErr: Label 'A company with that name already exists. Try a different name.';
        NewCompanyDataDescription: Text;
        CompanyCreated: Boolean;
        SpecifyCompanyNameErr: Label 'To continue, you must specify a name for the company.';
        EvaluationDataTxt: Label '\Contoso Company Sample Data / Setup Data\\Create a company that has everything you need to evaluate Business Central. For example, invoices and ledger entries let you explore charts and reports. Accounts, items, vendors, and customers showcase financial and operational capabilities.';
        StandardDataTxt: Label '\Essential Experience / Setup Data Only\\Create a company with the Essential functionality scope containing data and setup, such as a chart of accounts and payment methods ready for use by companies with standard processes. Set up your own items and customers, and start posting right away.';
        NoDataTxt: Label '\Any Experience / No Sample Data / No Setup Data\\Create a company with the desired experience for companies with any process complexity, and set it up manually.';
        TrialPeriodTxt: Label '\\You will be able to use this company for a 30-day trial period.';
        EvalPeriodTxt: Label '\\You will be able to use the company to try out the product for as long as you want. ';
        IsSandbox: Boolean;
        CompanySetUpInProgressMsg: Label 'Company %1 is created, but we are still setting it up.\This might take some time, so take a break before you begin to use it. When it is ready, its status is Completed. Refresh the page to update the status.', Comment = '%1 - a company name';
        AddUsersVisible: Boolean;
        ManageUsersLbl: Label 'Manage Users';
        CanManageUser: Boolean;
        ContainUsers: Boolean;
        OnlySuperCanManageUsersLbl: Label 'Only administrators and super users can sign in to this company and manage users.';
        OnlySuperCanCreateNewCompanyErr: Label 'Only users with the SUPER permission set can create a new company.';

    procedure GetNewCompanyName(): Text[30];
    begin
        exit(NewCompanyName);
    end;

    procedure GetStep(): Option Start,Creation,"Demo Data","Add Users",Finish;
    begin
        exit(Step);
    end;

    procedure GetNewCompanyData(): Enum "Company Demo Data Type"
    begin
        exit(NewCompanyData);
    end;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::Creation:
                ShowCreationStep();
            Step::"Demo Data":
                ShowDemoDataStep();
            Step::"Add Users":
                ShowAddUsersStep();
            Step::Finish:
                ShowFinalStep();
        end;
    end;

    local procedure FinishAction()
    var
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        PermissionManager: Codeunit "Permission Manager";
    begin
        AssistedCompanySetup.CreateNewCompany(NewCompanyName);
        OnAfterCreateNewCompany(NewCompanyData, NewCompanyName);

        AssistedCompanySetup.SetupCompanyWithoutDemodata(NewCompanyName, NewCompanyData);

        if Rec.FindSet() then
            repeat
                PermissionManager.AssignDefaultPermissionsToUser(Rec."User Security ID", NewCompanyName);
            until Rec.Next() = 0;

        CompanyCreated := true;
        OnFinishActionOnBeforeCurrPageClose(NewCompanyData, NewCompanyName);
        CurrPage.Close();

        if not (NewCompanyData in [NewCompanyData::"Create New - No Data"]) then
            Message(CompanySetUpInProgressMsg, NewCompanyName);
    end;

    local procedure NextStep(Backwards: Boolean)
    var
        CompanyCreationDemoData: Codeunit "Company Creation Demo Data";
    begin
        if (Step = Step::Creation) and not Backwards then
            if NewCompanyName = '' then
                Error(SpecifyCompanyNameErr);
        if (Step = Step::Creation) and not Backwards then
            // Skip demo data page if user chooses to create company without data
            if NewCompanyData = NewCompanyData::"Create New - No Data" then
                Step := Step + 1
            else begin
                CompanyCreationDemoData.CheckDemoDataAppsAvailability();
                CurrPage.Update();
            end;
        if (Step = step::"Add Users") and Backwards then
            if NewCompanyData = NewCompanyData::"Create New - No Data" then
                Step := Step - 1;

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;

        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowCreationStep()
    begin
        CreationStepVisible := true;

        FinishActionEnabled := false;
    end;

    local procedure ShowDemoDataStep()
    begin
        DemoDataStepVisible := true;

        FinishActionEnabled := false;
    end;

    local procedure ShowAddUsersStep()
    begin
        AddUsersVisible := true;

        FinishActionEnabled := false;
    end;

    local procedure ShowFinalStep()
    begin
        FinalStepVisible := true;
        NextActionEnabled := false;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := true;
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        CreationStepVisible := false;
        DemoDataStepVisible := false;
        AddUsersVisible := false;
        FinalStepVisible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure UpdateDataDescription()
    var
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        case NewCompanyData of
            NewCompanyData::"Evaluation - Contoso Sample Data":
                NewCompanyDataDescription := EvaluationDataTxt;
            NewCompanyData::"Production - Setup Data Only":
                NewCompanyDataDescription := StandardDataTxt;
            NewCompanyData::"Create New - No Data":
                NewCompanyDataDescription := NoDataTxt;
            else
                OnUpdateDataDescriptionCaseElse(NewCompanyData, NewCompanyDataDescription);
        end;

        if IsSandbox then
            exit;

        if TenantLicenseState.IsPaidMode() then
            exit;

        case NewCompanyData of
            NewCompanyData::"Evaluation - Contoso Sample Data":
                NewCompanyDataDescription += EvalPeriodTxt;
            NewCompanyData::"Production - Setup Data Only",
            NewCompanyData::"Create New - No Data":
                NewCompanyDataDescription += TrialPeriodTxt;
        end;
    end;

#pragma warning disable AS0072
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateNewCompany(NewCompanyData: Enum "Company Demo Data Type"; NewCompanyName: Text[30])
    begin
    end;
#pragma warning restore AS0072

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCompanyName(var NewCompanyName: Text[30])
    begin
    end;

#pragma warning disable AS0072
    [IntegrationEvent(false, false)]
    local procedure OnFinishActionOnBeforeCurrPageClose(NewCompanyData: Enum "Company Demo Data Type"; NewCompanyName: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDataDescriptionCaseElse(NewCompanyData: Enum "Company Demo Data Type"; var NewCompanyDataDescription: Text)
    begin
    end;
#pragma warning restore AS0072
}
#pragma warning restore AS0032
#pragma warning restore AS0018
