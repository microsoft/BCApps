// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

enum 12116 "Withholding Tax Reason"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "A") { Caption = 'A'; }
    value(2; "B") { Caption = 'B'; }
    value(3; "C") { Caption = 'C'; }
    value(4; "D") { Caption = 'D'; }
    value(5; "E") { Caption = 'E'; }
    value(6; "G") { Caption = 'G'; }
    value(7; "H") { Caption = 'H'; }
    value(8; "I") { Caption = 'I'; }
    value(9; "L") { Caption = 'L'; }
    value(10; "L1") { Caption = 'L1'; }
    value(11; "M") { Caption = 'M'; }
    value(12; "M1") { Caption = 'M1'; }
    value(13; "M2") { Caption = 'M2'; }
    value(14; "N") { Caption = 'N'; }
    value(15; "O") { Caption = 'O'; }
    value(16; "O1") { Caption = 'O1'; }
    value(17; "P") { Caption = 'P'; }
    value(18; "Q") { Caption = 'Q'; }
    value(19; "R") { Caption = 'R'; }
    value(20; "S") { Caption = 'S'; }
    value(21; "T") { Caption = 'T'; }
    value(22; "U") { Caption = 'U'; }
    value(23; "V") { Caption = 'V'; }
    value(24; "V1") { Caption = 'V1'; }
    value(25; "V2") { Caption = 'V2'; }
    value(26; "W") { Caption = 'W'; }
    value(27; "X") { Caption = 'X'; }
    value(28; "Y") { Caption = 'Y'; }
    value(29; "ZO") { Caption = 'ZO'; }
    value(30; "K") { Caption = 'K'; }
}
