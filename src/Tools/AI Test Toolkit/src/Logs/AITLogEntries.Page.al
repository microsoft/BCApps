// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149033 "AIT Log Entries"
{
    Caption = 'AI Log Entries';
    PageType = List;
    Editable = false;
    SourceTable = "AIT Log Entry";
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                FreezeColumn = Status;

                field(RunID; Rec."Run ID")
                {
                    ToolTip = 'Specifies the AIT RunID Guid.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field("Code"; Rec."Test Suite Code")
                {
                    ToolTip = 'Specifies the AIT Code of the AIT.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field("AIT Line No."; Rec."Test Method Line No.")
                {
                    ToolTip = 'Specifies the Line No. of the AIT.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the Entry No. of the AIT.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field(Version; Rec.Version)
                {
                    Caption = 'Version No.';
                    ToolTip = 'Specifies the Version No. of the AIT execution.';
                    ApplicationArea = All;
                }
                field(Tag; Rec.Tag)
                {
                    ToolTip = 'Specifies the Tag that we entered in the AIT Test Suite.';
                    ApplicationArea = All;
                }
                field(CodeunitID; Rec."Codeunit ID")
                {
                    ToolTip = 'Specifies the codeunit id of the AIT.';
                    ApplicationArea = All;
                }
                field(CodeunitName; Rec."Codeunit Name")
                {
                    ToolTip = 'Specifies the codeunit name of the AIT.';
                    ApplicationArea = All;
                }
                field(Operation; Rec.Operation)
                {
                    ToolTip = 'Specifies the single operation of the AIT.';
                    ApplicationArea = All;
                    Visible = false;
                    Enabled = false;
                }
                field("Procedure Name"; Rec."Procedure Name")
                {
                    ToolTip = 'Specifies the name of the procedure being executed.';
                    ApplicationArea = All;
                }
                field("Original Operation"; Rec."Original Operation")
                {
                    ToolTip = 'Specifies the original operation of the AIT.';
                    Visible = false;
                    Enabled = false;
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the iteration.';
                    ApplicationArea = All;
                    StyleExpr = this.StatusStyleExpr;
                }
                field("Orig. Status"; Rec."Original Status")
                {
                    Caption = 'Orig. Status';
                    Visible = false;
                    ToolTip = 'Specifies the original status of the iteration.';
                    ApplicationArea = All;
                }
                field(Dataset; Rec."Test Input Group Code")
                {
                    ToolTip = 'Specifies the dataset of the AIT.';
                    ApplicationArea = All;
                }
                field("Dataset Line No."; Rec."Test Input Code")
                {
                    ToolTip = 'Specifies the Line No. of the dataset.';
                    ApplicationArea = All;
                }
                field("Input Dataset Desc."; Rec."Test Input Description")
                {
                    ToolTip = 'Specifies the description of the input dataset.';
                    ApplicationArea = All;
                }
                field("Input Text"; this.InputText)
                {
                    Caption = 'Input';
                    ToolTip = 'Specifies the test input of the AIT.';
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        Message(Rec.GetInputBlob());
                    end;
                }
                field("Output Text"; this.OutputText)
                {
                    Caption = 'Test Output';
                    ToolTip = 'Specifies the test output of the AIT.';
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        Message(Rec.GetOutputBlob());
                    end;
                }
                field(TestRunDuration; this.TestRunDuration)
                {
                    Caption = 'Duration';
                    ToolTip = 'Specifies the duration of the iteration.';
                    ApplicationArea = All;
                }
                field(StartTime; Format(Rec."Start Time", 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2><Second dec.>'))
                {
                    Caption = 'Start Time';
                    ToolTip = 'Specifies the start time of the test.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(EndTime; Format(Rec."End Time", 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2><Second dec.>'))
                {
                    Caption = 'End Time';
                    ToolTip = 'Specifies the end time of the test.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Message; this.ErrorMessage)
                {
                    Caption = 'Error Message';
                    ToolTip = 'Specifies when the error message from the test.';
                    ApplicationArea = All;
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    begin
                        Message(this.ErrorMessage);
                    end;
                }
                field("Orig. Message"; Rec."Original Message")
                {
                    Caption = 'Orig. Message';
                    Visible = false;
                    ToolTip = 'Specifies the original message from the test.';
                    ApplicationArea = All;
                }
                field("Error Call Stack"; this.ErrorCallStack)
                {
                    Caption = 'Call stack';
                    Editable = false;
                    ToolTip = 'Specifies the call stack for this error.';
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        Message(this.ErrorCallStack);
                    end;
                }
                field("Log was Modified"; Rec."Log was Modified")
                {
                    Caption = 'Log was Modified';
                    ToolTip = 'Specifies if the log was modified by any event subscribers.';
                    Visible = false;
                    ApplicationArea = All;
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
                ApplicationArea = All;
                Caption = 'Delete entries within filter';
                Image = Delete;
                ToolTip = 'Deletes all the log entries.';

                trigger OnAction()
                begin
                    if not Confirm(this.DoYouWantToDeleteQst, false) then
                        exit;

                    Rec.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
            action(ShowErrors)
            {
                ApplicationArea = All;
                Visible = not this.IsFilteredToErrors;
                Caption = 'Show errors';
                Image = FilterLines;
                ToolTip = 'Shows only errors.';

                trigger OnAction()
                begin
                    Rec.SetRange(Status, Rec.Status::Error);
                    this.IsFilteredToErrors := true;
                    CurrPage.Update(false);
                end;
            }
            action(ClearShowErrors)
            {
                ApplicationArea = All;
                Visible = this.IsFilteredToErrors;
                Caption = 'Show success and errors';
                Image = RemoveFilterLines;
                ToolTip = 'Clears the filter on errors.';

                trigger OnAction()
                begin
                    Rec.SetRange(Status);
                    this.IsFilteredToErrors := false;
                    CurrPage.Update(false);
                end;
            }
            action("Show Sensitive Data")
            {
                ApplicationArea = All;
                Caption = 'Show sensitive data';
                Image = ShowWarning;
                Visible = not this.ShowSensitiveData;
                ToolTip = 'Use this action to make sensitive data visible.';

                trigger OnAction()
                begin
                    this.ShowSensitiveData := true;
                    CurrPage.Update(false);
                end;
            }
            action("Hide Sensitive Data")
            {
                ApplicationArea = All;
                Caption = 'Hide sensitive data';
                Image = RemoveFilterLines;
                Visible = this.ShowSensitiveData;
                ToolTip = 'Use this action to hide sensitive data.';

                trigger OnAction()
                begin
                    this.ShowSensitiveData := false;
                    CurrPage.Update(false);
                end;
            }
            action("Download Test Output")
            {
                ApplicationArea = All;
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
        this.TestRunDuration := Rec."Duration (ms)";
        this.SetInputOutputDataFields();
        this.SetErrorFields();
        this.SetStatusStyleExpr();
    end;

    local procedure SetStatusStyleExpr()
    begin
        case Rec.Status of
            Rec.Status::Success:
                this.StatusStyleExpr := 'Favorable';
            Rec.Status::Error:
                this.StatusStyleExpr := 'Unfavorable';
            else
                this.StatusStyleExpr := '';
        end;
    end;

    local procedure SetErrorFields()
    begin
        this.ErrorMessage := '';
        this.ErrorCallStack := '';

        if Rec.Status = Rec.Status::Error then begin
            ErrorCallStack := Rec.GetErrorCallStack();
            ErrorMessage := Rec.GetMessage();
        end;
    end;

    local procedure SetInputOutputDataFields()
    begin
        this.InputText := '';
        this.OutputText := '';

        if Rec.Sensitive and not this.ShowSensitiveData then begin
            Rec.CalcFields("Input Data", "Output Data");
            if Rec."Input Data".Length > 0 then
                this.InputText := ClickToShowLbl;
            if Rec."Output Data".Length > 0 then
                this.OutputText := ClickToShowLbl;
        end else begin
            this.InputText := Rec.GetInputBlob();
            this.OutputText := Rec.GetOutputBlob();
        end;
    end;
}