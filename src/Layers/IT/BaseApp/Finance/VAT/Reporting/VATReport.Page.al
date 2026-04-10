// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Attachment;

/// <summary>
/// Primary interface for creating, managing, and submitting VAT returns to tax authorities.
/// Provides comprehensive workflow management from line suggestion through submission and response handling.
/// </summary>
page 740 "VAT Report"
{
    Caption = 'VAT Report';
    PageType = Document;
    SourceTable = "VAT Report Header";

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
                field("VAT Report Config. Code"; Rec."VAT Report Config. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the appropriate configuration code.';

                    trigger OnValidate()
                    begin
                        ReportPrintable := not Rec.isDatifattura();
                    end;
                }
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT report is a standard report, or if it is related to a previously submitted VAT report.';
                }
                field("Original Report No."; Rec."Original Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original VAT report if the VAT Report Type field is set to a value other than Standard.';
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
                field("Tax Auth. Receipt No."; Rec."Tax Auth. Receipt No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the receipt number that you received from the tax authorities when you submitted the VAT transactions report.';
                }
                field("Tax Auth. Document No."; Rec."Tax Auth. Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number that is provided by the tax authority after you submit a VAT Data transmission.';
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
                    ToolTip = 'Specifies whether the amounts are in the additional reporting currency.';
                }
                field("Country/Region Filter"; Rec."Country/Region Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region filter for the report.';
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
                    Image = SuggestLines;
                    ToolTip = 'Suggest Tax lines.';

                    trigger OnAction()
                    begin
                        VATReportMediator.GetLines(Rec);
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
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Enabled = ReportPrintable;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    VATReportMediator.Print(Rec);
                end;
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
                actionref("&Print_Promoted"; "&Print")
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

    trigger OnAfterGetCurrRecord()
    begin
        ReportPrintable := not Rec.isDatifattura();
    end;

    var
        VATReportMediator: Codeunit "VAT Report Mediator";
        ReportPrintable: Boolean;

}
