namespace System.Security.AccessControl;

using System.Environment.Configuration;
using System.IO;

permissionset 5972 "D365 RAPIDSTART"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 RapidStart';

    Permissions = tabledata "Configuration Package File" = RIMD,
                  tabledata "Config. Field Map" = RIMD,
                  tabledata "Config. Line" = RIMD,
                  tabledata "Config. Package" = RIMD,
                  tabledata "Config. Package Data" = RIMD,
                  tabledata "Config. Package Error" = RIMD,
                  tabledata "Config. Package Field" = RIMD,
                  tabledata "Config. Package Filter" = RIMD,
                  tabledata "Config. Package Record" = RIMD,
                  tabledata "Config. Package Table" = RIMD,
                  tabledata "Config. Question" = RIMD,
                  tabledata "Config. Question Area" = RIMD,
                  tabledata "Config. Questionnaire" = RIMD,
                  tabledata "Config. Record For Processing" = RIMD,
                  tabledata "Config. Related Field" = RIMD,
                  tabledata "Config. Related Table" = RIMD,
                  tabledata "Config. Selection" = RIMD,
                  tabledata "Config. Setup" = RIMD,
                  tabledata "Config. Table Processing Rule" = RIMD,
                  tabledata "Config. Template Header" = RIMD,
                  tabledata "Config. Template Line" = RIMD,
                  tabledata "Config. Tmpl. Selection Rules" = RIMD,
                  tabledata "Tenant Config. Package File" = RIMD;
}
