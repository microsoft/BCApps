namespace Microsoft.Test.Foundation.NoSeries;
using System.TestLibraries.Utilities;
#if not CLEAN24
using Microsoft.Foundation.NoSeries;
#endif
permissionset 134530 "No. Series Test"
{
    Assignable = true;
#if not CLEAN24
    Permissions = codeunit "Library Assert" = X,
    tabledata "No. Series Line" = m;
#else
    Permissions = codeunit "Library Assert" = X;
#endif

}