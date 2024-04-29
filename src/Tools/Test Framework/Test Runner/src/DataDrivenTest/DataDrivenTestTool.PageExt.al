pageextension 130451 MyExtension extends "AL Test Tool"
{
    layout
    {
        addafter(Name)
        {
            field("Data Input"; Rec."Data Input")
            {
                ApplicationArea = All;
                Caption = 'Data Input';
                ToolTip = 'Data input for the test method line';
            }
        }
    }
    actions
    {
        addafter(RunTests)
        {
            action(ImportDataInputs)
            {
                ApplicationArea = All;
                Caption = 'Import data-driven test inputs';
                Image = ImportCodes;

                trigger OnAction()
                var
                    ALTestSuite: Record "AL Test Suite";
                    ImportDataDrivenTests: Codeunit "Import Data Driven Test";
                begin
                    ALTestSuite.Get(Rec."Test Suite");
                    ImportDataDrivenTests.UploadAndImportDataInputsFromJson(ALTestSuite);
                end;
            }
            action(ImportTestDefinitions)
            {
                ApplicationArea = All;
                Caption = 'Import data-driven test definitions';
                Image = ImportLog;

                trigger OnAction()
                var
                    ALTestSuite: Record "AL Test Suite";
                    ImportDataDrivenTests: Codeunit "Import Data Driven Test";
                begin
                    ALTestSuite.Get(Rec."Test Suite");
                    ImportDataDrivenTests.UploadAndImportTestDefinitions(ALTestSuite);
                end;
            }
            action(DataInputs)
            {
                ApplicationArea = All;
                Caption = 'Data inputs';
                Image = TestFile;
                trigger OnAction()
                var
                    TestInput: Record "Test Input";
                begin
                    TestInput.SetRange("Test Suite", Rec."Test Suite");
                    Page.Run(Page::"Test Inputs", TestInput);
                end;
            }
            action(DataOutput)
            {
                ApplicationArea = All;
                Caption = 'Data output';
                Image = Export;
                trigger OnAction()
                var
                    TestOutput: Codeunit "Test Output";
                begin
                    Message(TestOutput.GetAllTestOutput().ToText());
                end;
            }
            action(ClearDataOutput)
            {
                ApplicationArea = All;
                Caption = 'Clear data output';
                Image = ClearLog;

                trigger OnAction()
                var
                    TestOutput: Codeunit "Test Output";
                begin
                    Clear(TestOutput);
                end;
            }
        }

        addlast(Category_Process)
        {
            group(DataDrivenTest)
            {
                Caption = 'Data-Driven Test';
                Image = TestReport;

                actionref(ImportDefinition_Promoted; ImportDataInputs)
                {
                }
                actionref(ImportTestDefinitions_Promoted; ImportTestDefinitions)
                {
                }
                actionref(DataInputs_Promoted; DataInputs)
                {
                }
                actionref(DataOutput_Promoted; DataOutput)
                {
                }
                actionref(ClearDataOutput_Promoted; ClearDataOutput)
                {
                }
            }
        }
    }
}