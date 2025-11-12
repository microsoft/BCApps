// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using System.Security.AccessControl;
using System.Utilities;

page 2591 "Dimension Correction Draft"
{
    PageType = ListPlus;
    SourceTable = "Dimension Correction";
    DataCaptionExpression = Rec.Description;
    Caption = 'Draft Dimension Correction';

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                Caption = 'General';
                Editable = EditAllowed;
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
                    Caption = 'Description';
                    Tooltip = 'Specifies information about the correction. For example, this might provide a reason for the correction.';
                    MultiLine = true;

                    trigger OnValidate()
                    begin
                        if Rec.Description <> '' then
                            CurrPage.Update(true);
                    end;
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
                            MultiLine = true;
                            Editable = false;
                            Enabled = false;
                            Caption = 'Validation Status';
                            Tooltip = 'Specifies the status of the last validation.';
                        }
                    }
                }

                field(UpdateAnalysisViews; Rec."Update Analysis Views")
                {
                    ApplicationArea = All;
                    Caption = 'Update Analysis Views';
                    Tooltip = 'Specifies if the Analysis views should be updated at the end of correction.';
                }

                group(AnalysisViewSelection)
                {
                    ShowCaption = false;
                    Visible = Rec."Update Analysis Views";

                    field(AnalysisViewUpdateType; Rec."Analysis View Update Type")
                    {
                        ApplicationArea = All;
                        Editable = Rec."Update Analysis Views";
                        Caption = 'Selection';
                        Tooltip = 'Specifies the analysis views to update when you correct the dimension.';
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

            part(DimensionCorrectionsPage; "Dimension Correction Changes")
            {
                Editable = EditAllowed;
                ApplicationArea = All;
                Caption = 'Dimension Correction Changes';
                UpdatePropagation = SubPart;
                SubPageLink = "Dimension Correction Entry No." = field("Entry No.");
            }

            part(SelectedGLEntries; "Dim. Correct Ledger Entries")
            {
                ApplicationArea = All;
                Caption = 'Selected Ledger Entries';
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunDimensionChange)
            {
                ApplicationArea = All;
                Image = ExecuteBatch;
                Caption = 'Run';
                ToolTip = 'Schedule a job to update the selected dimensions.';

                trigger OnAction()
                var
                    DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                begin
                    DimensionCorrectionMgt.VerifyCanValidateDimensionCorrection(Rec);
                    DimensionCorrectionMgt.VerifyCanStartJob(Rec);
                    if not DimensionCorrectionMgt.ScheduleRunJob(Rec) then
                        exit;

                    if Rec.Status = Rec.Status::"In Process" then begin
                        Message(JobSuccessfullyScheduledMsg);
                        CurrPage.Close();
                    end;
                end;
            }

            action(Reset)
            {
                ApplicationArea = All;
                Image = ReOpen;
                Enabled = Rec."Started Correction";
                Caption = 'Reopen';
                ToolTip = 'Reopen the dimension correction, for example, to make changes. This will clear the results of the previous run.';

                trigger OnAction()
                begin
                    Rec.ReopenDraftDimensionCorrection();
                    Rec.Modify();
                    Message(DraftDimensionCorrectionReopenedMsg);
                    CurrPage.Update();
                end;
            }

            action(ValidateCorrection)
            {
                ApplicationArea = All;
                Caption = 'Validate Dimension Changes';
                Image = TestReport;
                ToolTip = 'Validates the dimension changes.';

                trigger OnAction()
                var
                    DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                begin
                    if Rec.Status = Rec.Status::"Validaton in Process" then
                        Error(JobAlreadyInProgressErr);

                    DimensionCorrectionMgt.VerifyCanStartJob(Rec);

                    if DimensionCorrectionMgt.ScheduleValidationJob(Rec) then begin
                        Message(ValidationJobSuccessfullyScheduledMsg);
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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RunDimensionChange_Promoted; RunDimensionChange)
                {
                }
                actionref(Reset_Promoted; Reset)
                {
                }
                actionref(ValidateCorrection_Promoted; ValidateCorrection)
                {
                }
                actionref(ShowErrors_Promoted; ShowErrors)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.Completed then begin
            Page.Run(PAGE::"Dimension Correction", Rec);
            Error('');
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        UpdateEditAllowed();
    end;

    trigger OnAfterGetRecord()
    var
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        DimensionCorrectionMgt.UpdateStatus(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.SelectedGLEntries.Page.SetDimensionCorrectionEntryNo(Rec."Entry No.");
        Rec.GetValidateDimensionChangesText(ValidationStatusTxt);
        ValidationStatusVisible := (ValidationStatusTxt <> '') and (Rec.Status <> Rec.Status::Failed);
        IsErrorActionEnabled := ValidationStatusVisible and (not IsNullGuid(Rec."Validation Errors Register ID"));
        UpdateEditAllowed();
        UpdateUserDisplayName();
        ResetEnabled := Rec."Started Correction" and (Rec.Status <> Rec.Status::"In Process");
    end;

    local procedure UpdateEditAllowed()
    begin
        EditAllowed := (Rec.Status in [Rec.Status::Draft, Rec.Status::Failed]) and (not Rec."Started Correction");
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
        EditAllowed: Boolean;
        ResetEnabled: Boolean;
        IsErrorActionEnabled: Boolean;
        ValidationStatusTxt: Text;
        ValidationStatusVisible: Boolean;
        JobSuccessfullyScheduledMsg: Label 'Dimension Correction was successfully scheduled.';
        ValidationJobSuccessfullyScheduledMsg: Label 'Job to Validate Dimension Correction was successfully scheduled.';
        DraftDimensionCorrectionReopenedMsg: Label 'Cleared data from previous run. Dimension Correction is reopened for corrections.';
        JobAlreadyInProgressErr: Label 'A job for this task is already in progress.';
}
