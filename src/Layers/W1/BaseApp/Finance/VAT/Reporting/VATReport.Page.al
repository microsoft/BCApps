// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Attachment;
using System.DateTime;
using System.Utilities;

page 740 "VAT Report"
{
    Caption = 'VAT Return';
    DataCaptionExpression = Rec."No.";
    LinksAllowed = false;
    PageType = Document;
    SourceTable = "VAT Report Header";
    SourceTableView = where("VAT Report Config. Code" = const("VAT Return"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsEditable;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("VAT Report Version"; Rec."VAT Report Version")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Version';
                    Editable = not ReturnPeriodEnabled;
                    NotBlank = true;
                    ToolTip = 'Specifies version of the report.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the report is in progress, is completed, or contains errors.';

                    trigger OnValidate()
                    begin
                        InitPageControllers();
                    end;
                }
                field("Amounts in Add. Rep. Currency"; Rec."Amounts in Add. Rep. Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the amounts are in the additional reporting currency.';
                }
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the additional information must be added to VAT report.';
                    Visible = false;
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the VAT report lines were created.';
                    Visible = false;
                }
                group(Control23)
                {
                    Editable = false;
                    ShowCaption = false;
                    field("Period Year"; Rec."Period Year")
                    {
                        ApplicationArea = Basic, Suite;
                        LookupPageID = "Date Lookup";
                        ToolTip = 'Specifies the year of the reporting period.';
                    }
                    field("Period Type"; Rec."Period Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the length of the reporting period. The field is empty if a custom period is defined.';
                    }
                    field("Period No."; Rec."Period No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the specific reporting period to use. The field is empty if a custom period is defined.';
                    }
                    field("Start Date"; Rec."Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the first date of the reporting period.';
                    }
                    field("End Date"; Rec."End Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the last date of the reporting period.';
                    }
                    field("Country/Region Filter"; Rec."Country/Region Filter")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region filter for the report.';

                    }
                }
            }
            group("Return Period")
            {
                Editable = false;
                Visible = ReturnPeriodEnabled;
                field(ReturnPeriodDueDate; ReturnPeriodDueDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Due Date';
                    ToolTip = 'Specifies the due date for the VAT return period.';
                }
                field(ReturnPeriodStatus; ReturnPeriodStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the VAT return period.';
                }
            }
            part(VATReportLines; "VAT Report Statement Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Lines';
                SubPageLink = "VAT Report No." = field("No."),
                              "VAT Report Config. Code" = field("VAT Report Config. Code");
            }
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Messages';
                Visible = ErrorsExist;
            }
        }
        area(factboxes)
        {
#if not CLEAN25
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ObsoleteTag = '25.0';
                ObsoleteState = Pending;
                ObsoleteReason = 'The "Document Attachment FactBox" has been replaced by "Doc. Attachment List Factbox", which supports multiple files upload.';
                ApplicationArea = All;
                Visible = false;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"VAT Report Header"),
                              "No." = field("No."),
                              "VAT Report Config. Code" = field("VAT Report Config. Code");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"VAT Report Header"),
                              "No." = field("No."),
                              "VAT Report Config. Code" = field("VAT Report Config. Code");

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
                    Caption = 'Suggest Lines';
                    Enabled = SuggestLinesControllerStatus;
                    Image = SuggestLines;
                    ToolTip = 'Create VAT Report entries based on information gathered from documents related to sales and purchases. ';

                    trigger OnAction()
                    begin
                        VATReportMediator.GetLines(Rec);
                        CurrPage.VATReportLines.PAGE.SelectFirst();
                        CheckForErrors();
                    end;
                }
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Enabled = ReleaseControllerStatus;
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Verify that the report includes all of the required information, and prepare it for submission.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Release(Rec);
                        CheckForErrors();
                    end;
                }
                action(Generate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Generate';
                    Enabled = SubmitControllerStatus;
                    Image = GetLines;
                    ToolTip = 'Generate the content of VAT report.';
                    Visible = GenerationVisible;

                    trigger OnAction()
                    begin
                        VATReportMediator.Generate(Rec);
                        if not CheckForErrors() then
                            Message(ReportGeneratedMsg);
                    end;
                }
                action(Submit)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Submit';
                    Enabled = SubmitControllerStatus;
                    Image = SendElectronicDocument;
                    ToolTip = 'Submits the VAT report to the tax authority''s reporting service.';
                    Visible = SubmissionVisible;

                    trigger OnAction()
                    begin
                        VATReportMediator.Export(Rec);
                        if not CheckForErrors() then
                            Message(ReportSubmittedMsg);
                    end;
                }
                action("Receive Response")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receive Response';
                    Enabled = ReceiveControllerStatus;
                    Image = Alerts;
                    ToolTip = 'Receive a response from the the tax authority''s reporting service after the VAT report submission.';
                    Visible = ReceiveVisible;

                    trigger OnAction()
                    begin
                        VATReportMediator.ReceiveResponse(Rec);
                    end;
                }
                action("Mark as Submitted")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark as Submitted';
                    Enabled = MarkAsSubmitControllerStatus;
                    Image = Approve;
                    ToolTip = 'Indicate that you submitted the report to the tax authority manually.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Submit(Rec);
                        if not CheckForErrors() then
                            Message(MarkAsSubmittedMsg);
                    end;
                }
                action("Cancel Submission")
                {
                    ApplicationArea = Basic, Suite;
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
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Enabled = ReopenControllerStatus;
                    Image = ReOpen;
                    ToolTip = 'Open the report again to make changes.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                    end;
                }
                action("Download Submission Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Download Submission Message';
                    Enabled = DownloadSubmissionControllerStatus;
                    Image = MoveDown;
                    ToolTip = 'Open the report again to make changes.';

                    trigger OnAction()
                    var
                        VATReportArchive: Record "VAT Report Archive";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeDownloadSubmissionMessage(IsHandled, Rec);
                        if IsHandled then
                            exit;
                        VATReportArchive.DownloadSubmissionMessage(Rec."VAT Report Config. Code".AsInteger(), Rec."No.");
                    end;
                }
                action("Download Response Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Download Response Message';
                    Enabled = DownloadResponseControllerStatus;
                    Image = MoveDown;
                    ToolTip = 'Open the report again to make changes.';

                    trigger OnAction()
                    var
                        VATReportArchive: Record "VAT Report Archive";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeDownloadResponseMessage(IsHandled, Rec);
                        if IsHandled then
                            exit;
                        VATReportArchive.DownloadResponseMessage(Rec."VAT Report Config. Code".AsInteger(), Rec."No.");
                    end;
                }
                action("Calc. and Post VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate and Post VAT Settlement';
                    Enabled = CalcAndPostVATStatus;
                    Image = "Report";
                    ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account. For every VAT posting group, the batch job finds all the VAT entries in the VAT Entry table that are included in the filters in the definition window.';

                    trigger OnAction()
                    var
                        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
                    begin
                        CalcAndPostVATSettlement.InitializeRequest(Rec."Start Date", Rec."End Date", WorkDate(), Rec."No.", '', false, false);
                        CalcAndPostVATSettlement.Run();
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Image = Print;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';
                Visible = false;

                trigger OnAction()
                begin
                    VATReportMediator.Print(Rec);
                end;
            }
            action("Report Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Setup';
                Image = Setup;
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
                Visible = false;
            }
        }
        area(navigation)
        {
            action("Open VAT Return Period Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open VAT Return Period Card';
                Image = ShowList;
                ToolTip = 'Open the VAT return period card for this VAT return.';
                Visible = ReturnPeriodEnabled;

                trigger OnAction()
                var
                    VATReportMgt: Codeunit "VAT Report Mgt.";
                begin
                    VATReportMgt.OpenVATPeriodCardFromVATReturn(Rec);
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
                actionref("Mark as Submitted_Promoted"; "Mark as Submitted")
                {
                }
                actionref(Generate_Promoted; Generate)
                {
                }
                actionref("Receive Response_Promoted"; "Receive Response")
                {
                }
                actionref("Cancel Submission_Promoted"; "Cancel Submission")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'VAT Settlement', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Calc. and Post VAT Settlement_Promoted"; "Calc. and Post VAT Settlement")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        InitPageControllers();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InitPageControllers();
    end;

    trigger OnOpenPage()
    begin
        if Rec."No." <> '' then
            InitPageControllers();
        IsEditable := Rec.Status = Rec.Status::Open;
    end;

    var
        VATReportMediator: Codeunit "VAT Report Mediator";
        ErrorsExist: Boolean;
        ReportGeneratedMsg: Label 'The report has been successfully generated.';
        ReportSubmittedMsg: Label 'The report has been successfully submitted.';
        CancelReportSentMsg: Label 'The cancellation request has been sent.';
        MarkAsSubmittedMsg: Label 'The report has been marked as submitted.';
        SuggestLinesControllerStatus: Boolean;
        SubmitControllerStatus: Boolean;
        GenerationVisible: Boolean;
        SubmissionVisible: Boolean;
        ReceiveControllerStatus: Boolean;
        ReceiveVisible: Boolean;
        MarkAsSubmitControllerStatus: Boolean;
        ReleaseControllerStatus: Boolean;
        ReopenControllerStatus: Boolean;
        DownloadSubmissionControllerStatus: Boolean;
        DownloadResponseControllerStatus: Boolean;
        CalcAndPostVATStatus: Boolean;
        ReturnPeriodDueDate: Date;
        ReturnPeriodStatus: Option Open,Closed;
        ReturnPeriodEnabled: Boolean;

    protected var
        IsEditable: Boolean;

    local procedure InitPageControllers()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        SuggestLinesControllerStatus := Rec.Status = Rec.Status::Open;
        ReleaseControllerStatus := Rec.Status = Rec.Status::Open;
        GenerationVisible := VATReportMediator.ShowGenerate(Rec);
        SubmissionVisible := VATReportMediator.ShowExport(Rec);
        SubmitControllerStatus := Rec.Status = Rec.Status::Released;
        ReceiveVisible := VATReportMediator.ShowReceiveResponse(Rec);
        ReceiveControllerStatus := Rec.Status = Rec.Status::Submitted;
        MarkAsSubmitControllerStatus := Rec.Status = Rec.Status::Released;
        DownloadSubmissionControllerStatus := VATReportMediator.ShowSubmissionMessage(Rec);
        DownloadResponseControllerStatus :=
          DocumentAttachment.VATReturnResponseAttachmentsExist(Rec) or
          (Rec.Status = Rec.Status::Rejected) or
          (Rec.Status = Rec.Status::Accepted) or
          (Rec.Status = Rec.Status::Closed);
        CalcAndPostVATStatus := Rec.Status = Rec.Status::Accepted;
        ReopenControllerStatus := Rec.Status = Rec.Status::Released;
        InitReturnPeriodGroup();
        OnAfterInitPageControllers(Rec, SubmitControllerStatus, MarkAsSubmitControllerStatus, CalcAndPostVATStatus);
    end;

    local procedure InitReturnPeriodGroup()
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        ReturnPeriodEnabled := VATReturnPeriod.Get(Rec."Return Period No.");
        if ReturnPeriodEnabled then begin
            ReturnPeriodDueDate := VATReturnPeriod."Due Date";
            ReturnPeriodStatus := VATReturnPeriod.Status;
        end;
    end;

    local procedure CheckForErrors(): Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        TempErrorMessage.CopyFromContext(Rec);
        CurrPage.ErrorMessagesPart.Page.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesPart.Page.Update();
        ErrorsExist := not TempErrorMessage.IsEmpty();

        exit(ErrorsExist);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPageControllers(VATReportHeader: Record "VAT Report Header"; var SubmitControllerStatus: Boolean; var MarkAsSubmitControllerStatus: Boolean; var CalcAndPostVATStatus: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadSubmissionMessage(var IsHandled: Boolean; var VATReportHeader: Record "VAT Report Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadResponseMessage(var IsHandled: Boolean; var VATReportHeader: Record "VAT Report Header")
    begin
    end;
}

