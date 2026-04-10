// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Attachment;
using System.Telemetry;

/// <summary>
/// Primary interface for creating, managing, and submitting VAT returns to tax authorities.
/// Provides comprehensive workflow management from line suggestion through submission and response handling.
/// </summary>
page 740 "VAT Report"
{
    Caption = 'VAT Report';
    PageType = Document;
    SourceTable = "VAT Report Header";
    SourceTableView = where("VAT Report Config. Code" = const(VIES));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT report is a standard report, or if it is related to a previously submitted VAT report.';
                }
                field("Trade Type"; Rec."Trade Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the trade, such as sales.';
                }
                field("EU Goods/Services"; Rec."EU Goods/Services")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what types of transactions the report covers, such as goods or services.';
                }
                field("Report Period Type"; Rec."Report Period Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reporting period for the VAT report.';
                }
                field("Report Period No."; Rec."Report Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Indicates the VAT period.';
                }
                field("Report Year"; Rec."Report Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year that the VAT report covers.';
                }
                field("Processing Date"; Rec."Processing Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the VAT report was created.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the report period for the VAT report.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the report period for the VAT report.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the VAT report.';
                }
                field("Amounts in Add. Rep. Currency"; Rec."Amounts in Add. Rep. Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Original Report No."; Rec."Original Report No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Test Export"; Rec."Test Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to test the export file first. The report must have the Status Open in order to select the Test Export check box.';
                }
                field(Notice; Rec.Notice)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this is a nil report (Anzeige), indicating there are no EU transactions to report for this period.';
                }
                field(Revocation; Rec.Revocation)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this report revokes a previously submitted VIES report for the same period (Widerruf).';
                }
                field("Total Base"; Rec."Total Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated sum of the base amount of the exported lines.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated total amount of VAT, in euros.';
                }
                field("Total Number of Supplies"; Rec."Total Number of Supplies")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of G/L transactions that make up the Total Amount.';
                }
            }
            group(Company)
            {
                Caption = 'Company';
                Visible = false;
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company name that is associated with the VAT report.';
                }
                field("Company Address"; Rec."Company Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the company associated with the VAT report.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the company submitting the VAT report.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the company submitting the VAT report.';
                }
                field("Tax Office ID"; Rec."Tax Office ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Tax Office ID of the company submitting the VAT report.';
                }
            }
            group("Sign-off")
            {
                Caption = 'Sign-off';
                field("Sign-off Place"; Rec."Sign-off Place")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location where the VAT report has been signed off.';
                }
                field("Sign-off Date"; Rec."Sign-off Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the VAT report has been signed off.';
                }
                field("Signed by Employee No."; Rec."Signed by Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the employee who signed the VAT report.';
                }
                field("Created by Employee No."; Rec."Created by Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the employee who created the VAT report.';
                }
            }
            part(VATReportLines; "VAT Report Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "VAT Report No." = field("No.");
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"VAT Report Header"),
                              "No." = field("No."),
#pragma warning disable AL0603
                              "VAT Report Config. Code" = field("VAT Report Config. Code");
#pragma warning restore AL0603
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SuggestLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Lines';
                    Image = SuggestGrid;
                    ToolTip = 'Suggest Tax lines.';

                    trigger OnAction()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        VatReportTok: Label 'DACH VAT Report', Locked = true;
                    begin
                        FeatureTelemetry.LogUptake('0001Q0C', VatReportTok, Enum::"Feature Uptake Status"::"Used");
                        VATReportMediator.GetLines(Rec);
                        FeatureTelemetry.LogUsage('0001Q0D', VatReportTok, 'VAT report generated');
                    end;
                }
                action("Co&rrect Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&rrect Lines';
                    Image = SuggestLines;

                    trigger OnAction()
                    begin
                        VATReportMediator.CorrectLines(Rec);
                    end;
                }
                separator(Action23)
                {
                }
                action("&Release")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the Tax report to indicate that it has been printed or exported. The status then changes to Released.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Release(Rec);
                    end;
                }
                action("Mark as Su&bmitted")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark as Su&bmitted';
                    Image = Approve;
                    ToolTip = 'Mark the lines for submission to the Tax authorities.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Submit(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the Tax report to indicate that it must be printed or exported again, for example because it has been corrected.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                    end;
                }
                separator(Action26)
                {
                }
                action("&Export")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export';
                    Image = Export;
                    ToolTip = 'Export the Tax report.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Export(Rec);
                    end;
                }
#if not CLEAN28
                action(ExportLegacy)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export (Legacy)';
                    Image = Export;
                    ToolTip = 'Export the Tax report using the legacy report format.';
                    Visible = false;
                    ObsoleteReason = 'This action is used to run legacy report 11008 "Export VIES Report".';
                    ObsoleteState = Pending;
                    ObsoleteTag = '28.0';

                    trigger OnAction()
                    begin
                        VATReportMediator.ExportLegacy(Rec);
                    end;
                }
#endif
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(SuggestLines_Promoted; SuggestLines)
                {
                }
                actionref("Co&rrect Lines_Promoted"; "Co&rrect Lines")
                {
                }
                group(Category_Release)
                {
                    Caption = 'Release';
                    ShowAs = SplitButton;

                    actionref("&Release_Promoted"; "&Release")
                    {
                    }
                    actionref("Re&open_Promoted"; "Re&open")
                    {
                    }
                }
                actionref("Mark as Su&bmitted_Promoted"; "Mark as Su&bmitted")
                {
                }
                actionref("&Export_Promoted"; "&Export")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'VAT Settlement', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }


    var
        VATReportMediator: Codeunit "VAT Report Mediator";
}
