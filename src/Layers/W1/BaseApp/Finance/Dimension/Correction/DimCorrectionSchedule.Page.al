// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using System.Threading;

page 2593 "Dim Correction Schedule"
{
    PageType = StandardDialog;
    SourceTable = "Job Queue Entry";
    Caption = 'Run Dimension Correction';
    DataCaptionExpression = '';

    layout
    {
        area(Content)
        {
            group(RunImmediatelyGroup)
            {
                ShowCaption = false;
                field(RunImmediately; RunImmediately)
                {
                    ApplicationArea = All;
                    Caption = 'Run immediately';
                    ToolTip = 'Specifies whether to start the job as soon as possible. We recommend that you turn this on only when jobs have a small number of entries. For example, fewer than 1000. For large projects, consider scheduling the run to happen outside working hours.';

                    trigger OnValidate()
                    begin
                        UpdateAfterChangingRunImmediately(RunImmediately);
                    end;
                }
            }

            group(ScheduleJobGroup)
            {
                Caption = 'Scheduling Parameters';
                Enabled = not RunImmediately;

                group(ScheduleJobParameters)
                {
                    ShowCaption = false;
                    field(NumberOfRetriesField; Rec."Maximum No. of Attempts to Run")
                    {
                        ApplicationArea = All;
                        Caption = 'Maximum No. of Attempts to Run';
                        ToolTip = 'Specifies the number of times the job queue entry will try to run.';
                    }

                    field(EarliestStartDateTimeField; Rec."Earliest Start Date/Time")
                    {
                        ApplicationArea = All;
                        Caption = 'Earliest Start Date/Time';
                        ToolTip = 'Specifies the earliest date and time when the dimension correction should be run.  The format for the date and time must be month/day/year hour:minute, and then AM or PM. For example, 3/10/2021 12:00 AM.';
                    }

                    field(Timeout; Rec."Job Timeout")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Maximum Duration';
                        ToolTip = 'Specifies the maximum time that the dimension correction is allowed to run.';
                    }

                    field(AdvancedSettings; AdvancedSettingsLbl)
                    {
                        ShowCaption = false;
                        ApplicationArea = All;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            Rec.SetRecFilter();
                            Page.RunModal(PAGE::"Job Queue Entry Card", Rec);
                            Rec.Find();
                        end;
                    }
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::Cancel, Action::LookupCancel] then begin
            if Rec.Delete() then;
            exit(true);
        end;

        Rec.SetStatus(Rec.Status::Ready);
    end;

    trigger OnOpenPage()
    begin
        RunImmediately := false;
        UpdateAfterChangingRunImmediately(RunImmediately);

        if NewPageCaption <> '' then
            CurrPage.Caption(NewPageCaption);

        OnAfterOnOpenPage(RunImmediately);
    end;


    procedure SetNewCaption(NewCaption: Text)
    begin
        NewPageCaption := NewCaption;
    end;

    local procedure UpdateAfterChangingRunImmediately(NewRunImmediately: Boolean)
    var
        NumberOfRetries: Integer;
        EarliestStartDateTime: DateTime;
    begin
        if NewRunImmediately then begin
            NumberOfRetries := 0;
            EarliestStartDateTime := CurrentDateTime();
        end else begin
            NumberOfRetries := 3;
            EarliestStartDateTime := CreateDateTime(DT2Date(CurrentDateTime()), CreateDefaultTime());
        end;

        Rec.Validate("Maximum No. of Attempts to Run", NumberOfRetries);
        Rec.Validate("Earliest Start Date/Time", EarliestStartDateTime);
        Rec."Job Timeout" := Rec.DefaultJobTimeout();
        Rec.Modify(true);
    end;

    local procedure CreateDefaultTime() Result: Time
    begin
        Evaluate(
          Result,
          Format(22, 0, '<Integer,2><Filler Character,0>') +
          Format(0, 0, '<Integer,2><Filler Character,0>') +
          Format(0, 0, '<Integer,2><Filler Character,0>'));
    end;

    procedure ShowWarningMessage()
    begin
        Message(ScheduleAfterBusinessHoursMsg);
    end;

    var
        RunImmediately: Boolean;
        NewPageCaption: Text;
        AdvancedSettingsLbl: Label 'Advanced Settings';
        ScheduleAfterBusinessHoursMsg: Label 'If you are correcting dimensions for a large number of entries, such as more than 1000, we recommend that you schedule the update to happen after business hours. This helps avoid performance issues.';

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var RunImmediately: boolean)
    begin
    end;
}
