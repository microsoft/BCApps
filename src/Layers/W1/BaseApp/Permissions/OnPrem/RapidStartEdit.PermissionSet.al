namespace System.Security.AccessControl;

using System.IO;
using Microsoft.API;

permissionset 2800 "RapidStart - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'RapidStart Services';

    Permissions = tabledata "API Entities Setup" = RIMD,
                  tabledata "Config. Field Map" = RIMD,
                  tabledata "Config. Line" = RIMD,
                  tabledata "Config. Media Buffer" = RIMD,
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
                  tabledata "DataExch-RapidStart Buffer" = RIMD,
                  tabledata "RapidStart Services Cue" = R,
                  tabledata "Tenant Config. Package File" = RIMD;
}
