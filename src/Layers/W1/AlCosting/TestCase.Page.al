page 103116 "Test Case"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    PageType = Card;
    SourceTable = "Test Case";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
            part(TestCases; "Test Iteration Subform")
            {
                SubPageLink = "Use Case No." = FIELD("Use Case No."),
                              "Test Case No." = FIELD("Test Case No.");
                SubPageView = sorting("Use Case No.", "Test Case No.", "Iteration No.");
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
                        TestIteration: Record "Test Iteration";
                        Testscript: Codeunit Testscript;
                    begin
                        TestIteration.Reset();
                        TestIteration.SetRange("Use Case No.", "Use Case No.");
                        TestIteration.SetRange("Test Case No.", "Test Case No.");
                        TestIteration.SetRange("Stop After", true);
                        if TestIteration.FindFirst() then begin
                            Testscript.SetLastIteration(
                              "Use Case No.", "Test Case No.", TestIteration."Iteration No.", TestIteration."Step No.");
                            Testscript.SetKeepUseCases(true);
                            Testscript.SetShowScriptResults(true);
                            Testscript.Run();
                            TestIteration."Stop After" := false;
                            TestIteration.Modify();
                        end else begin
                            Testscript.SetLastIteration("Use Case No.", "Test Case No.", 0, 0);
                            Testscript.SetKeepUseCases(true);
                            Testscript.SetShowScriptResults(true);
                            Testscript.Run();
                        end;
                    end;
                }
                action("Create Iterations")
                {
                    Caption = 'Create Iterations';

                    trigger OnAction()
                    var
                        TestSetupMgmt: Codeunit TestSetupManagement;
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
        UseCase: Record "Use Case";

    [Scope('OnPrem')]
    procedure GetUseCase()
    begin
        UseCase.Get("Use Case No.");
    end;

    local procedure UseCaseNoOnAfterValidate()
    begin
        GetUseCase();
    end;
}

