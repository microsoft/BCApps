#if not CLEANSCHEMA30
namespace Microsoft.API;

using System.Apps;

table 5447 "API Extension Upload"
{
    ObsoleteReason = 'Use the Business Central admin center API to upload per-tenant extensions.';
#if not CLEAN30
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteTag = '30.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; Schedule; Enum "Extension Deploy To")
        {
            Caption = 'Schedule';
            DataClassification = SystemMetadata;
        }
        field(3; "Schema Sync Mode"; Enum "Extension Sync Mode")
        {
            Caption = 'Schema Sync Mode';
            DataClassification = SystemMetadata;
        }
        field(20; Content; Blob)
        {
            Caption = 'Content';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#endif