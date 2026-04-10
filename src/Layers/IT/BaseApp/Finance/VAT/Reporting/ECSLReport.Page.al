// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using System.Text;
using System.Utilities;

/// <summary>
/// Card interface for creating, managing, and submitting European Community Sales List reports.
/// Provides comprehensive workflow from line generation through validation and submission to EU tax authorities.
/// </summary>
page 321 "ECSL Report"
{
    Caption = 'EC Sales List Report';
    Description = 'EC Sales List Report';
    LinksAllowed = false;
    PageType = Document;
    ShowFilter = false;
    SourceTable = "VAT Report Header";
    SourceTableView = where("VAT Report Config. Code" = filter("VAT Transactions Report"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = BasicEU;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("VAT Report Config. Code"; Rec."VAT Report Config. Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the appropriate configuration code.';
                    Visible = false;
                }
                field("Original Report No."; Rec."Original Report No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the original VAT report if the VAT Report Type field is set to a value other than Standard.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = BasicEU;
                    DrillDown = false;
                    Enabled = false;
                    ToolTip = 'Specifies whether the report is in progress, is completed, or contains errors.';
                }
                field(ViewErrors; ViewErrors)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'View Errors';
                    Editable = false;
                    ToolTip = 'Specifies the link to a page where you can view errors that the tax authority found in the report.';
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates to use to filter the amounts.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        // SETFILTER("Date Filter",DateFilter);
                        CurrPage.Update();
                    end;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = BasicEU;
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        ClearPeriod();
                    end;
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = BasicEU;
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        ClearPeriod();
                    end;
                }
            }
            part(ECSLReportLines; "ECSL Report Subform")
            {
                ApplicationArea = BasicEU;
                SubPageLink = "Report No." = field("No.");
            }
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = BasicEU;
                Caption = 'Messages';
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
                    ApplicationArea = BasicEU;
                    Caption = 'Suggest Lines';
                    Image = SuggestLines;
                    ToolTip = 'Create EC Sales List entries based on information gathered from sales-related documents.';

                    trigger OnAction()
                    var
                        ECSLVATReportLine: Record "ECSL VAT Report Line";
                    begin
                        VATReportMediator.GetLines(Rec);
                        UpdateSubForm();
                        CheckForErrors(Rec.RecordId);
                        ECSLVATReportLine.SetRange("Report No.", Rec."No.");
                        if ECSLVATReportLine.Count = 0 then
                            Message(NoLineGeneratedMsg);
                    end;
                }
                action(Release)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ToolTip = 'Verify that the report includes all of the required information, and prepare it for submission.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Release(Rec);
                        CheckForErrors(Rec.RecordId);
                        Message(ReportReleasedMsg);
                    end;
                }
                action(Submit)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Submit';
                    Image = SendElectronicDocument;
                    ToolTip = 'Submits the EC Sales List report to the tax authority''s reporting service.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Export(Rec);
                        CheckForErrors(Rec.RecordId);
                        Message(ReportSubmittedMsg);
                    end;
                }
                action("Mark as Submitted")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Mark as Su&bmitted';
                    Image = Approve;
                    ToolTip = 'Indicate that the tax authority has approved and returned the report.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Submit(Rec);
                        Message(MarkAsSubmittedMsg);
                    end;
                }
                action("Cancel Submission")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Cancel Submission';
                    Image = Cancel;
                    ToolTip = 'Cancels previously submitted report.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                        Message(CancelReportSentMsg);
                    end;
                }
                action("Log Entries")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Log Entries';
                    Image = ErrorLog;
                    ToolTip = 'View a history of communications with the tax authority.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the report again to make changes.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = BasicEU;
                Caption = '&Print';
                Image = Print;
                ToolTip = 'Prepare the report for printing by specifying the information it will include.';
                Visible = false;

                trigger OnAction()
                begin
                    VATReportMediator.Print(Rec);
                end;
            }
            action("Report Setup")
            {
                ApplicationArea = BasicEU;
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

                actionref(SuggestLines_Promoted; SuggestLines)
                {
                }
                group(Category_Release)
                {
                    Caption = 'Release';
                    ShowAs = SplitButton;

                    actionref(Release_Promoted; Release)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                }
                actionref(Submit_Promoted; Submit)
                {
                }
                actionref("Log Entries_Promoted"; "Log Entries")
                {
                }
                actionref("Mark as Submitted_Promoted"; "Mark as Submitted")
                {
                }
                actionref("Cancel Submission_Promoted"; "Cancel Submission")
                {
                }
            }
        }
    }

    trigger OnClosePage()
    begin
        DeleteErrors();
    end;

    var
        DummyCompanyInformation: Record "Company Information";
        VATReportMediator: Codeunit "VAT Report Mediator";
        DateFilter: Text[30];
        ViewErrors: Text;
        ReportSubmittedMsg: Label 'The report has been successfully submitted.';
        CancelReportSentMsg: Label 'The cancel request has been sent.';
        MarkAsSubmittedMsg: Label 'The report has been marked as submitted.';
        ReportReleasedMsg: Label 'The report has been marked as released.';
        NoLineGeneratedMsg: Label 'Ther are no VAT entries in the specified period.';

    local procedure UpdateSubForm()
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementName.FindFirst();
        VATStatementName.SetFilter("Date Filter", DateFilter);
        // CurrPage.VATReportLines.PAGE.UpdateForm(VATStatementName,Selection,PeriodSelection,UseAmtsInAddCurr);
        CurrPage.ECSLReportLines.PAGE.UpdateForm();

        // TO DO - Update ECSL
    end;

    local procedure ClearPeriod()
    begin
        // "Period No." := 0;
        // "Period Type" := "Period Type"::" ";
    end;

    local procedure CheckForErrors(FilterRecordID: RecordID)
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Context Record ID", FilterRecordID);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.Update();
    end;

    local procedure DeleteErrors()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Context Record ID", DummyCompanyInformation.RecordId);
        if ErrorMessage.FindFirst() then
            ErrorMessage.DeleteAll(true);
        Commit();
    end;
}

