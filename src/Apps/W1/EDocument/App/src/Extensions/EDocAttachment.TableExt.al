#pragma warning disable AA0247
tableextension 6160 "E-Doc. Attachment" extends "Document Attachment"
{
    fields
    {
#pragma warning disable AS0099 // Preserve existing field IDs for compatibility.
        field(6360; "E-Document Attachment"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(6361; "E-Document Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            TableRelation = "E-Document";
        }
#pragma warning restore AS0099
    }
}
