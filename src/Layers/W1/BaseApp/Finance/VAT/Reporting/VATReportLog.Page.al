// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 739 "VAT Report Log"
{
    Caption = 'VAT Report Log';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "VAT Report Archive";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to create a new VAT report, or if you want to change a previously submitted report.';
                }
                field("VAT Report No."; Rec."VAT Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the VAT Report.';
                }
                field("Submitted By"; Rec."Submitted By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person who submitted the VAT Report.';
                }
                field("Submittion Date"; Rec."Submittion Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the VAT Report was submitted.';
                }
                field("Response Received Date"; Rec."Response Received Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the response was received.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Download Submission Message")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download Submission Message';
                Enabled = DownloadSubmissionControllerStatus;
                Image = XMLFile;
                ToolTip = 'Open the report again to make changes.';
                Visible = false;

                trigger OnAction()
                var
                    VATReportArchive: Record "VAT Report Archive";
                begin
                    CurrPage.SetSelectionFilter(VATReportArchive);
                    if VATReportArchive.FindFirst() then
                        VATReportArchive.DownloadSubmissionMessage(
                          VATReportArchive."VAT Report Type".AsInteger(), VATReportArchive."VAT Report No.");
                end;
            }
            action("Download Response Message")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download Response Message';
                Enabled = DownloadResponseControllerStatus;
                Image = XMLFile;
                ToolTip = 'Open the report again to make changes.';
                Visible = false;

                trigger OnAction()
                var
                    VATReportArchive: Record "VAT Report Archive";
                begin
                    CurrPage.SetSelectionFilter(VATReportArchive);
                    if VATReportArchive.FindFirst() then
                        VATReportArchive.DownloadResponseMessage(
                          VATReportArchive."VAT Report Type".AsInteger(), VATReportArchive."VAT Report No.");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Download Submission Message_Promoted"; "Download Submission Message")
                {
                }
                actionref("Download Response Message_Promoted"; "Download Response Message")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        DownloadSubmissionControllerStatus := true;
        DownloadResponseControllerStatus := true;
    end;

    var
        DownloadSubmissionControllerStatus: Boolean;
        DownloadResponseControllerStatus: Boolean;

    procedure SetReport(VATReportHeader: Record "VAT Report Header")
    begin
        Rec.SetFilter("VAT Report No.", VATReportHeader."No.");
        Rec.SetFilter("VAT Report Type", Format(VATReportHeader."VAT Report Config. Code"::"EC Sales List"));
    end;
}

