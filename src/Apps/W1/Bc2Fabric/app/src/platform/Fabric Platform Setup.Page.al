namespace Microsoft.Bc2Fabric;

using Microsoft.Utilities;
using System.Fabric;

#if not PTE
page 150004 "Fabric Platform Setup"
#else
page 50104 "Fabric Platform Setup"
#endif
{
    Caption = 'Fabric Platform Export Setup';
    PageType = Card;
    SourceTable = "Tenant Fabric Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    AboutTitle = 'Connect to Microsoft Fabric';
    AboutText = 'Use this page to connect your environment to Microsoft Fabric, choose which companies and tables to synchronize, and monitor the synchronization.';

    layout
    {
        area(Content)
        {
            group(Destination)
            {
                Caption = 'Fabric Destination';

                field("Fabric Workspace Name"; WorkspaceNameValue)
                {
                    Caption = 'Fabric Workspace Name';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the display name of the selected Microsoft Fabric workspace. Use the assist button to browse available workspaces.';

                    trigger OnAssistEdit()
                    var
                        AdminClient: Codeunit "Fabric Platform Admin Client";
                        CredMgt: Codeunit "Fabric Platform Credential Mgt";
                        TempBuffer: Record "Name/Value Buffer" temporary;
                        LookupPage: Page "Fabric Platform Name Lookup";
                        WorkspaceId: Guid;
                    begin
                        if Rec."Export Enabled" then
                            Error(CannotChangeWhileExportEnabledErr);
                        AdminClient.GetWorkspaces(TempBuffer);
                        if TempBuffer.IsEmpty() then
                            Error(NoWorkspacesFoundErr);
                        LookupPage.SetSource(TempBuffer);
                        LookupPage.LookupMode(true);
                        if LookupPage.RunModal() = Action::LookupOK then begin
                            LookupPage.GetRecord(TempBuffer);
                            if not Evaluate(WorkspaceId, TempBuffer.Value) then
                                Error(WorkspaceIdInvalidErr, TempBuffer.Value);
                            Rec."Fabric Workspace ID" := WorkspaceId;
                            Rec."Fabric Workspace Name" := CopyStr(TempBuffer.Name, 1, MaxStrLen(Rec."Fabric Workspace Name"));
                            Clear(Rec."Fabric Lakehouse ID");
                            Rec.Modify(true);
                            WorkspaceNameValue := CopyStr(Rec."Fabric Workspace Name", 1, MaxStrLen(WorkspaceNameValue));
                            OpenMirroringNameValue := '';
                            CredMgt.SetOpenMirroringDatabaseName(OpenMirroringNameValue);
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field("Fabric Workspace ID"; Rec."Fabric Workspace ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the Microsoft Fabric workspace that receives the exported data.';
                }
                field("Fabric Open Mirroring Name"; OpenMirroringNameValue)
                {
                    Caption = 'Fabric Open Mirroring Name';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the display name of the selected Microsoft Fabric Open Mirroring database. Use the assist button to browse Open Mirroring databases in the selected workspace.';

                    trigger OnAssistEdit()
                    var
                        AdminClient: Codeunit "Fabric Platform Admin Client";
                        CredMgt: Codeunit "Fabric Platform Credential Mgt";
                        TempBuffer: Record "Name/Value Buffer" temporary;
                        LookupPage: Page "Fabric Platform Name Lookup";
                        MirroredDatabaseId: Guid;
                    begin
                        if Rec."Export Enabled" then
                            Error(CannotChangeWhileExportEnabledErr);
                        AdminClient.GetMirroredDatabases(Rec."Fabric Workspace ID", TempBuffer);
                        if TempBuffer.IsEmpty() then
                            Error(NoMirroredDatabasesFoundErr);
                        LookupPage.SetSource(TempBuffer);
                        LookupPage.LookupMode(true);
                        if LookupPage.RunModal() = Action::LookupOK then begin
                            LookupPage.GetRecord(TempBuffer);
                            if not Evaluate(MirroredDatabaseId, TempBuffer.Value) then
                                Error(MirroredDatabaseIdInvalidErr, TempBuffer.Value);
                            Rec."Fabric Lakehouse ID" := MirroredDatabaseId;
                            Rec.Modify(true);
                            OpenMirroringNameValue := CopyStr(TempBuffer.Name, 1, MaxStrLen(OpenMirroringNameValue));
                            CredMgt.SetOpenMirroringDatabaseName(OpenMirroringNameValue);
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field("Fabric Lakehouse ID"; Rec."Fabric Lakehouse ID")
                {
                    Caption = 'Fabric Open Mirroring Database ID';
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the Microsoft Fabric Open Mirroring database that receives the exported data.';
                }
                field("Fabric Data Namespace"; Rec."Fabric Data Namespace")
                {
                    ApplicationArea = All;
                    Editable = NamespaceEditable;
                    ToolTip = 'Specifies the Fabric schema name used for the exported data tables.';
                }
                field("Fabric Logging Namespace"; Rec."Fabric Logging Namespace")
                {
                    ApplicationArea = All;
                    Editable = NamespaceEditable;
                    ToolTip = 'Specifies the Fabric schema name used for the exported logging tables.';
                }
                field("Setup Complete"; Rec."Setup Complete")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies whether the platform setup pipeline completed successfully.';
                }
            }
            group(Options)
            {
                Caption = 'Configuration';

                field("Minutes Between Exports"; Rec."Minutes Between Exports")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the interval, in minutes, between continuous export runs.';

                    trigger OnValidate()
                    begin
                        NotifyValueUsedOnNextRun();
                    end;
                }
                field("Max Consecutive Failed Runs"; Rec."Max Consecutive Failed Runs")
                {
                    ApplicationArea = All;
                    MinValue = 1;
                    MaxValue = 5;
                    ToolTip = 'Specifies how many consecutive failed runs are allowed before the platform stops the export.';

                    trigger OnValidate()
                    begin
                        NotifyValueUsedOnNextRun();
                    end;
                }
                field("Export Enabled"; Rec."Export Enabled")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies whether continuous export is currently enabled.';
                }
            }
            group(Credentials)
            {
                // Temporary: will be replaced by Microsoft first-party app authentication.
                Caption = 'Workspace API Credentials';

                field(ClientId; ClientIdValue)
                {
                    Caption = 'Client ID';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure AD application (client) ID used for delegated workspace and Open Mirroring database browsing.';

                    trigger OnValidate()
                    var
                        CredMgt: Codeunit "Fabric Platform Credential Mgt";
                    begin
                        CredMgt.SetClientId(ClientIdValue);
                        CredMgt.ClearTokenCache();
                        EnableActionEnabled := true;
                        CurrPage.Update(false);
                    end;
                }
                field(ClientSecret; ClientSecretValue)
                {
                    Caption = 'Client Secret';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the Azure AD client secret. Enter a new value to update the stored secret.';

                    trigger OnValidate()
                    var
                        CredMgt: Codeunit "Fabric Platform Credential Mgt";
                    begin
                        if (ClientSecretValue <> '') and (ClientSecretValue <> ClientSecretSetLbl) then begin
                            CredMgt.SetClientSecret(ClientSecretValue);
                            CredMgt.ClearTokenCache();
                            ClientSecretValue := ClientSecretSetLbl;
                            EnableActionEnabled := true;
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field(PrincipalId; PrincipalIdValue)
                {
                    Caption = 'Principal ID';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object ID of the service principal in Azure AD. Used to grant the service principal Contributor access on the Fabric workspace.';

                    trigger OnValidate()
                    var
                        CredMgt: Codeunit "Fabric Platform Credential Mgt";
                    begin
                        CredMgt.SetPrincipalId(PrincipalIdValue);
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part(CompaniesFactBox; "Fabric Companies FactBox")
            {
                ApplicationArea = All;
            }
            part(TablesFactBox; "Fabric Tables FactBox")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Fabric)
            {
                Caption = 'Fabric';

                action(EnableExport)
                {
                    Caption = 'Connect to Fabric';
                    ApplicationArea = All;
                    Enabled = EnableActionEnabled;
                    Image = Setup;
                    ToolTip = 'Connects to Microsoft Fabric using the configured credentials and runs the platform setup pipeline. This is asynchronous; follow progress on Synchronization Overview.';

                    trigger OnAction()
                    var
                        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                    begin
                        FabricPlatformMgt.EnableExport();
                        CurrPage.Update(false);
                    end;
                }
                action(DisableExport)
                {
                    Caption = 'Disconnect from Fabric';
                    ApplicationArea = All;
                    Image = Delete;
                    ToolTip = 'Cancels in-flight runs and removes the platform export resources for this tenant.';

                    trigger OnAction()
                    var
                        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                    begin
                        FabricPlatformMgt.DisableExport();
                        CurrPage.Update(false);
                    end;
                }
                action(TestConnection)
                {
                    Caption = 'Test Connection';
                    ApplicationArea = All;
                    Image = Process;
                    ToolTip = 'Tests the connection to Microsoft Fabric using the configured credentials.';

                    trigger OnAction()
                    var
                        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                    begin
                        FabricPlatformMgt.TestConnection();
                    end;
                }
            }
            action(StartExport)
            {
                Caption = 'Start synchronization';
                ApplicationArea = All;
                Image = Start;
                ToolTip = 'Starts continuous export. This is asynchronous; follow progress on Synchronization Overview.';

                trigger OnAction()
                var
                    FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                begin
                    FabricPlatformMgt.StartExport();
                    CurrPage.Update(false);
                end;
            }
            action(StopExport)
            {
                Caption = 'Stop synchronization';
                ApplicationArea = All;
                Image = Stop;
                ToolTip = 'Cancels any in-flight export run and disables continuous export.';

                trigger OnAction()
                var
                    FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                begin
                    FabricPlatformMgt.StopExport();
                    CurrPage.Update(false);
                end;
            }
            action(AddToWorkspace)
            {
                Caption = 'Add to Workspace';
                ApplicationArea = All;
                Image = UserSetup;
                ToolTip = 'Grants the service principal (Principal ID) Contributor access on the selected Fabric workspace. Run this once after selecting the workspace.';

                trigger OnAction()
                var
                    AdminClient: Codeunit "Fabric Platform Admin Client";
                    CredMgt: Codeunit "Fabric Platform Credential Mgt";
                begin
                    AdminClient.AddServicePrincipalToWorkspace(Rec."Fabric Workspace ID", CredMgt.GetPrincipalId());
                    Message(SPAddedToWorkspaceMsg, Rec."Fabric Workspace Name");
                end;
            }
            action(Refresh)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Refreshes the page with the latest data.';

                trigger OnAction()
                begin
                    SelectLatestVersion();
                    Rec.Get(Rec."Setup ID");
                    SetEditable();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            group(Configuration)
            {
                Caption = 'Configuration';

                action(Tables)
                {
                    Caption = 'Tables';
                    ApplicationArea = All;
                    Image = Table;
                    RunObject = page "Fabric Platform Tables";
                    ToolTip = 'Selects the Business Central tables to export.';
                }
                action(Companies)
                {
                    Caption = 'Companies';
                    ApplicationArea = All;
                    Image = Company;
                    RunObject = page "Fabric Platform Companies";
                    ToolTip = 'Selects the companies to export.';
                }
            }
            action(ConfigPackages)
            {
                Caption = 'Configuration Packages';
                ApplicationArea = All;
                Image = Setup;
                RunObject = page "Fabric Config Packages";
                ToolTip = 'Activates a curated set of tables from a shipped configuration package.';
            }
            group(Monitoring)
            {
                Caption = 'Monitoring';

                action(ExportSummary)
                {
                    Caption = 'Synchronization Overview';
                    ApplicationArea = All;
                    Image = History;
                    RunObject = page "Fabric Platform Export Summary";
                    ToolTip = 'Shows one row per export run with its state and any error.';
                }
                action(ExportDetails)
                {
                    Caption = 'Synchronization Details';
                    ApplicationArea = All;
                    Image = ViewDetails;
                    RunObject = page "Fabric Platform Export Details";
                    ToolTip = 'Shows per-company, per-table export status and watermarks.';
                }
            }
        }
        area(Promoted)
        {
            actionref(StartExport_Promoted; StartExport) { }
            actionref(StopExport_Promoted; StopExport) { }
            actionref(Refresh_Promoted; Refresh) { }
            group(Category_Fabric)
            {
                Caption = 'Fabric';

                actionref(EnableExport_Promoted; EnableExport) { }
                actionref(DisableExport_Promoted; DisableExport) { }
                actionref(TestConnection_Promoted; TestConnection) { }
            }
            group(Category_Configuration)
            {
                Caption = 'Configuration';

                actionref(Tables_Promoted; Tables) { }
                actionref(Companies_Promoted; Companies) { }
            }
            group(Category_Monitoring)
            {
                Caption = 'Monitoring';

                actionref(ExportSummary_Promoted; ExportSummary) { }
                actionref(ExportDetails_Promoted; ExportDetails) { }
            }
        }
    }

    trigger OnOpenPage()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
    begin
        FabricPlatformMgt.EnsureSetup(Rec);
        ClientIdValue := CopyStr(CredMgt.GetClientId(), 1, MaxStrLen(ClientIdValue));
        PrincipalIdValue := CopyStr(CredMgt.GetPrincipalId(), 1, MaxStrLen(PrincipalIdValue));
        OpenMirroringNameValue := CopyStr(CredMgt.GetOpenMirroringDatabaseName(), 1, MaxStrLen(OpenMirroringNameValue));
        WorkspaceNameValue := CopyStr(Rec."Fabric Workspace Name", 1, MaxStrLen(WorkspaceNameValue));
        if CredMgt.IsClientSecretSet() then
            ClientSecretValue := ClientSecretSetLbl;
        SetEditable();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        WorkspaceNameValue := CopyStr(Rec."Fabric Workspace Name", 1, MaxStrLen(WorkspaceNameValue));
        SetEditable();
    end;

    local procedure SetEditable()
    begin
        NamespaceEditable := not Rec."Setup Complete";
        EnableActionEnabled := not Rec."Setup Complete";
    end;

    local procedure NotifyValueUsedOnNextRun()
    begin
        if Rec."Export Enabled" then
            Message(ValuePickedUpOnNextRunMsg);
    end;

    var
        NamespaceEditable: Boolean;
        EnableActionEnabled: Boolean;
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
        CannotChangeWhileExportEnabledErr: Label 'You cannot change the Fabric workspace or Open Mirroring database while export is enabled. Disable export first.';
        SPAddedToWorkspaceMsg: Label 'Service principal added as Contributor to workspace ''%1''.', Comment = '%1 = workspace name';
        ValuePickedUpOnNextRunMsg: Label 'This change will take effect starting with the next export run.';

}
