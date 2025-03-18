// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;


/// <summary>
/// This page shows the database activity monitor setup.
/// </summary>
page 6282 "Database Act. Monitor Setup"
{
    PageType = Document;
    Caption = 'Database Activity Monitor Setup';
    SourceTable = "Database Act. Monitor Setup";
    PromotedActionCategories = 'New, Process, Report, Navigate';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Log All Tables"; "Log All Tables")
                {
                    ApplicationArea = All;
                    Caption = 'Log All Tables';
                    ToolTip = 'Specifies whether to log all tables.';
                    Importance = Promoted;
                }
                field("Emit telemetry"; "Emit telemetry")
                {
                    ApplicationArea = All;
                    Caption = 'Emit Telemetry';
                    ToolTip = 'Specifies whether to emit activity to telemetry.';
                    Importance = Promoted;
                }
                field("Logging context"; Rec."Logging Context")
                {
                    ApplicationArea = All;
                    Caption = 'Logging Context';
                    ToolTip = 'Specifies whether to log only the current session or all sessions.';
                    Importance = Promoted;
                }
                field("Logging Period"; Rec."Logging Period")
                {
                    ApplicationArea = All;
                    Caption = 'Logging Period';
                    ToolTip = 'Specifies the period for logging.';
                    Importance = Promoted;
                }
            }

            group(LogAll)
            {
                Caption = 'Logging';
                Visible = Rec."Log All Tables";

                field("Log Delete"; Rec."Log Delete")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log delete operations.';
                    Importance = Promoted;
                }
                field("Log Insert"; Rec."Log Insert")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log delete operations.';
                    Importance = Promoted;
                }
                field("Log Modify"; Rec."Log Modify")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log delete operations.';
                    Importance = Promoted;
                }
                field("Log Rename"; Rec."Log Rename")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log rename operations.';
                    Importance = Promoted;
                }
            }

            part("Database Act. Monitor Lines"; "Database Act. Monitor Lines")
            {
                ApplicationArea = All;
                Caption = 'Logging for tables';
                Visible = not Rec."Log All Tables";
            }
        }
    }

    trigger OnOpenPage()
    begin
        // TODO: Log uptake


        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
