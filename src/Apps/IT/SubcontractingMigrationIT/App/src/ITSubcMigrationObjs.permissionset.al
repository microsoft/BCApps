#if not CLEAN29
namespace Microsoft.Manufacturing.Subcontracting.Migration;

permissionset 149951 "ITSubcMigration-Objs"
{
    Assignable = true;
    Caption = 'IT Subcontracting Migration - Objects';
    Access = Internal;
    Permissions = codeunit "IT Subc. Migration" = X;

    ObsoleteState = Pending;
    ObsoleteReason = 'The legacy subcontracting feature is being deprecated.';
    ObsoleteTag = '29.0';
}
#endif
