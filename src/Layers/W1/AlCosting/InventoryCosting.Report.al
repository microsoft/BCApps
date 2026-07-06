report 103900 "Inventory Costing"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ExmplDataInvtCost: Codeunit "Exmpl Data - Inventory Costing";
    begin
        ExmplDataInvtCost.CreateExmplData(ExampleNo);
    end;

    var
        ExampleNo: Integer;
}

