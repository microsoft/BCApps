#if not CLEAN29
namespace Microsoft.Manufacturing.Subcontracting.Migration.Test;

table 149957 "IT Subc. Migration Test Sync"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Status; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = Created,"At Lock Boundary",Succeeded,Failed;
        }
        field(3; "Error Text"; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
#endif
