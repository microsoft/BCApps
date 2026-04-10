namespace System.Automation;

query 1502 "Workflow Definition"
{
    Caption = 'Workflow Definition';
    OrderBy = ascending(Sequence_No);

    elements
    {
        dataitem(Workflow; Workflow)
        {
            column("Code"; "Code")
            {
            }
            column(Workflow_Description; Description)
            {
            }
            column(Enabled; Enabled)
            {
            }
            column(Template; Template)
            {
            }
            dataitem(Workflow_Step; "Workflow Step")
            {
                DataItemLink = "Workflow Code" = Workflow.Code;
                SqlJoinType = InnerJoin;
                column(ID; ID)
                {
                }
                column(Step_Description; Description)
                {
                }
                column(Entry_Point; "Entry Point")
                {
                }
                column(Type; Type)
                {
                }
                column(Function_Name; "Function Name")
                {
                }
                column(Argument; Argument)
                {
                }
                column(Sequence_No; "Sequence No.")
                {
                }
                dataitem(Workflow_Event; "Workflow Event")
                {
                    DataItemLink = "Function Name" = Workflow_Step."Function Name";
                    column(Table_ID; "Table ID")
                    {
                    }
                }
            }
        }
    }
}

