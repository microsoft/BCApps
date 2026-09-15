page 103222 "WMS Test Iteration Subform"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'WMS Test Iteration Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Whse. Test Iteration";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Iteration No.";"Iteration No.")
                {
                }
                field("Step No.";"Step No.")
                {
                }
                field("Test Case No.";"Test Case No.")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Stop After";"Stop After")
                {

                    trigger OnValidate()
                    var
                        TestIteration: Record "Whse. Test Iteration";
                    begin
                        if "Stop After" then begin
                          FilterGroup(4);
                          TestIteration.CopyFilters(Rec);
                          Reset();
                          ModifyAll("Stop After",false);
                          "Stop After" := true;
                          Modify();
                          CopyFilters(TestIteration);
                          FilterGroup(0);
                        end;
                    end;
                }
                field(Description;Description)
                {
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }
}

