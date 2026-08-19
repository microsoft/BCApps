namespace Microsoft.Bc2Fabric;

using System.Fabric;

page 150004 "Fabric Platform Setup"
{
    Caption = 'Fabric Platform Export Setup';
    PageType = Card;
    SourceTable = "Tenant Fabric Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Destination)
            {
                Caption = 'Fabric Destination';

                field("Fabric Workspace ID"; Rec."Fabric Workspace ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Microsoft Fabric workspace that receives the exported data.';
                }
                field("Fabric Workspace Name"; Rec."Fabric Workspace Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display name of the selected Microsoft Fabric workspace.';
                }
                field("Fabric Lakehouse ID"; Rec."Fabric Lakehouse ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Microsoft Fabric lakehouse that receives the exported data.';
                }
                field("Fabric Data Namespace"; Rec."Fabric Data Namespace")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Fabric schema name used for the exported data tables.';
                }
                field("Fabric Logging Namespace"; Rec."Fabric Logging Namespace")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Fabric schema name used for the exported logging tables.';
                }
            }
            group(Options)
            {
                Caption = 'Export Options';

                field("Minutes Between Exports"; Rec."Minutes Between Exports")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the interval, in minutes, between continuous export runs.';
                }
                field("Max Consecutive Failed Runs"; Rec."Max Consecutive Failed Runs")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many consecutive failed runs are allowed before the platform stops the export.';
                }
            }
            group(Status)
            {
                Caption = 'Status';

                field("Setup Complete"; Rec."Setup Complete")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies whether the platform setup pipeline completed successfully.';
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
            action(EnableExport)
            {
                Caption = 'Enable';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Runs the platform setup pipeline using Microsoft first-party authentication. This is asynchronous; follow progress on Export Summary.';

                trigger OnAction()
                var
                    FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                begin
                    FabricPlatformMgt.EnableExport();
                    CurrPage.Update(false);
                end;
            }
            action(StartExport)
            {
                Caption = 'Start';
                ApplicationArea = All;
                Image = Start;
                ToolTip = 'Starts continuous export. This is asynchronous; follow progress on Export Summary.';

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
                Caption = 'Stop';
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
            action(DisableExport)
            {
                Caption = 'Disable';
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
        }
        area(Navigation)
        {
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
            action(ConfigPackages)
            {
                Caption = 'Configuration Packages';
                ApplicationArea = All;
                Image = Setup;
                RunObject = page "Fabric Config Packages";
                ToolTip = 'Activates a curated set of tables from a shipped configuration package.';
            }
            action(ExportSummary)
            {
                Caption = 'Export Summary';
                ApplicationArea = All;
                Image = History;
                RunObject = page "Fabric Platform Export Summary";
                ToolTip = 'Shows one row per export run with its state and any error.';
            }
            action(ExportDetails)
            {
                Caption = 'Export Details';
                ApplicationArea = All;
                Image = ViewDetails;
                RunObject = page "Fabric Platform Export Details";
                ToolTip = 'Shows per-company, per-table export status and watermarks.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EnableExport_Promoted; EnableExport) { }
                actionref(StartExport_Promoted; StartExport) { }
                actionref(StopExport_Promoted; StopExport) { }
                actionref(DisableExport_Promoted; DisableExport) { }
            }
        }
    }

    trigger OnOpenPage()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.EnsureSetup(Rec);
    end;
}
