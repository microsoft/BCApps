// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

#pragma warning disable AS0030
/// <summary>
/// Displays list view of all EC Sales List reports with status tracking and submission management.
/// Provides read-only access to ECSL report headers with filtering by EC Sales List configuration.
/// </summary>
page 323 "EC Sales List Reports"
#pragma warning restore AS0030
{
    ApplicationArea = VAT;
    Caption = 'ECSL Report List';
    CardPageID = "ECSL Report";
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Header";
    SourceTableView = where("VAT Report Config. Code" = filter(VIES));
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Report Config. Code"; Rec."VAT Report Config. Code")
                {
                    ApplicationArea = VAT;
                    Visible = false;
                }
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if you want to create a new VAT report, or if you want to change a previously submitted report.';
                    Visible = false;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = VAT;
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the last date of the EC sales list report.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the status of the report.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = VAT;
                }
                field("Original Report No."; Rec."Original Report No.")
                {
                    ApplicationArea = VAT;
                }
                field("Report Period Type"; Rec."Report Period Type")
                {
                    ApplicationArea = VAT;
                }
                field("Report Period No."; Rec."Report Period No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the EC sales list reporting period to use.';
                }
                field("Report Year"; Rec."Report Year")
                {
                    ApplicationArea = VAT;
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
                action(Card)
                {
                    ApplicationArea = VAT;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the ECSL report.';

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
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Report Setup_Promoted"; "Report Setup")
                {
                }
            }
        }
    }
}

