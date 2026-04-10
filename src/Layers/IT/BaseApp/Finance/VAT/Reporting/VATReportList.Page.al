// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Attachment;

/// <summary>
/// Displays a list view of all VAT returns with filtering and navigation capabilities.
/// Provides read-only access to VAT report headers with status tracking and card navigation.
/// </summary>
page 744 "VAT Report List"
{
    ApplicationArea = VAT;
    Caption = 'VAT Reports';
    CardPageID = "VAT Report";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Header";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Report Config. Code"; Rec."VAT Report Config. Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the appropriate configuration code.';
                }
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = VAT;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the start date of the report period for the VAT report.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the end date of the report period for the VAT report.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the status of the VAT report.';
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
#pragma warning disable AL0603
                SubPageLink = "Table ID" = const(Database::"VAT Report Header"), "No." = field("No."), "VAT Report Config. Code" = field("VAT Report Config. Code");
#pragma warning restore AL0603            
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = VAT;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"VAT Report", Rec);
                    end;
                }
            }
            action("Report Setup")
            {
                ApplicationArea = VAT;
                Caption = 'Report Setup';
                Image = Setup;
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
                Visible = false;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Report Setup_Promoted"; "Report Setup")
                {
                }
            }
        }
    }
}
