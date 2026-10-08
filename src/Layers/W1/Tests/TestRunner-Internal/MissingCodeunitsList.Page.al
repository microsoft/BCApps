page 130025 "Missing Codeunits List"
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
                field(Number; Number)
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    if FindFirst() then
                        TestManagement.AddMissingTestCodeunits(Rec, CurrentTestSuite);
                end;
            }
            action(ImportSelectedCodeunits)
            {
                ApplicationArea = All;
                Caption = 'Import Selected Codeunits';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SelectedCodeunits: Record "Integer";
                    TestMgtInternal: Codeunit "Test Management Internal";
                begin
                    CurrPage.SetSelectionFilter(SelectedCodeunits);
                    TestMgtInternal.ImportTestCodeunits(SelectedCodeunits);
                end;
            }
        }
    }

    var
        TestManagement: Codeunit "Test Management";
        CurrentTestSuite: Text[10];

    [Scope('OnPrem')]
    procedure Initialize(var CUIds: Record "Integer" temporary; TestSuiteName: Text[10])
    begin
        CurrentTestSuite := TestSuiteName;
        Copy(CUIds, true);
    end;
}

