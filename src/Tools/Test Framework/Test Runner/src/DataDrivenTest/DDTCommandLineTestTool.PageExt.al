pageextension 130452 "DDT Command Line Test Tool" extends "Command Line Test Tool"
{
    layout
    {
        addafter(CCResultsCSVText)
        {
            field(DataOutput; DataOutputTxt)
            {
                ApplicationArea = All;
                Caption = 'Data Output';
                ToolTip = 'Data output for the test method line';
            }
            field(DataInput; DataInputTxt)
            {
                ApplicationArea = All;
                Caption = 'Data Input';
                ToolTip = 'Data input for the test method line';

                trigger OnValidate()
                var
                    ImportDataDrivenTest: Codeunit "Import Data Driven Test";
                begin
                    ImportDataDrivenTest.ImportDataInputsFromText(GlobalALTestSuite, DataInputTxt);
                end;
            }
            field(TestDefinitions; TestDefinitionsTxt)
            {
                ApplicationArea = All;
                Caption = 'Test Definitions';
                ToolTip = 'Test definitions for the test method line';

                trigger OnValidate()
                var
                    ImportDataDrivenTest: Codeunit "Import Data Driven Test";
                begin
                    ImportDataDrivenTest.ImportTestDefinitions(GlobalALTestSuite, TestDefinitionsTxt);
                end;
            }
        }
    }

    actions
    {
        addafter(GetCodeCoverageMap)
        {
            action(GetDataOutput)
            {
                ApplicationArea = All;
                Caption = 'Get Data Output';
                ToolTip = 'Specifies the action for invoking GetDataOutput procedure';
                trigger OnAction()
                var
                    TestOutput: Codeunit "Test Output";
                    TestJson: Interface "Test Json";
                begin
                    TestJson := TestOutput.GetAllTestOutput();
                    DataOutputTxt := TestJson.ToText();
                end;
            }
            action(ClearDataOuput)
            {
                ApplicationArea = All;
                Caption = 'Clear Data Output';
                ToolTip = 'Specifies the action for invoking ClearDataOutput procedure';
                trigger OnAction()
                var
                    TestOutput: Codeunit "Test Output";
                begin
                    Clear(TestOutput);
                    DataOutputTxt := '';
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(GetDataOutput_Promoted; GetDataOutput)
            {
            }
            actionref(ClearDataOuput_Promoted; ClearDataOuput)
            {
            }
        }
    }

    var
        DataOutputTxt: Text;
        DataInputTxt: Text;
        TestDefinitionsTxt: Text;
}