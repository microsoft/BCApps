// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149033 "AIT Log Entries"
{
    Caption = 'AI Log Entries';
    PageType = List;
    ApplicationArea = All;
    Editable = false;
    SourceTable = "AIT Log Entry";
    Extensible = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                FreezeColumn = Status;

                field(RunID; Rec."Run ID")
                {
                    ToolTip = 'Specifies the Run ID.';
                    Visible = false;
                }
                field("Code"; Rec."Test Suite Code")
                {
                    ToolTip = 'Specifies the Test Suite Code.';
                    Visible = false;
                }
                field("AIT Line No."; Rec."Test Method Line No.")
                {
                    ToolTip = 'Specifies the Test Method Line No.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the Log Entry No..';
                    Visible = false;
                }
                field(Version; Rec.Version)
                {
                    Caption = 'Version No.';
                    ToolTip = 'Specifies the Version No. of the test run.';
                }
                field(Tag; Rec.Tag)
                {
                    ToolTip = 'Specifies the Tag that we entered in the AI Test Suite.';
                }
                field(CodeunitID; Rec."Codeunit ID")
                {
                    ToolTip = 'Specifies the test codeunit id.';
                }
                field(CodeunitName; Rec."Codeunit Name")
                {
                    ToolTip = 'Specifies the test codeunit name.';
                }
                field(Operation; Rec.Operation)
                {
                    ToolTip = 'Specifies the operation.';
                    Visible = false;
                    Enabled = false;
                }
                field("Procedure Name"; Rec."Procedure Name")
                {
                    ToolTip = 'Specifies the name of the procedure being executed.';
                }
                field("Original Operation"; Rec."Original Operation")
                {
                    ToolTip = 'Specifies the original operation.';
                    Visible = false;
                    Enabled = false;
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the iteration.';
                    StyleExpr = StatusStyleExpr;
                }
                field("Orig. Status"; Rec."Original Status")
                {
                    Visible = false;
                }
                field(Dataset; Rec."Test Input Group Code")
                {
                    ToolTip = 'Specifies the dataset that is used by the test.';
                }
                field("Dataset Line No."; Rec."Test Input Code")
                {
                    ToolTip = 'Specifies the Line No. of the dataset.';
                }
                field("Input Dataset Desc."; Rec."Test Input Description")
                {
                    ToolTip = 'Specifies the description of the input dataset.';
                }
                field("Input Text"; InputText)
                {
                    Caption = 'Input';
                    ToolTip = 'Specifies the test input of the AIT.';

                    trigger OnDrillDown()
                    begin
                        Message(Rec.GetInputBlob());
                    end;
                }
                field("Output Text"; OutputText)
                {
                    Caption = 'Test Output';
                    ToolTip = 'Specifies the test output of the AIT.';

                    trigger OnDrillDown()
                    begin
                        Message(Rec.GetOutputBlob());
                    end;
                }
                field(TestRunDuration; TestRunDuration)
                {
                    Caption = 'Duration';
                    ToolTip = 'Specifies the duration of the iteration.';
                }
                field(StartTime; Format(Rec."Start Time", 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2><Second dec.>'))
                {
                    Caption = 'Start Time';
                    ToolTip = 'Specifies the start time of the test.';
                    Visible = false;
                }
                field(EndTime; Format(Rec."End Time", 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2><Second dec.>'))
                {
                    Caption = 'End Time';
                    ToolTip = 'Specifies the end time of the test.';
                    Visible = false;
                }
                field(Message; ErrorMessage)
                {
                    Caption = 'Error Message';
                    ToolTip = 'Specifies when the error message from the test.';
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    begin
                        Message(ErrorMessage);
                    end;
                }
                field("Orig. Message"; Rec."Original Message")
                {
                    Caption = 'Orig. Message';
                    Visible = false;
                    ToolTip = 'Specifies the original message from the test.';
                }
                field("Error Call Stack"; ErrorCallStack)
                {
                    Caption = 'Call stack';
                    Editable = false;
                    ToolTip = 'Specifies the call stack for this error.';

                    trigger OnDrillDown()
                    begin
                        Message(ErrorCallStack);
                    end;
                }
                field("Log was Modified"; Rec."Log was Modified")
                {
                    Caption = 'Log was Modified';
                    ToolTip = 'Specifies if the log was modified by any event subscribers.';
                    Visible = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DeleteAll)
            {
                Caption = 'Delete entries within filter';
                Image = Delete;
                ToolTip = 'Deletes all the log entries.';

                trigger OnAction()
                begin
                    if not Confirm(DoYouWantToDeleteQst, false) then
                        exit;

                    Rec.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
            action(ShowErrors)
            {
                Visible = not IsFilteredToErrors;
                Caption = 'Show errors';
                Image = FilterLines;
                ToolTip = 'Shows only errors.';

                trigger OnAction()
                begin
                    Rec.SetRange(Status, Rec.Status::Error);
                    IsFilteredToErrors := true;
                    CurrPage.Update(false);
                end;
            }
            action(ClearShowErrors)
            {
                Visible = IsFilteredToErrors;
                Caption = 'Show success and errors';
                Image = RemoveFilterLines;
                ToolTip = 'Clears the filter on errors.';

                trigger OnAction()
                begin
                    Rec.SetRange(Status);
                    IsFilteredToErrors := false;
                    CurrPage.Update(false);
                end;
            }
            action("Show Sensitive Data")
            {
                Caption = 'Show sensitive data';
                Image = ShowWarning;
                Visible = not ShowSensitiveData;
                ToolTip = 'Use this action to make sensitive data visible.';

                trigger OnAction()
                begin
                    ShowSensitiveData := true;
                    CurrPage.Update(false);
                end;
            }
            action("Hide Sensitive Data")
            {
                Caption = 'Hide sensitive data';
                Image = RemoveFilterLines;
                Visible = ShowSensitiveData;
                ToolTip = 'Use this action to hide sensitive data.';

                trigger OnAction()
                begin
                    ShowSensitiveData := false;
                    CurrPage.Update(false);
                end;
            }
            action("Download Test Output")
            {
                Caption = 'Download Test Output';
                Image = Download;
                ToolTip = 'Use this action to download the test output.';

                trigger OnAction()
                var
                    AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
                begin
                    AITALTestSuiteMgt.DownloadTestOutputFromLogToFile(Rec);
                end;

            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(DeleteAll_Promoted; DeleteAll)
                {
                }
                actionref(ShowErrors_Promoted; ShowErrors)
                {
                }
                actionref(ClearShowErrors_Promoted; ClearShowErrors)
                {
                }
                actionref("Show Sensitive Data_Promoted"; "Show Sensitive Data")
                {
                }
                actionref("Hide Sensitive Data_Promoted"; "Hide Sensitive Data")
                {
                }
                actionref("Download Test Output_Promoted"; "Download Test Output")
                {
                }
            }
        }
    }

    var
        ClickToShowLbl: Label 'Show data input';
        DoYouWantToDeleteQst: Label 'Do you want to delete all entries within the filter?';
        InputText: Text;
        OutputText: Text;
        ErrorMessage: Text;
        ErrorCallStack: Text;
        StatusStyleExpr: Text;
        TestRunDuration: Duration;
        IsFilteredToErrors: Boolean;
        ShowSensitiveData: Boolean;

    trigger OnAfterGetRecord()
    begin
        TestRunDuration := Rec."Duration (ms)";
        SetInputOutputDataFields();
        SetErrorFields();
        SetStatusStyleExpr();
    end;

    local procedure SetStatusStyleExpr()
    begin
        case Rec.Status of
            Rec.Status::Success:
                StatusStyleExpr := 'Favorable';
            Rec.Status::Error:
                StatusStyleExpr := 'Unfavorable';
            else
                StatusStyleExpr := '';
        end;
    end;

    local procedure SetErrorFields()
    begin
        ErrorMessage := '';
        ErrorCallStack := '';

        if Rec.Status = Rec.Status::Error then begin
            ErrorCallStack := Rec.GetErrorCallStack();
            ErrorMessage := Rec.GetMessage();
        end;
    end;

    local procedure SetInputOutputDataFields()
    begin
        InputText := '';
        OutputText := '';

        if Rec.Sensitive and not ShowSensitiveData then begin
            Rec.CalcFields("Input Data", "Output Data");
            if Rec."Input Data".Length > 0 then
                InputText := ClickToShowLbl;
            if Rec."Output Data".Length > 0 then
                OutputText := ClickToShowLbl;
        end else begin
            InputText := Rec.GetInputBlob();
            OutputText := Rec.GetOutputBlob();
        end;
    end;
}