namespace Microsoft.FabricExport;

using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Fabric;

page 48519 "Fabric Platform Setup Wizard"
{
    Caption = 'Set Up Microsoft Fabric Mirroring (Preview)';
    PageType = NavigatePage;
    SourceTable = "Tenant Fabric Setup";
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Introduction)
            {
                Visible = Step = 1;
                Caption = 'Welcome';

                label(IntroText)
                {
                    Caption = 'This guide connects your environment to Microsoft Fabric: set up authentication, choose a workspace and Open Mirroring database, grant access, connect, and select the companies and tables to synchronize.';
                }
            }
            group(Credentials)
            {
                Visible = Step = 2;
                Caption = 'Authentication';

                group(FirstPartyAuthentication)
                {
                    ShowCaption = false;

                    label(AuthenticationText)
                    {
                        Caption = 'The Microsoft Business Central Fabric Export application is used by default.';
                    }
                }
                field(UseCustomApp; UseCustomAppValue)
                {
                    Caption = 'Use custom app registration';
                    Editable = CustomAppSelectionEditable;
                    Visible = false;
                    ToolTip = 'Specifies whether to authenticate with your own Microsoft Entra app registration instead of the Microsoft Business Central Fabric Export application. Switching this off deletes the stored client secret.';

                    trigger OnValidate()
                    begin
                        CredMgt.SetCustomAppEnabled(UseCustomAppValue);
                        if not UseCustomAppValue then
                            Clear(ClientSecretValue);
                        CredMgt.ClearTokenCache();
                        PrincipalIdValue := CopyStr(CredMgt.GetPrincipalId(), 1, MaxStrLen(PrincipalIdValue));
                        UpdateControls();
                        CurrPage.Update(false);
                    end;
                }
                field(PrincipalId; PrincipalIdValue)
                {
                    Caption = 'Principal ID';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the object ID of the Microsoft Entra enterprise application used to access the Fabric workspace. This is not the application (client) ID.';

                    trigger OnValidate()
                    begin
                        CredMgt.SetPrincipalId(PrincipalIdValue);
                        UpdateControls();
                        CurrPage.Update(false);
                    end;
                }
                group(PrincipalIdGuidance)
                {
                    ShowCaption = false;
                    Visible = PrincipalIdMissing;

                    label(PrincipalIdInstructions)
                    {
                        Caption = 'Principal ID is required to grant the application access to your Microsoft Fabric workspace. Ask your Microsoft Entra administrator to add the enterprise application to your tenant and provide its ID.';
                    }
                    field(PrincipalIdSetupInstructions; PrincipalIdSetupInstructionsLbl)
                    {
                        Caption = 'How to set up';
                        ToolTip = 'Opens instructions for adding the enterprise application to Microsoft Entra and finding its Object ID.';
                        DrillDown = true;
                        Editable = false;
                        ShowCaption = false;
                        Style = StandardAccent;
                        StyleExpr = true;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(PrincipalIdSetupHelpUrl);
                        end;
                    }
                }
                group(CustomAppCredentials)
                {
                    ShowCaption = false;
                    Visible = UseCustomAppValue;

                    field(ClientId; ClientIdValue)
                    {
                        Caption = 'Client ID';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the Microsoft Entra application (client) ID used for delegated workspace and Open Mirroring database browsing.';

                        trigger OnValidate()
                        begin
                            CredMgt.SetClientId(ClientIdValue);
                            CredMgt.ClearTokenCache();
                        end;
                    }
                    field(ClientSecret; ClientSecretValue)
                    {
                        Caption = 'Client Secret';
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the client secret of the Microsoft Entra application. Enter a new value to update the stored secret.';

                        trigger OnValidate()
                        begin
                            if (ClientSecretValue <> '') and (ClientSecretValue <> ClientSecretSetLbl) then begin
                                CredMgt.SetClientSecret(ClientSecretValue);
                                CredMgt.ClearTokenCache();
                                ClientSecretValue := ClientSecretSetLbl;
                            end;
                        end;
                    }
                }
            }
            group(Workspace)
            {
                Visible = Step = 3;
                Caption = 'Fabric Workspace';

                field("Fabric Workspace Name"; WorkspaceNameValue)
                {
                    Caption = 'Fabric Workspace Name';
                    Editable = false;
                    ToolTip = 'Specifies the display name of the selected Microsoft Fabric workspace. Use the assist button to browse available workspaces.';

                    trigger OnAssistEdit()
                    var
                        TempBuffer: Record "Name/Value Buffer" temporary;
                        AdminClient: Codeunit "Fabric Platform Admin Client";
                        LookupPage: Page "Fabric Platform Name Lookup";
                        WorkspaceId: Guid;
                    begin
                        AdminClient.GetWorkspaces(TempBuffer);
                        if TempBuffer.IsEmpty() then
                            Error(NoWorkspacesFoundErr);
                        LookupPage.SetSource(TempBuffer);
                        LookupPage.LookupMode(true);
                        if LookupPage.RunModal() = Action::LookupOK then begin
                            LookupPage.GetRecord(TempBuffer);
                            if not Evaluate(WorkspaceId, TempBuffer.Value) then
                                Error(CreateFabricDataErrorInfo(StrSubstNo(WorkspaceIdInvalidErr, TempBuffer.Value)));
                            Rec.Validate("Fabric Workspace ID", WorkspaceId);
                            Rec.Validate("Fabric Workspace Name", CopyStr(TempBuffer.Name, 1, MaxStrLen(Rec."Fabric Workspace Name")));
                            Clear(Rec."Fabric Lakehouse ID");
                            Rec.Modify(true);
                            WorkspaceNameValue := CopyStr(Rec."Fabric Workspace Name", 1, MaxStrLen(WorkspaceNameValue));
                            OpenMirroringNameValue := '';
                            CredMgt.SetOpenMirroringDatabaseName(OpenMirroringNameValue);
                        end;
                    end;
                }
            }
            group(WorkspaceAccess)
            {
                Visible = Step = 4;
                Caption = 'Grant Workspace Access';

                label(WorkspaceAccessText)
                {
                    Caption = 'Choose Add to workspace to grant the service principal Contributor access on the selected Fabric workspace. Run this once per workspace.';
                }
            }
            group(OpenMirroring)
            {
                Visible = Step = 5;
                Caption = 'Fabric Open Mirroring Database';

                field("Fabric Open Mirroring Name"; OpenMirroringNameValue)
                {
                    Caption = 'Fabric Open Mirroring Name';
                    Editable = false;
                    ToolTip = 'Specifies the display name of the selected Microsoft Fabric Open Mirroring database. Use the assist button to browse Open Mirroring databases in the selected workspace.';

                    trigger OnAssistEdit()
                    var
                        TempBuffer: Record "Name/Value Buffer" temporary;
                        AdminClient: Codeunit "Fabric Platform Admin Client";
                        LookupPage: Page "Fabric Platform Name Lookup";
                        MirroredDatabaseId: Guid;
                    begin
                        AdminClient.GetMirroredDatabases(Rec."Fabric Workspace ID", TempBuffer);
                        if TempBuffer.IsEmpty() then
                            Error(NoMirroredDatabasesFoundErr);
                        LookupPage.SetSource(TempBuffer);
                        LookupPage.LookupMode(true);
                        if LookupPage.RunModal() = Action::LookupOK then begin
                            LookupPage.GetRecord(TempBuffer);
                            if not Evaluate(MirroredDatabaseId, TempBuffer.Value) then
                                Error(CreateFabricDataErrorInfo(StrSubstNo(MirroredDatabaseIdInvalidErr, TempBuffer.Value)));
                            Rec.Validate("Fabric Lakehouse ID", MirroredDatabaseId);
                            Rec.Modify(true);
                            OpenMirroringNameValue := CopyStr(TempBuffer.Name, 1, MaxStrLen(OpenMirroringNameValue));
                            CredMgt.SetOpenMirroringDatabaseName(OpenMirroringNameValue);
                        end;
                    end;
                }
            }
            group(Connect)
            {
                Visible = Step = 6;
                Caption = 'Synchronization Options';

                field("Minutes Between Exports"; Rec."Minutes Between Exports")
                {
                    ToolTip = 'Specifies the interval, in minutes, between continuous export runs.';
                }
                label(ConnectText)
                {
                    Caption = 'Choose Connect to Fabric to run the platform setup pipeline. This is asynchronous; follow progress on Fabric Synchronization Overview after finishing this guide.';
                }
            }
            group(Companies)
            {
                Visible = Step = 7;
                Caption = 'Companies';

                label(CompaniesText)
                {
                    Caption = 'Choose Select companies to add the companies whose data you want to send to Microsoft Fabric.';
                }
            }
            group(Tables)
            {
                Visible = Step = 8;
                Caption = 'Tables';

                label(TablesText)
                {
                    Caption = 'Choose Select tables to add the Business Central tables you want to send to Microsoft Fabric.';
                }
            }
            group(Finish)
            {
                Visible = Step = 9;
                Caption = 'All Set';

                label(FinishText)
                {
                    Caption = 'Your Fabric connection is configured. Choose Finish to start synchronization, or start it later from the Fabric Platform Setup page.';
                }
                field("Export Enabled"; Rec."Export Enabled")
                {
                    Editable = false;
                    ToolTip = 'Specifies whether continuous export is currently enabled.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddToWorkspace)
            {
                Caption = 'Add to workspace';
                ApplicationArea = All;
                Visible = Step = 4;
                Image = UserSetup;
                InFooterBar = true;
                ToolTip = 'Grants the service principal Contributor access on the selected Fabric workspace.';

                trigger OnAction()
                var
                    AdminClient: Codeunit "Fabric Platform Admin Client";
                begin
                    AdminClient.AddConnectionToWorkspace(Rec."Fabric Workspace ID");
                    Message(SPAddedToWorkspaceMsg, Rec."Fabric Workspace Name");
                end;
            }
            action(ConnectToFabric)
            {
                Caption = 'Connect to Fabric';
                ApplicationArea = All;
                Visible = Step = 6;
                Image = Setup;
                InFooterBar = true;
                ToolTip = 'Connects to Microsoft Fabric using the configured credentials and runs the platform setup pipeline.';

                trigger OnAction()
                var
                    FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                begin
                    FabricPlatformMgt.EnableExport();
                    CurrPage.Update(false);
                end;
            }
            action(SelectCompanies)
            {
                Caption = 'Select companies';
                ApplicationArea = All;
                Visible = Step = 7;
                Image = Company;
                InFooterBar = true;
                RunObject = page "Fabric Platform Companies";
                ToolTip = 'Opens the page to select the companies to export.';
            }
            action(SelectTables)
            {
                Caption = 'Select tables';
                ApplicationArea = All;
                Visible = Step = 8;
                Image = Table;
                InFooterBar = true;
                RunObject = page "Fabric Platform Tables";
                ToolTip = 'Opens the page to select the Business Central tables to export.';
            }
            action(ActionBack)
            {
                Caption = 'Back';
                ApplicationArea = All;
                Enabled = Step > 1;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Step -= 1;
                    CurrPage.Update(false);
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next';
                ApplicationArea = All;
                Visible = Step < 9;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Step += 1;
                    CurrPage.Update(false);
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish';
                ApplicationArea = All;
                Visible = Step = 9;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishWizard();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.EnsureSetup(Rec);
        PrincipalIdSetupHelpUrl := AdminClient.GetPrincipalIdSetupHelpUrl();
        ClientIdValue := CopyStr(CredMgt.GetCustomClientId(), 1, MaxStrLen(ClientIdValue));
        UseCustomAppValue := CredMgt.IsCustomAppEnabled();
        PrincipalIdValue := CopyStr(CredMgt.GetPrincipalId(), 1, MaxStrLen(PrincipalIdValue));
        OpenMirroringNameValue := CopyStr(CredMgt.GetOpenMirroringDatabaseName(), 1, MaxStrLen(OpenMirroringNameValue));
        WorkspaceNameValue := CopyStr(Rec."Fabric Workspace Name", 1, MaxStrLen(WorkspaceNameValue));
        if CredMgt.IsClientSecretSet() then
            ClientSecretValue := ClientSecretSetLbl;
        Step := 1;
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        CustomAppSelectionEditable := not Rec."Export Enabled";
        PrincipalIdMissing := PrincipalIdValue.Trim() = '';
    end;

    local procedure FinishWizard()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Fabric Platform Setup Wizard");
        CurrPage.Close();
    end;

    local procedure CreateFabricDataErrorInfo(DetailedMessage: Text) ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(FabricDataInvalidErr);
        ErrInfo.DetailedMessage(DetailedMessage);
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
    end;

    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        // Step: 1=Introduction 2=Credentials 3=Workspace 4=WorkspaceAccess 5=OpenMirroring 6=Connect 7=Companies 8=Tables 9=Finish
        Step: Integer;
        UseCustomAppValue: Boolean;
        CustomAppSelectionEditable: Boolean;
        PrincipalIdMissing: Boolean;
        ClientIdValue: Text[250];
        PrincipalIdValue: Text[250];
        PrincipalIdSetupHelpUrl: Text;
        OpenMirroringNameValue: Text[250];
        WorkspaceNameValue: Text[250];
        [NonDebuggable]
        ClientSecretValue: Text[250];
        ClientSecretSetLbl: Label '*** secret stored ***', Locked = true;
        PrincipalIdSetupInstructionsLbl: Label 'Read setup instructions';
        NoWorkspacesFoundErr: Label 'No Microsoft Fabric workspaces were found. Ask your administrator to check that you have access to a workspace.';
        NoMirroredDatabasesFoundErr: Label 'No Open Mirroring databases found in the selected workspace.';
        WorkspaceIdInvalidErr: Label 'Fabric returned an invalid workspace ID: %1.', Comment = '%1 = workspace ID';
        MirroredDatabaseIdInvalidErr: Label 'Fabric returned an invalid Open Mirroring database ID: %1.', Comment = '%1 = Open Mirroring database ID';
        FabricDataInvalidErr: Label 'Microsoft Fabric returned unexpected data. Contact your administrator or Microsoft support if this continues.';
        SPAddedToWorkspaceMsg: Label 'Service principal has Contributor access or higher on workspace ''%1''.', Comment = '%1 = workspace name';
}
