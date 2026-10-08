page 130203 "Call Stack FactBox"
{
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    ShowFilter = false;
    SourceTable = "Test Result";

    layout
    {
        area(content)
        {
            field(CallStack; CallStack)
            {
                ApplicationArea = All;
                MultiLine = true;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        InStr: InStream;
    begin
        CalcFields("Call Stack");
        "Call Stack".CreateInStream(InStr);
        InStr.ReadText(CallStack)
    end;

    var
        CallStack: Text;
}

