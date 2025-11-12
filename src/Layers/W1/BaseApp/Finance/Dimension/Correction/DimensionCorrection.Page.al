// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using System.Security.AccessControl;
using System.Utilities;

page 2588 "Dimension Correction"
{
    PageType = ListPlus;
    SourceTable = "Dimension Correction";
    DataCaptionExpression = Rec.Description;
    Caption = 'Dimension Correction';

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                Editable = false;
                Caption = 'General';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    Caption = 'Entry No.';
                    Tooltip = 'Specifies the identifier of the correction.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Caption = 'Description';
                    Tooltip = 'Specifies information about the correction. For example, this might provide a reason for the correction.';
                }

                group(StatusGroup)
                {
                    ShowCaption = false;
                    field(Status; Rec.Status)
                    {
                        ApplicationArea = All;
                        Caption = 'Status';
                        Tooltip = 'Specifies the status of the correction.';
                    }

                    group(ErrorMessage)
                    {
                        ShowCaption = false;
                        Visible = Rec.Status = Rec.Status::Failed;

                        field(ErrorMessageText; Rec."Error Message")
                        {
                            ApplicationArea = All;
                            MultiLine = true;
                            Caption = 'Error Message';
                            Tooltip = 'Specifies why the correction failed.';
                        }
                    }

                    group(ValidationStatusGroup)
                    {
                        ShowCaption = false;
                        Visible = ValidationStatusVisible;
                        field(ValidationStatus; ValidationStatusTxt)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            MultiLine = true;
                            Caption = 'Validation Status';
                            Tooltip = 'Specifies the status of the last validation.';
                        }
                    }

                    field(UpdateAnalysisViewsStatus; Rec."Update Analysis Views Status")
                    {
                        ApplicationArea = All;
                        Caption = 'Update Analysis Views Status';
                        Tooltip = 'Specifies the status of update to analysis views.';
                    }

                    group(AnalysisViewsErrorMessage)
                    {
                        ShowCaption = false;
                        Visible = Rec.Status = Rec."Update Analysis Views Status"::Failed;

                        field(AnalysisViewsErrorMessageText; Rec."Update Analysis Views Error")
                        {
                            ApplicationArea = All;
                            MultiLine = true;
                            Caption = 'Update Analysis Views Error';
                            Tooltip = 'Specifies why the data in analysis views could not be updated.';
                        }
                    }
                }
                group(UserInfo)
                {
                    ShowCaption = false;

                    field(LastModifiedAt; Rec.SystemModifiedAt)
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Caption = 'Last modified at';
                        Tooltip = 'Specifies the last date and time that the correction was updated.';
                    }

                    field(LastModifiedBy; SystemModifiedByDisplayName)
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = false;
                        Caption = 'Last modified by';
                        Tooltip = 'Specifies the last user who changed the entry.';
                    }

                    field(CreatedAt; Rec.SystemCreatedAt)
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Caption = 'Created at';
                        Tooltip = 'Specifies the date and time that the correction was created.';
                    }

                    field(CreatedBy; SystemCreatedByDisplayName)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Importance = Additional;
                        Caption = 'Created by';
                        Tooltip = 'Specifies the user who created the entry.';
                    }
                }
            }

            part(DimensionCorrectionsPage; "Dim Correction Changes Posted")
            {
                ApplicationArea = All;
                Caption = 'Dimension Correction Changes';
                UpdatePropagation = SubPart;
                Editable = false;
                SubPageLink = "Dimension Correction Entry No." = field("Entry No.");
            }

            part(SelectedGLEntries; "Dim Correct Posted Ledg Entr")
            {
                ApplicationArea = All;
                Editable = false;
                Caption = 'Selected Ledger Entries';
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UndoDimensionCorrection)
            {
                ApplicationArea = All;
                Enabled = UndoAndValidateAreEnabled;
                Image = Undo;
                Caption = 'Undo';
                ToolTip = 'Undo the selected correction. The values of the related entries will be reverted to their previous state.';

                trigger OnAction()
                var
                    DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                begin
                    if Rec.Status <> Rec.Status::Completed then
                        Error(CanOnlyUndoCompletedCorrectionsErr);

                    if Rec.Status = Rec.Status::"Undo in Process" then
                        Error(JobAlreadyInProgressErr);

                    DimensionCorrectionMgt.VerifyCanStartJob(Rec);
                    DimensionCorrectionMgt.VerifyCanUndoDimensionCorrection(Rec);
                    if DimensionCorrectionMgt.ScheduleUndoJob(Rec) then begin
                        DimensionCorrectionMgt.SetUndoStatusInProgress(Rec);
                        CurrPage.Close();
                    end;
                end;
            }

            action(CopyToDraft)
            {
                ApplicationArea = All;
                Image = CopyToTask;
                Caption = 'Copy to Draft';
                ToolTip = 'Create a draft of the selected dimension correction with the same selection criteria. For example, this is useful for making a correction when you cannot undo.';

                trigger OnAction()
                var
                    NewDimensionCorrection: Record "Dimension Correction";
                    DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                begin
                    DimensionCorrectionMgt.CopyToDraft(Rec, NewDimensionCorrection);
                    if Confirm(OpenCopiedEntryQst) then begin
                        Page.Run(Page::"Dimension Correction Draft", NewDimensionCorrection);
                        CurrPage.Close();
                    end;
                end;
            }

            action(ValidateCorrection)
            {
                ApplicationArea = All;
                Caption = 'Validate Undo Dimension Correction';
                Image = TestReport;
                Enabled = UndoAndValidateAreEnabled;
                ToolTip = 'Validates the dimension changes.';

                trigger OnAction()
                var
                    DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                begin
                    if Rec.Status = Rec.Status::"Validaton in Process" then
                        Error(JobAlreadyInProgressErr);

                    if Rec.Status <> Rec.Status::Completed then
                        Error(CanOnlyUndoCompletedCorrectionsErr);

                    DimensionCorrectionMgt.VerifyCanValidateDimensionCorrection(Rec);
                    DimensionCorrectionMgt.VerifyCanStartJob(Rec);
                    if DimensionCorrectionMgt.ScheduleValidationJob(Rec) then begin
                        Message(UndoDimCorrectionValidationJobSuccessfullyScheduledMsg);
                        CurrPage.Close();
                    end;
                end;
            }

            action(ShowErrors)
            {
                ApplicationArea = All;
                Caption = 'Show Errors';
                Image = ErrorLog;
                ToolTip = 'Open the list of validation errors.';
                Enabled = IsErrorActionEnabled;

                trigger OnAction()
                var
                    ErrorMessageManagement: Codeunit "Error Message Management";
                begin
                    ErrorMessageManagement.ShowErrors(Rec."Validation Errors Register ID");
                end;
            }

            group(AnalysisViews)
            {
                Caption = 'Analysis Views';
                Image = AnalysisView;

                action(UpdateAnalysisViews)
                {
                    ApplicationArea = All;
                    Image = AnalysisViewDimension;
                    Caption = 'Update Analysis Views';
                    ToolTip = 'Update the data shown in analysis views to include the results of the correction.';

                    trigger OnAction()
                    var
                        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                    begin
                        if Rec."Update Analysis Views Status" <> Rec."Update Analysis Views Status"::"In Process" then
                            DimensionCorrectionMgt.ScheduleUpdateAnalysisViews(Rec)
                        else
                            Error(JobAlreadyInProgressErr);
                    end;
                }

                action(SetAnalysisViewCompleted)
                {
                    ApplicationArea = All;
                    Image = CompleteLine;
                    Caption = 'Set Update Analysis Views Status to Completed';
                    ToolTip = 'Set the status of an analysis view update to Completed. Use this action after you have manually updated analysis views.';

                    trigger OnAction()
                    var
                        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                    begin
                        DimensionCorrectionMgt.SetUpdateAnalysisViewsCompleted(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UndoDimensionCorrection_Promoted; UndoDimensionCorrection)
                {
                }
                actionref(CopyToDraft_Promoted; CopyToDraft)
                {
                }
                actionref(ValidateCorrection_Promoted; ValidateCorrection)
                {
                }
                actionref(ShowErrors_Promoted; ShowErrors)
                {
                }
                actionref(UpdateAnalysisViews_Promoted; UpdateAnalysisViews)
                {
                }
                actionref(SetAnalysisViewCompleted_Promoted; SetAnalysisViewCompleted)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        DimensionCorrectionMgt.UpdateStatus(Rec);
        DimensionCorrectionMgt.UpdateAnalysisViewStatus(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    var
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        DimensionCorrectionMgt.ShowNotificationUpdateCashFlowAccounting();
        CurrPage.SelectedGLEntries.Page.SetDimensionCorrectionEntryNo(Rec."Entry No.");
        Rec.GetValidateDimensionChangesText(ValidationStatusTxt);
        ValidationStatusVisible := (ValidationStatusTxt <> '') and (not (Rec.Status in [Rec.Status::Failed, Rec.Status::"Undo Completed"]));
        IsErrorActionEnabled := ValidationStatusVisible and (not IsNullGuid(Rec."Validation Errors Register ID"));
        UpdateUserDisplayName();
        UndoAndValidateAreEnabled := Rec.Status <> Rec.Status::"Undo Completed";
    end;

    local procedure UpdateUserDisplayName()
    var
        User: Record "User";
    begin
        Clear(SystemCreatedByDisplayName);
        Clear(SystemModifiedByDisplayName);

        if not User.ReadPermission() then
            exit;

        if User.Get(Rec.SystemCreatedBy) then
            SystemCreatedByDisplayName := User."User Name";

        if User.Get(Rec.SystemModifiedBy) then
            SystemModifiedByDisplayName := User."User Name";
    end;

    var
        SystemModifiedByDisplayName: Text;
        SystemCreatedByDisplayName: Text;
        ValidationStatusTxt: Text;
        IsErrorActionEnabled: Boolean;
        ValidationStatusVisible: Boolean;
        UndoAndValidateAreEnabled: Boolean;
        UndoDimCorrectionValidationJobSuccessfullyScheduledMsg: Label 'The Job for validating the undo of dimension correction is scheduled.';
        OpenCopiedEntryQst: Label 'A draft of the dimension correction has been created. Would you like to open the draft entry now?';
        CanOnlyUndoCompletedCorrectionsErr: Label 'You can only undo dimension corrections that are completed.';
        JobAlreadyInProgressErr: Label 'There is a job already in progress.';
}
