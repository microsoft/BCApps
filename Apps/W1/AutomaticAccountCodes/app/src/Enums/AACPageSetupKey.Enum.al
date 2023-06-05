// #if not CLEAN22 // Can't remove the enum until we remove table 4857 "Auto. Acc. Page Setup"

/// <summary>
/// Automatic Acc. feature will be moved to a separate app.
/// </summary>
enum 4853 "AAC Page Setup Key"
{
    ObsoleteReason = 'Automatic Acc.functionality will be moved to a new app.';
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '22.0';
#pragma warning restore AS0072

    value(0; "Automatic Acc. Groups List")
    { }

    value(1; "Automatic Acc. Groups Card")
    { }
}
// #endif