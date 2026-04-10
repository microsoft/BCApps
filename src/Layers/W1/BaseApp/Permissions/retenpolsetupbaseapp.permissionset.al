namespace System.Security.AccessControl;

using System.Environment;
using System.Threading;
using System.Utilities;

permissionset 650 "Reten. Pol. Setup - BaseApp"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "Error Message" = IMD,
                  tabledata "Error Message Register" = IMD,
                  tabledata "Job Queue Category" = ri,
                  tabledata "Job Queue Log Entry" = IMD,
                  tabledata "Job Queue Entry" = rim,
                  tabledata "Scheduled Task" = R;
}