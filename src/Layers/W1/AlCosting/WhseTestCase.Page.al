page 103202 "Whse. Test Case"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Whse. Test Case';
    PageType = Card;
    SourceTable = "Whse. Test Case";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Project Code"; "Project Code")
                {
                    Editable = false;
                }
                field("Use Case No."; "Use Case No.")
                {
                    Editable = false;

                    trigger OnValidate()
                    begin
                        UseCaseNoOnAfterValidate();
                    end;
                }
                field("UseCase.Description"; UseCase.Description)
                {
                    Editable = false;
                    ShowCaption = false;
                }
                field("Test Case No."; "Test Case No.")
                {
                    Editable = false;
                }
                field(Description; Description)
                {
                    Editable = false;
                }
            }
            part(TestCases; "WMS Test Iteration Subform")
            {
                SubPageLink = "Project Code" = FIELD("Project Code"),
                              "Use Case No." = FIELD("Use Case No."),
                              "Test Case No." = FIELD("Test Case No.");
                SubPageView = sorting("Project Code", "Use Case No.", "Test Case No.", "Iteration No.", "Step No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("F&unction")
            {
                Caption = 'F&unction';
                action("Perform Testcase")
                {
                    Caption = 'Perform Testcase';

                    trigger OnAction()
                    var
                        TestIteration: Record "Whse. Test Iteration";
                        TestscriptWMS: Codeunit "WMS Testscript";
                        TestscriptBW: Codeunit "BW Testscript";
                    begin
                        TestIteration.Reset();
                        TestIteration.SetRange("Project Code", "Project Code");
                        TestIteration.SetRange("Use Case No.", "Use Case No.");
                        TestIteration.SetRange("Test Case No.", "Test Case No.");
                        TestIteration.SetRange("Stop After", true);
                        if TestIteration.Find('-') then
                            case "Project Code" of
                                'WMS':
                                    begin
                                        TestscriptWMS.SetLastIteration(
                                          "Use Case No.", "Test Case No.", TestIteration."Iteration No.", TestIteration."Step No.", "Project Code");
                                        TestscriptWMS.SetKeepUseCases(true);
                                        TestscriptWMS.SetShowTestResults(true);
                                        TestscriptWMS.Run();
                                        TestIteration."Stop After" := false;
                                        TestIteration.Modify();
                                    end;
                                'BW':
                                    begin
                                        TestscriptBW.SetLastIteration(
                                          "Use Case No.", "Test Case No.", TestIteration."Iteration No.", TestIteration."Step No.", "Project Code");
                                        TestscriptBW.SetKeepUseCases(true);
                                        TestscriptBW.SetShowScriptResult(true);
                                        TestscriptBW.Run();
                                        TestIteration."Stop After" := false;
                                        TestIteration.Modify();
                                    end;
                            end
                        else
                            case "Project Code" of
                                'WMS':
                                    begin
                                        TestscriptWMS.SetLastIteration("Use Case No.", "Test Case No.", 0, 0, "Project Code");
                                        TestscriptWMS.SetKeepUseCases(true);
                                        TestscriptWMS.SetShowTestResults(true);
                                        TestscriptWMS.Run();
                                    end;
                                'BW':
                                    begin
                                        TestscriptBW.SetLastIteration("Use Case No.", "Test Case No.", 0, 0, "Project Code");
                                        TestscriptBW.SetKeepUseCases(true);
                                        TestscriptBW.SetShowScriptResult(true);
                                        TestscriptBW.Run();
                                    end;
                            end;
                    end;
                }
                action("Create Iterations")
                {
                    Caption = 'Create Iterations';

                    trigger OnAction()
                    var
                        TestSetupMgmt: Codeunit "WMS TestSetupManagement";
                    begin
                        TestSetupMgmt.CreateIterations(Rec, false, true);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetUseCase();
    end;

    var
        UseCase: Record "Whse. Use Case";

    [Scope('OnPrem')]
    procedure GetUseCase()
    begin
        UseCase.Get("Project Code", "Use Case No.");
    end;

    local procedure UseCaseNoOnAfterValidate()
    begin
        GetUseCase();
    end;
}

