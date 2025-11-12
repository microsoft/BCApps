page 103117 "Test Iteration Subform"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Test Iteration";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Iteration No.";"Iteration No.")
                {
                    Editable = false;
                }
                field("Step No.";"Step No.")
                {
                    Editable = false;
                }
                field("Stop After";"Stop After")
                {

                    trigger OnValidate()
                    var
                        TestIteration: Record "Test Iteration";
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

