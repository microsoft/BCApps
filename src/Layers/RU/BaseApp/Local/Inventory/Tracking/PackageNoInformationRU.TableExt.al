#if not CLEANSCHEMA28
namespace Microsoft.Inventory.Tracking;

tableextension 14958 "Package No. Information RU" extends "Package No. Information"
{
    fields
    {
#pragma warning disable AS0072
#pragma warning restore AS0072
#if not CLEANSCHEMA28
        field(40; "Current No."; Code[6])
        {
            Caption = 'Current No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Not used.';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
    }
}
#endif