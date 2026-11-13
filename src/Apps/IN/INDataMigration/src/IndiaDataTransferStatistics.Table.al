#pragma warning disable AA0247
#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 19298 "India Data Transfer Statistics"
#pragma warning restore AS0103, PTE0004
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            DataClassification = CustomerContent;

        }
        field(2; "Total Companies"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("India Migration Company");
            Editable = false;
        }
        field(3; "Pending Companies"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("India Migration Company" where(Status = filter(<> Completed)));
            Editable = false;
        }
        field(4; "Completed Companies"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("India Migration Company" where(Status = filter(Completed)));
            Editable = false;
        }
        field(5; "Pending Tables"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("India Migration Worksheet" where(Status = filter(<> Completed)));
            Editable = false;
        }
        field(6; "Completed Tables"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("India Migration Worksheet" where(Status = filter(Completed)));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
}
