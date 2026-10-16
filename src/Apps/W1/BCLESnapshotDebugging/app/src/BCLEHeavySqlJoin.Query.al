namespace Microsoft.Samples.BCLESnapshotDebugging;

query 70956 "BCLE Heavy SQL Join"
{
    elements
    {
        dataitem(OuterBuffer; "BCLE Profiling Buffer")
        {
            DataItemTableFilter = "Category Code" = const('BCLE-SLOW-SQL');

            column(OuterEntryNo; "Entry No.")
            {
            }

            dataitem(InnerBuffer; "BCLE Profiling Buffer")
            {
                DataItemLink = "Category Code" = OuterBuffer."Category Code";
                SqlJoinType = InnerJoin;

                column(JoinedRows)
                {
                    Method = Count;
                }
            }
        }
    }
}
