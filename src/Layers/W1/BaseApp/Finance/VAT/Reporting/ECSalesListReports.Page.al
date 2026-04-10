// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Displays list view of all EC Sales List reports with status tracking and submission management.
/// Provides read-only access to ECSL report headers with filtering by EC Sales List configuration.
/// </summary>
page 323 "EC Sales List Reports"
{
    ApplicationArea = BasicEU;
    Caption = 'EC Sales List Reports';
    CardPageID = "ECSL Report";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Header";
    SourceTableView = where("VAT Report Config. Code" = filter("EC Sales List"));
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = BasicEU;
                }
                field("VAT Report Config. Code"; Rec."VAT Report Config. Code")
                {
                    ApplicationArea = BasicEU;
                    Visible = false;
                }
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies if you want to create a new VAT report, or if you want to change a previously submitted report.';
                    Visible = false;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = BasicEU;
                    Visible = false;
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the last date of the EC sales list report.';
                    Visible = false;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = BasicEU;
                    Visible = false;
                }
                field("Original Report No."; Rec."Original Report No.")
                {
                    ApplicationArea = BasicEU;
                    Visible = false;
                }
                field("Period Type"; Rec."Period Type")
                {
                    ApplicationArea = BasicEU;
                }
                field("Period No."; Rec."Period No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the EC sales list reporting period to use.';
                }
                field("Period Year"; Rec."Period Year")
                {
                    ApplicationArea = BasicEU;
                }
                field("Message Id"; Rec."Message Id")
                {
                    ApplicationArea = BasicEU;
                    Visible = false;
                }
                field("Statement Template Name"; Rec."Statement Template Name")
                {
                    ApplicationArea = BasicEU;
                    Visible = false;
                }
                field("Statement Name"; Rec."Statement Name")
                {
                    ApplicationArea = BasicEU;
                    Visible = false;
                }
                field("VAT Report Version"; Rec."VAT Report Version")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the version of the VAT report.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the status of the report, such as Open or Submitted. ';
                }
                field("Submitted By"; SubmittedBy)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Submitted By';
                    ToolTip = 'Specifies the name of the person who submitted the report. ';
                }
                field("Submitted Date"; SubmittedDate)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Submitted Date';
                    ToolTip = 'Specifies the date when the report was submitted. ';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        VATReportArchive: Record "VAT Report Archive";
    begin
        if VATReportArchive.Get(Rec."VAT Report Type", Rec."No.") then begin
            SubmittedBy := VATReportArchive."Submitted By";
            SubmittedDate := VATReportArchive."Submittion Date";
        end;
    end;

    var
        SubmittedBy: Code[50];
        SubmittedDate: Date;
}

