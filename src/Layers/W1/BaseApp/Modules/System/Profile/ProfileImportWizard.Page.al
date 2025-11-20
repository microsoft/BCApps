namespace System.Environment.Configuration;

using System.Agents;
using System.IO;
using System.Apps;
using System.Tooling;

page 9199 "Profile Import Wizard"
{
    Caption = 'Import profiles';
    ApplicationArea = All;
    UsageCategory = Administration;
    PageType = NavigatePage;
    SourceTable = "Profile Import";
    SourceTableTemporary = true;
    AccessByPermission = TableData "Profile Designer Diagnostic" = I;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            group(Step1)
            {
                Visible = Step1Visible;
                group("Welcome to Profile Import")
                {
                    Caption = 'Welcome to the import profiles guide';
                    group(WelcomeToWizardGroup)
                    {
                        Caption = '';
                        InstructionalText = 'You can update your list of profiles (roles) by uploading a package file that you exported earlier.';
                    }
                    group(BackupBeforeImportingGroup)
                    {
                        Caption = '';
                        InstructionalText = 'Importing a package can add new profiles or replace existing profiles and their page modifications. Before you import a package, we recommend that you create a copy of your existing profiles by using the Export Profiles action on the Profiles (Roles) page.';
                    }
                    group(BriefInterruptionGroup)
                    {
                        Caption = '';
                        InstructionalText = 'When you replace a profile, signed-in users who are assigned to the profile may be interrupted briefly.';
                    }
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    group(ChooseSelectPackageGroup)
                    {
                        Caption = '';
                        InstructionalText = 'Choose Select Package to find a profiles package file.';
                    }
                    group(SelectProfileBeforeImportGroup)
                    {
                        Caption = '';
                        InstructionalText = 'After choosing a package, you can select which profiles you want to add or replace before committing the change.';
                    }
                }
            }

            group(Step2)
            {
                Caption = '';
                InstructionalText = 'The package contains the following profiles. If there are profiles that you do not want to import, clear the check box.';
                Visible = Step2Visible;

                repeater(Control1)
                {
                    field(Selected; Rec.Selected)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies that the profile from the package will be imported.';
                        Width = 5;
                    }
                    field(Action; Action)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        StyleExpr = ActionStyleExpr;
                        Caption = 'Action';
                        ToolTip = 'Specifies the action performed upon import. Each profile from the package will either be added to your list of profiles or will overwrite a profile.';
                        Width = 10;
                    }
                    field("Profile ID"; Rec."Profile ID")
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ToolTip = 'Specifies an ID that is used to identify the profile (role). There can be more than one profile with the same ID if they come from different extensions.';
                    }
                    field(ApplicationNameField; ApplicationName)
                    {
                        Caption = 'Source of the profile in Business Central';
                        editable = false;
                        ApplicationArea = All;
                        ToolTip = 'For profiles that will be replaced, this indicates the origin of that profile which can be either an extension, shown by its name, or created by a user.';
                    }
                }
            }

            group(Step3)
            {
                Caption = '';
                Visible = Step3Visible;

                part(ProfileDesignerDiagnosticsListPart; "Profile Designer Diagnostics")
                {
                    ApplicationArea = All;
                    Caption = 'Results';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(BackAction)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Visible = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                ToolTip = 'Return to previous step';

                trigger OnAction();
                begin
                    NextStep(true);
                end;
            }
            action(SelectProfilePackageAction)
            {
                ApplicationArea = All;
                Caption = 'Select package';
                Visible = ImportProfilePackageActionVisible;
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Select a profile package to be imported.';

                trigger OnAction();
                begin
                    Rec.DeleteAll(); // Make sure to clean up current profiles
                    ServerFileName := FileManagement.UploadFileWithFilter(SelectProfileToImportTxt, ProfilesZipFileNameTxt, 'Zip file (*.zip)|*.zip', '*.zip');
                    if ServerFileName = '' then
                        Error(''); // User cancelled upload
                    NextStep(false); // On the next step we will automatically load the server file
                end;
            }
            action(ActionImport)
            {
                ApplicationArea = All;
                Caption = 'Import selected';
                Visible = ImportActionVisible;
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Import the selected profiles into the database.';

                trigger OnAction();
                var
                    ImportID: Guid;
                begin
                    TempProfileImport.SetRange(Selected, true);
                    if TempProfileImport.IsEmpty() then
                        Error(SelectProfileToImportErr);
                    ImportID := ProfileHelper.ImportProfiles(TempProfileImport);
                    CurrPage.ProfileDesignerDiagnosticsListPart.Page.SetRecords(ImportID);
                    CurrPage.ProfileDesignerDiagnosticsListPart.Page.Update(false);
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Done';
                Visible = DoneActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Close the wizard.';

                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnOpenPage();
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();

        Rec.Init();

        Rec.Insert();

        Step := Step::Start;
        EnableControls();
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec.Exists then begin
            Action := Action::Replace;
            ActionStyleExpr := 'Attention';
        end else begin
            Action := Action::Add;
            ActionStyleExpr := '';
        end;

        ApplicationName := ExtensionManagement.GetAppName(Rec."App ID");
    end;

    local procedure CreatePackageUploadDiagnosticsMessage(var DesignerDiagnostic: Record "Designer Diagnostic"): Text
    begin
        DesignerDiagnostic.SetRange(Severity, Enum::Severity::Warning);
        if not DesignerDiagnostic.IsEmpty() then
            exit(DiagnosticsWarningsReportedTxt);
        DesignerDiagnostic.SetRange(Severity, Enum::Severity::Information);
        if not DesignerDiagnostic.IsEmpty() then
            exit(DiagnosticsInformationalMessagesReportedTxt);
    end;

    procedure SetRecords(var TempProfileImport: Record "Profile Import" temporary)
    begin
        Rec.Copy(TempProfileImport, true);
    end;

    local procedure EnableControls();
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStep1();
            Step::SelectProfilesToImport:
                ShowStep2();
            Step::Finish:
                ShowStep3();
        end;
    end;

    local procedure FinishAction();
    begin
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean);
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
        HideNotifications();
        OnInitializeStep();
    end;

    local procedure BackupPreviousProfileImportSelections(var PreviousProfileImport: Record "Profile Import" temporary)
    begin
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                PreviousProfileImport := Rec;
                PreviousProfileImport.Insert();
            until Rec.Next() = 0;
    end;

    local procedure RestorePreviousProfileImportSelections(var PreviousProfileImport: Record "Profile Import" temporary)
    begin
        if Rec.FindSet() then
            repeat
                if PreviousProfileImport.Get(Rec."App ID", Rec."Profile ID") then begin
                    Rec.Selected := PreviousProfileImport.Selected;
                    Rec.Modify();
                end;
            until Rec.Next() = 0;
    end;

    local procedure OnInitializeStep()
    var
        TempPreviousProfileImport: Record "Profile Import" temporary;
        DesignerDiagnostic: Record "Designer Diagnostic";
        DiagnosticsNotification: Notification;
        SuccessfullyReadProfilePackage: Boolean;
        ImportID: Guid;
    begin
        if Step <> Step::SelectProfilesToImport then
            exit;

        BackupPreviousProfileImportSelections(TempPreviousProfileImport);

        // For step 2 we need to import/re-import the profile package and show the new status
        Clear(ProfileHelper); // when importing the same file twice, we need to make sure the file is not locked from previous read
        ProfileHelper.ImportProfileConfigurationPackage(ServerFileName);
        SuccessfullyReadProfilePackage := ProfileHelper.ReadProfilesFromPackage(TempProfileImport, ImportID);

        SetRecords(TempProfileImport);
        RestorePreviousProfileImportSelections(TempPreviousProfileImport);
        CurrPage.Update(false);

        if not SuccessfullyReadProfilePackage then begin
            // Something went wrong, show diagnostics screen immediately
            DesignerDiagnostic.SetRange("Operation ID", ImportID);
            DesignerDiagnostic.SetFilter(Severity, '<>%1', Enum::Severity::Hidden);
            Page.Run(Page::"Profile Import Diagnostics", DesignerDiagnostic);
            NextStep(true); // Move back to upload package step (something went wrong with upload)
            exit;
        end;

        DesignerDiagnostic.SetRange("Operation ID", ImportID);
        DesignerDiagnostic.SetFilter(Severity, '<>%1', Enum::Severity::Hidden);
        if not DesignerDiagnostic.IsEmpty() then begin
            DiagnosticsNotification.Id := DiagnosticsNotificationIDTxt;
            DiagnosticsNotification.Message := CreatePackageUploadDiagnosticsMessage(DesignerDiagnostic);
            DiagnosticsNotification.SetData('ImportID', ImportID);
            DiagnosticsNotification.AddAction(ShowDiagnosticsTxt, Codeunit::"Profile Helper", 'ShowProfileDiagnostics');
            NotificationLifecycleMgt.SendNotification(DiagnosticsNotification, TempProfileImport.RecordId());
        end;

        if Rec.IsEmpty() then begin
            Message(PackageDoesNotContainAnyProfilesMsg);
            NextStep(true); // Move back to upload package step (no profiles were in the package)
        end;
    end;

    local procedure HideNotifications()
    begin
        if Step = Step::SelectProfilesToImport then
            exit; // On any page != import profiles page, recall profile diagnostics notification

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure ShowStep1();
    begin
        CurrPage.Caption := StrSubstNo(ImportProfilesStepTxt, 1);
        Step1Visible := true;

        DoneActionEnabled := false;
        BackActionEnabled := false;
        ImportProfilePackageActionVisible := true;
    end;

    local procedure ShowStep2();
    begin
        CurrPage.Caption := StrSubstNo(ImportProfilesStepTxt, 2);
        Step2Visible := true;
        ImportActionVisible := true;
    end;

    local procedure ShowStep3();
    begin
        CurrPage.Caption := StrSubstNo(ImportProfilesStepTxt, 3);
        Step3Visible := true;

        DoneActionEnabled := true;
    end;

    local procedure ResetControls();
    begin
        DoneActionEnabled := false;
        BackActionEnabled := true;

        Step1Visible := false;
        Step2Visible := false;
        Step3Visible := false;

        ImportActionVisible := false;
        ImportProfilePackageActionVisible := false;
    end;

    var
        TempProfileImport: Record "Profile Import" temporary;
        FileManagement: Codeunit "File Management";
        ExtensionManagement: Codeunit "Extension Management";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ProfileHelper: Codeunit "Profile Helper";
        DiagnosticsWarningsReportedTxt: Label 'Package scanned successfully with warnings.';
        DiagnosticsInformationalMessagesReportedTxt: Label 'Package scanned successfully with informational messages.';
        ImportProfilesStepTxt: Label 'Import Profiles (%1 of 3)', Comment = '%1 = a number from 1-3';
        SelectProfileToImportTxt: Label 'Select profile package to import';
        ProfilesZipFileNameTxt: Label 'Profiles.zip';
        PackageDoesNotContainAnyProfilesMsg: Label 'The profile package does not contain any profiles.';
        SelectProfileToImportErr: Label 'You must select at least one profile to import.';
        ShowDiagnosticsTxt: Label 'Show diagnostics';
        Step: Option Start,SelectProfilesToImport,Finish;
        BackActionEnabled: Boolean;
        DoneActionEnabled: Boolean;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        ImportActionVisible: Boolean;
        ApplicationName: Text;
        ImportProfilePackageActionVisible: Boolean;
        DiagnosticsNotificationIDTxt: Label 'f942c4ea-6509-4068-9f87-f38520ffffb2', Locked = true;
        Action: Enum "Creation Type";
        ActionStyleExpr: Text;
        ServerFileName: Text;
}
