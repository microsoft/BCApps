namespace System.Security.AccessControl;

using System.TestTools;
using System.TestTools.TestRunner;

permissionset 4773 "TEST TOOL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Test Tool';

    Permissions = tabledata "CAL Test Codeunit" = RIMD,
                  tabledata "CAL Test Coverage Map" = RIMD,
                  tabledata "CAL Test Enabled Codeunit" = RIMD,
                  tabledata "CAL Test Line" = RIMD,
                  tabledata "CAL Test Method" = RIMD,
                  tabledata "CAL Test Result" = RIMD,
                  tabledata "CAL Test Suite" = RIMD,
                  tabledata "Semi-Manual Execution Log" = RIMD,
                  tabledata "Semi-Manual Test Wizard" = RIMD;
}
