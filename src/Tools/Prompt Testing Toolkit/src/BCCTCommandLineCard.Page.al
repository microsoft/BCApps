// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Environment;

page 149042 "BCCT CommandLine Card"
{
    Caption = 'BCCT CommandLine Runner';
    PageType = Card;
    Extensible = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Select Code"; BCCTCode)
                {
                    Caption = 'Select Code', Locked = true;
                    ToolTip = 'Specifies the ID of the suite.';
                    ApplicationArea = All;
                    TableRelation = "BCCT Header".Code;

                    trigger OnValidate()
                    var
                        BCCTHeader: record "BCCT Header";
                        BCCTLine: record "BCCT Line";
                    begin
                        if not BCCTHeader.Get(BCCTCode) then
                            Error(CannotFindBCCTSuiteErr, BCCTCode);

                        //BCCTHeader.CalcFields("Total No. of Sessions");
                        CurrentBCCTHeader := BCCTHeader;
                        BCCTLine.SetRange("BCCT Code", BCCTCode);
                        NoOfTests := BCCTLine.Count();
                    end;
                }

                field("Duration (minutes)"; DurationInMins)
                {
                    Caption = 'Duration (minutes)', Locked = true;
                    ToolTip = 'Specifies the duration the suite will be run.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("No. of Instances"; NoOfInstances)
                {
                    Caption = 'No. of Instances', Locked = true;
                    ToolTip = 'Specifies the number of instances that will be created.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("No. of Tests"; NoOfTests)
                {
                    Caption = 'No. of Tests', Locked = true;
                    ToolTip = 'Specifies the number of BCCT Suite Lines present in the BCCT Suite';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(StartNext)
            {
                Enabled = EnableActions;
                ApplicationArea = All;
                Caption = 'Start Next', Locked = true;
                Image = Start;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Starts the next available test.';

                trigger OnAction()
                begin
                    StartNextBCCT();
                end;
            }
            // action(StartNextPRT)
            // {
            //     Enabled = EnableActions;
            //     ApplicationArea = All;
            //     Caption = 'Start Next in Single Run mode', Locked = true;
            //     Image = Start;
            //     Promoted = true;
            //     PromotedOnly = true;
            //     PromotedCategory = Process;
            //     ToolTip = 'Starts the next available test in PRT mode.';

            //     trigger OnAction()
            //     begin
            //         StartNextBCCTAsPRT();
            //     end;
            // }
        }
    }

    var
        CurrentBCCTHeader: Record "BCCT Header";
        CannotFindBCCTSuiteErr: Label 'The specified BCCT Suite with code %1 cannot be found.', Comment = '%1 = BCCT Suite id.';
        EnableActions: Boolean;
        BCCTCode: Code[10];
        DurationInMins: Integer;
        NoOfInstances: Integer;
        NoOfTests: Integer;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        EnableActions := (EnvironmentInformation.IsSaas() and EnvironmentInformation.IsSandbox()) or EnvironmentInformation.IsOnPrem();
    end;

    local procedure StartNextBCCT()
    var
        BCCTStartTests: Codeunit "BCCT Start Tests";
    begin
        // if CurrentBCCTHeader.CurrentRunType <> CurrentBCCTHeader.CurrentRunType::BCCT then begin
        //     CurrentBCCTHeader.LockTable();
        //     CurrentBCCTHeader.Find();
        //     CurrentBCCTHeader.CurrentRunType := CurrentBCCTHeader.CurrentRunType::BCCT;
        //     CurrentBCCTHeader.Modify();
        //     Commit();
        // end;
        BCCTStartTests.StartNextBenchmarkTests(CurrentBCCTHeader);
        CurrentBCCTHeader.Find();
    end;

    // local procedure StartNextBCCTAsPRT()
    // var
    //     BCCTStartTests: Codeunit "BCCT Start Tests";
    // begin
    //     //CurrentBCCTHeader.CurrentRunType := CurrentBCCTHeader.CurrentRunType::PRT;
    //     CurrentBCCTHeader.Modify();
    //     BCCTStartTests.StartNextBenchmarkTests(CurrentBCCTHeader);
    // end;
}