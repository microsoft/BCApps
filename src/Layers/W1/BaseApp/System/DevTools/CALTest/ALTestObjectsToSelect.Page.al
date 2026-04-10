namespace System.TestTools.TestRunner;

using System.Reflection;

page 130409 "AL Test Objects To Select"
{
    Caption = 'AL Test Objects To Select';
    Editable = false;
    PageType = List;
    SourceTable = AllObj;
    SourceTableView = where("Object Type" = filter(<> TableData));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec."Object Type")
                {
                    ApplicationArea = All;
                }
                field(ID; Rec."Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID that applies.';
                }
                field(Name; Rec."Object Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the test objects selected.';
                }
                field(HitBy; CountTestCodeunits())
                {
                    ApplicationArea = All;
                    Caption = 'Hit By Test Codeunits';

                    trigger OnDrillDown()
                    begin
                        if CALTestCoverageMap.FindFirst() then
                            PAGE.RunModal(0, CALTestCoverageMap);
                    end;
                }
                field("App Package ID"; Rec."App Package ID")
                {
                    ApplicationArea = All;
                    Caption = 'App Package ID';
                    ToolTip = 'Specifies the GUID of the app from which the object originated.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CALTestCoverageMap.SetRange("Object Type", Rec."Object Type");
        CALTestCoverageMap.SetRange("Object ID", Rec."Object ID");
    end;

    var
        CALTestCoverageMap: Record "CAL Test Coverage Map";

    local procedure CountTestCodeunits(): Integer
    begin
        if CALTestCoverageMap.FindFirst() then begin
            CALTestCoverageMap.CalcFields("Hit by Test Codeunits");
            exit(CALTestCoverageMap."Hit by Test Codeunits");
        end;
        exit(0);
    end;
}

