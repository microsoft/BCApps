namespace System.Diagnostics;

using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.Privacy;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;
using System.Telemetry;

page 1368 "Monitor Field Setup Wizard"
{
    Caption = 'Field Monitoring Assisted Setup Guide';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            group("In Progress Banner")
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (Step <> Step::Finish);
                field(MediaResourceStandardReference; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(WelcomePage)
            {
                ShowCaption = false;
                Visible = Step = Step::Welcome;
                group("WELCOME")
                {
                    Caption = 'Welcome';
                    InstructionalText = 'Monitoring fields helps prevent unwanted changes to sensitive data. When someone changes a value in a monitored field, the change is logged, and a notification can be sent by email to a designated recipient.';
                    label("LoggingDescription")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'For each change, you can view the original and new value, the user who made the change, and the time and date that the change occurred.';
                        Importance = Additional;
                        MultiLine = true;
                    }
                    label("Perf Impact")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Monitoring fields can impact performance. We recommend that you only monitor the fields you think are most important.';
                        Importance = Additional;
                        MultiLine = true;
                    }
                }
            }

            group("Import Fields")
            {
                ShowCaption = false;
                Visible = Step = Step::"Import Fields";
                group("Let''s Get Started")
                {
                    Caption = 'Let''s Get Started';
                    InstructionalText = 'If you have specified data sensitivity classifications for fields, you can add the fields based on their classifications.';

                    label("Add Fields")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'If you have not classified your fields, you can add fields and manage settings for individual fields on the Monitored Fields Worksheet page.';
                        Importance = Additional;
                        MultiLine = true;
                    }
                    field(OpenDataClassificationWorksheetMsg; OpenDataClassificationWorksheetMsg)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Opens Data Classification Worksheet';
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Page.Run(Page::"Data Classification Worksheet");
                        end;
                    }
                    field(ImportSensitiveFields; ImportSensitiveFields)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sensitive';
                        ToolTip = 'Specifies whether to add fields that have a Sensitive data sensitivity classification.';
                    }
                    field(ImportPersonalFields; ImportPersonalFields)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Personal';
                        ToolTip = 'Specifies whether to add fields that have a Personal data sensitivity classification.';
                    }
                    field(ImportCompanyConfidentialFields; ImportCompanyConfidentialFields)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Company Confidential';
                        ToolTip = 'Specifies whether to add fields that have a Company Confidential data sensitivity classification.';
                    }
                }
            }
            group(ChooseUser)
            {
                ShowCaption = false;
                Visible = Step = Step::"Choose User";

                group("Choose User Description")
                {
                    Caption = 'Choose The Change Notification Recipient ';
                    InstructionalText = 'Specify the user who will receive an email notification when someone changes a value in a monitored field.';


                    field("Notification Recipient"; MonitorUserId)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the username of the person to notify about a change in a monitored field.';
                        caption = 'Notification Recipient';
                        ShowMandatory = true;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            User: Record User;
                        begin
                            if Page.RunModal(Page::"User Lookup", User) = ACTION::LookupOK then begin
                                MonitorUserId := User."User Name";
                                MonitorSensitiveField.CheckUserHasValidContactEmail(MonitorUserId);
                                MonitorSensitiveField.ValidateUserPermissions(MonitorUserId, DoesUserHasPermission);
                            end;
                            ResetControls();
                        end;

                        trigger OnValidate()
                        begin
                            MonitorSensitiveField.CheckUserHasValidContactEmail(MonitorUserId);
                            MonitorSensitiveField.ValidateUserPermissions(MonitorUserId, DoesUserHasPermission);
                            ResetControls();
                        end;
                    }
                    group(EmailAccount)
                    {
                        ShowCaption = false;
                        field("Email Account Name"; EmailAccountName)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the email account that will send the notification email. Typically, this is a system account that is not associated with a user.';
                            caption = 'Notification Email Account';
                            ShowMandatory = true;
                            Editable = false;

                            trigger OnAssistEdit()
                            var
                                TempEmailAccount: Record "Email Account" temporary;
                            begin
                                if Page.RunModal(Page::"Email Accounts", TempEmailAccount) = Action::LookupOK then begin
                                    EmailAccountId := TempEmailAccount."Account Id";
                                    EmailConnector := TempEmailAccount.Connector;
                                    EmailAccountName := TempEmailAccount.Name;
                                end;
                                ResetControls();
                            end;
                        }
                    }

                    group("Permission Warning")
                    {
                        Visible = not DoesUserHasPermission;
                        label("User required permissions")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'The selected user can receive email notifications about changes to field values. To allow the user to address changes you must assign the D365 Monitor Fields permission set to them.',
                                comment = 'Do not translate D365 Security or D365 Monitor Fields';
                            Importance = Additional;
                            MultiLine = true;
                        }
                        field(OpenUserCardMsg; OpenUserCardMsg)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Opens User page for the selected user';
                            Caption = 'Do you want to do that now?';

                            trigger OnDrillDown()
                            begin
                                MonitorSensitiveField.OpenUserCard(MonitorUserId);
                            end;
                        }
                    }

                }
            }
            group("Done Banner")
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (Step = Step::Finish);
                field(MediaResourceDoneReference; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group("Verify and Finish")
            {
                ShowCaption = false;
                Visible = Step = Step::Finish;

                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group("Click Finish")
                    {
                        InstructionalText = 'For notifications, you must specify the fields for which to send them. Turn on the View Monitored Fields toggle, and then choose Finish to open the Monitored Fields Worksheet page. Choose Notify for each field.';
                        ShowCaption = false;
                    }
                    group("Moniotr Notificaiton")
                    {
                        InstructionalText = 'If you just want to start monitoring fields, choose Finish. You will need to restart Business Central.';
                        ShowCaption = false;
                    }
                    field(OpenMonitorWorksheetPage; OpenMonitorWorksheetPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'View Monitored Fields';
                        ToolTip = 'Open the Monitored Fields Worksheet to review your settings when finished.';
                    }
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
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                ToolTip = 'Go to previous page';
                Enabled = BackEnabled;
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
                ToolTip = 'Go to next page';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                ToolTip = 'Finish the wizard';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ValidateAndFinishSetup();
                    CurrPage.Close();
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
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        EmailAccounts: Codeunit "Email Account";
    begin
        MonitorSensitiveField.ValidateUserPermissions(CopyStr(UserId(), 1, 50), DoesUserHasPermission);
        if not DoesUserHasPermission then
            Error(MissingPermissionErr);

        if not EmailAccounts.IsAnyAccountRegistered() then begin
            if Confirm(EmailConnectorMissingQst) then
                Page.Run(Page::"Email Account Wizard");
            Error('');
        end;

        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        MonitorUserId := FieldMonitoringSetup."User Id";
        EmailAccountName := FieldMonitoringSetup."Email Account Name";
        EmailAccountId := FieldMonitoringSetup."Email Account Id";
        OpenMonitorWorksheetPage := true;

        ResetControls();
    end;

    local procedure ResetControls()
    begin
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        case Step of
            Step::Welcome:
                BackEnabled := false;
            Step::"Choose User":
                NextEnabled := (MonitorUserId <> '') and ((EmailAccountName <> ''));
            Step::Finish:
                begin
                    FinishEnabled := true;
                    NextEnabled := false;
                end;
        end;
    end;

    local procedure NextStep(Backward: Boolean)
    begin
        if Backward then
            Step -= 1
        else
            Step += 1;

        ResetControls();
    end;

    local procedure ValidateAndFinishSetup()
    var
        AuditLog: Codeunit "Audit Log";
        GuidedExperience: Codeunit "Guided Experience";
        MonitorFieldSetUpLbl: Label 'The Monitor Field feature has been set up by UserSecurityId %1.', Locked = true;
    begin
        MonitorSensitiveField.SetSetupTable(MonitorUserId, EmailAccountId, EmailAccountName, EmailConnector);

        MonitorSensitiveField.ImportFieldsBySensitivity(ImportSensitiveFields, ImportPersonalFields, ImportCompanyConfidentialFields);
        MonitorSensitiveField.EnableMonitor(false);

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, page::"Monitor Field Setup Wizard");
        AuditLog.LogAuditMessage(StrSubstNo(MonitorFieldSetUpLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
        if OpenMonitorWorksheetPage then
            Page.Run(Page::"Monitored Fields Worksheet");
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

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
        ClientTypeManagement: Codeunit "Client Type Management";
        EmailAccountName: Text[250];
        EmailAccountId: Guid;
        EmailConnector: enum "Email Connector";
        MonitorUserId: Code[50];
        Step: Option Welcome,"Import Fields","Choose User",Finish;
        NextEnabled, BackEnabled, FinishEnabled, TopBannerVisible : Boolean;
        ImportSensitiveFields, ImportPersonalFields, ImportCompanyConfidentialFields, DoesUserHasPermission, ShowEmailConnector, OpenMonitorWorksheetPage : Boolean;
        OpenUserCardMsg: Label 'Do you want to do that now?';
        OpenDataClassificationWorksheetMsg: Label 'View Data Classification Worksheet';
        EmailConnectorMissingQst: Label 'To send notifications about changes in field values you must set up email in Business Central. Do you want to do that now?';
        MissingPermissionErr: label 'You do not have permission to use this setup guide. To run the guide, the D365 Monitor Fields permission set must be assigned to you.', comment = 'Do not translate D365 Security or D365 Monitor Fields';
}