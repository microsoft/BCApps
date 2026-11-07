page 130202 "Test Result List"
{
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Test Result";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Repeater';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }
                field("Test Run No."; "Test Run No.")
                {
                    ApplicationArea = All;
                }
                field(CUId; CUId)
                {
                    ApplicationArea = All;
                }
                field(CUName; CUName)
                {
                    ApplicationArea = All;
                }
                field(FName; FName)
                {
                    ApplicationArea = All;
                }
                field(Platform; Platform)
                {
                    ApplicationArea = All;
                }
                field(Result; Result)
                {
                    ApplicationArea = All;
                }
                field(Restore; Restore)
                {
                    ApplicationArea = All;
                }
                field("Execution Time"; "Execution Time")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; "Error Message")
                {
                    ApplicationArea = All;
                }
                field(File; File)
                {
                    ApplicationArea = All;
                }
                field(Database; Database)
                {
                    ApplicationArea = All;
                }
            }
        }
        area(factboxes)
        {
            part(CallStackFactBox; "Call Stack FactBox")
            {
                ApplicationArea = All;
                Caption = 'CallStackFactBox';
                SubPageLink = "No." = field("No.");
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("Call Stack")
            {
                ApplicationArea = All;
                Caption = 'Call Stack';
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;

                trigger OnAction()
                var
                    InStr: InStream;
                    CallStack: Text;
                begin
                    CalcFields("Call Stack");
                    "Call Stack".CreateInStream(InStr);
                    InStr.ReadText(CallStack);
                    Message(CallStack)
                end;
            }
        }
    }
}

