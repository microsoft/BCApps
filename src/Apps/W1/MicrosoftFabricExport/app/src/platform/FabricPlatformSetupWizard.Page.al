namespace Microsoft.FabricExport;

using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Fabric;

page 9118 "Fabric Platform Setup Wizard"
{
    Caption = 'Set Up Microsoft Fabric Export';
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
                    ApplicationArea = All;
                    Caption = 'This guide connects your environment to Microsoft Fabric: enter API credentials, choose a workspace and Open Mirroring database, grant access, connect, and select the companies and tables to synchronize.';
                }
            }
            group(Credentials)
            {
                Visible = Step = 2;
                Caption = 'Workspace API Credentials';

                field(ClientId; ClientIdValue)
                {
                    Caption = 'Client ID';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the Azure AD application (client) ID used for delegated workspace and Open Mirroring database browsing.';

                    trigger OnValidate()
                    begin
                        CredMgt.SetClientId(ClientIdValue);
                        CredMgt.ClearTokenCache();
                    end;
                }
                field(ClientSecret; ClientSecretValue)
                {
                    Caption = 'Client Secret';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the Azure AD client secret. Enter a new value to update the stored secret.';

                    trigger OnValidate()
                    begin
                        if (ClientSecretValue <> '') and (ClientSecretValue <> ClientSecretSetLbl) then begin
                            CredMgt.SetClientSecret(ClientSecretValue);
                            CredMgt.ClearTokenCache();
                            ClientSecretValue := ClientSecretSetLbl;
                        end;
                    end;
                }
                field(PrincipalId; PrincipalIdValue)
                {
                    Caption = 'Principal ID';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object ID of the service principal in Azure AD. Used to grant the service principal Contributor access on the Fabric workspace.';

                    trigger OnValidate()
                    begin
                        CredMgt.SetPrincipalId(PrincipalIdValue);
                    end;
                }
            }
            group(Workspace)
            {
                Visible = Step = 3;
                Caption = 'Fabric Workspace';

                field("Fabric Workspace Name"; WorkspaceNameValue)
                {
                    Caption = 'Fabric Workspace Name';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the display name of the selected Microsoft Fabric workspace. Use the assist button to browse available workspaces.';

                    trigger OnAssistEdit()
                    var
                        AdminClient: Codeunit "Fabric Platform Admin Client";
                        TempBuffer: Record "Name/Value Buffer" temporary;
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
                            Rec."Fabric Workspace ID" := WorkspaceId;
                            Rec."Fabric Workspace Name" := CopyStr(TempBuffer.Name, 1, MaxStrLen(Rec."Fabric Workspace Name"));
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
                    ApplicationArea = All;
                    Caption = 'Choose Add to workspace to grant the service principal (Principal ID) Contributor access on the selected Fabric workspace. Run this once per workspace.';
                }
            }
            group(OpenMirroring)
            {
                Visible = Step = 5;
                Caption = 'Fabric Open Mirroring Database';

                field("Fabric Open Mirroring Name"; OpenMirroringNameValue)
                {
                    Caption = 'Fabric Open Mirroring Name';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the display name of the selected Microsoft Fabric Open Mirroring database. Use the assist button to browse Open Mirroring databases in the selected workspace.';

                    trigger OnAssistEdit()
                    var
                        AdminClient: Codeunit "Fabric Platform Admin Client";
                        TempBuffer: Record "Name/Value Buffer" temporary;
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
                            Rec."Fabric Lakehouse ID" := MirroredDatabaseId;
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
                    ApplicationArea = All;
                    ToolTip = 'Specifies the interval, in minutes, between continuous export runs.';
                }
                label(ConnectText)
                {
                    ApplicationArea = All;
                    Caption = 'Choose Connect to Fabric to run the platform setup pipeline. This is asynchronous; follow progress on Fabric Synchronization Overview after finishing this guide.';
                }
            }
            group(Companies)
            {
                Visible = Step = 7;
                Caption = 'Companies';

                label(CompaniesText)
                {
                    ApplicationArea = All;
                    Caption = 'Choose Select companies to add the companies whose data you want to send to Microsoft Fabric.';
                }
            }
            group(Tables)
            {
                Visible = Step = 8;
                Caption = 'Tables';

                label(TablesText)
                {
                    ApplicationArea = All;
                    Caption = 'Choose Select tables to add the Business Central tables you want to send to Microsoft Fabric.';
                }
            }
            group(Finish)
            {
                Visible = Step = 9;
                Caption = 'All Set';

                label(FinishText)
                {
                    ApplicationArea = All;
                    Caption = 'Your Fabric connection is configured. Choose Finish to start synchronization, or start it later from the Fabric Platform Setup page.';
                }
                field("Export Enabled"; Rec."Export Enabled")
                {
                    ApplicationArea = All;
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
                ToolTip = 'Grants the service principal (Principal ID) Contributor access on the selected Fabric workspace.';

                trigger OnAction()
                var
                    AdminClient: Codeunit "Fabric Platform Admin Client";
                begin
                    AdminClient.AddServicePrincipalToWorkspace(Rec."Fabric Workspace ID", CredMgt.GetPrincipalId());
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
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.EnsureSetup(Rec);
        ClientIdValue := CopyStr(CredMgt.GetClientId(), 1, MaxStrLen(ClientIdValue));
        PrincipalIdValue := CopyStr(CredMgt.GetPrincipalId(), 1, MaxStrLen(PrincipalIdValue));
        OpenMirroringNameValue := CopyStr(CredMgt.GetOpenMirroringDatabaseName(), 1, MaxStrLen(OpenMirroringNameValue));
        WorkspaceNameValue := CopyStr(Rec."Fabric Workspace Name", 1, MaxStrLen(WorkspaceNameValue));
        if CredMgt.IsClientSecretSet() then
            ClientSecretValue := ClientSecretSetLbl;
        Step := 1;
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
        ErrInfo.Message := FabricDataInvalidErr;
        ErrInfo.DetailedMessage := DetailedMessage;
        ErrInfo.DataClassification := DataClassification::SystemMetadata;
        ErrInfo.ErrorType := ErrorType::Internal;
    end;

    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        // Step: 1=Introduction 2=Credentials 3=Workspace 4=WorkspaceAccess 5=OpenMirroring 6=Connect 7=Companies 8=Tables 9=Finish
        Step: Integer;
        ClientIdValue: Text[250];
        PrincipalIdValue: Text[250];
        OpenMirroringNameValue: Text[250];
        WorkspaceNameValue: Text[250];
        [NonDebuggable]
        ClientSecretValue: Text[250];
        ClientSecretSetLbl: Label '*** secret stored ***', Locked = true;
        NoWorkspacesFoundErr: Label 'No workspaces found. Verify the Client ID and Client Secret.';
        NoMirroredDatabasesFoundErr: Label 'No Open Mirroring databases found in the selected workspace.';
        WorkspaceIdInvalidErr: Label 'Fabric returned an invalid workspace ID: %1.', Comment = '%1 = workspace ID';
        MirroredDatabaseIdInvalidErr: Label 'Fabric returned an invalid Open Mirroring database ID: %1.', Comment = '%1 = Open Mirroring database ID';
        FabricDataInvalidErr: Label 'Microsoft Fabric returned unexpected data. Contact your administrator or Microsoft support if this continues.';
        SPAddedToWorkspaceMsg: Label 'Service principal added as Contributor to workspace ''%1''.', Comment = '%1 = workspace name';
}
