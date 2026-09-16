#if not CLEAN28
namespace Microsoft.Manufacturing.Subcontracting.Migration;

permissionset 149951 "ITSubcMigration-Objs"
{
    Assignable = true;
    Caption = 'IT Subcontracting Migration - Objects';
    Access = Internal;
    Permissions = codeunit "IT Subc. Migration" = X;

    ObsoleteState = Pending;
    ObsoleteReason = 'The legacy subcontracting feature is being deprecated.';
    ObsoleteTag = '28.0';
}
#endif
