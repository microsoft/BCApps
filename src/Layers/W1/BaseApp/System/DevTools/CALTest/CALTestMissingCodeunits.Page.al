namespace System.TestTools.TestRunner;

using System.Utilities;

page 130404 "CAL Test Missing Codeunits"
{
    Caption = 'Missing Codeunits List';
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Integer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater("<Codeunit List>")
            {
                Caption = 'Codeunit List';
                field(Number; Rec.Number)
                {
                    ApplicationArea = All;
                    Caption = 'Codeunit ID';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Retry)
            {
                ApplicationArea = All;
                Caption = 'Retry';
                Image = Refresh;

                trigger OnAction()
                begin
                    if Rec.FindFirst() then
                        CALTestMgt.AddMissingTestCodeunits(Rec, CurrentTestSuite);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Retry_Promoted; Retry)
                {
                }
            }
        }
    }

    var
        CALTestMgt: Codeunit "CAL Test Management";
        CurrentTestSuite: Code[10];

    [Scope('OnPrem')]
    procedure Initialize(var CUIds: Record "Integer" temporary; TestSuiteName: Code[10])
    begin
        CurrentTestSuite := TestSuiteName;
        Rec.Copy(CUIds, true);
    end;
}

