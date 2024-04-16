page 130459 "Test Inputs"
{
    PageType = List;
    SourceTable = "Test Input";
    Caption = 'Test inputs';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(TestInputs)
            {
                Editable = false;
                field(TestSuite; Rec."Test Suite")
                {
                    ApplicationArea = All;
                }
                field(MethodName; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(InputDescription; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(InputTestInputText; TestInputText)
                {
                    ApplicationArea = All;
                    Caption = 'Test Input';
                    ToolTip = 'Data input for the test method line';

                    trigger OnDrillDown()
                    begin
                        Message(TestInputText);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TestInputText := Rec.GetInput(Rec);
    end;

    var
        TestInputText: Text;
}