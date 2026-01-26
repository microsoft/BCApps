// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

enum 13115 "Non-Taxable Income Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "1") { Caption = 'Type 1'; }
    value(2; "2") { Caption = 'Type 2'; }
    value(3; "5") { Caption = 'Type 5'; }
    value(4; "6") { Caption = 'Type 6'; }
    value(5; "7") { Caption = 'Type 7'; }
    value(6; "8") { Caption = 'Type 8'; }
    value(7; "9") { Caption = 'Type 9'; }
    value(8; "10") { Caption = 'Type 10'; }
    value(9; "11") { Caption = 'Type 11'; }
    value(10; "12") { Caption = 'Type 12'; }
    value(11; "13") { Caption = 'Type 13'; }
    value(12; "4") { Caption = 'Type 4'; }
    value(13; "14") { Caption = 'Type 14'; }
    value(14; "21") { Caption = 'Type 21'; }
    value(15; "22") { Caption = 'Type 22'; }
    value(16; "23") { Caption = 'Type 23'; }
    value(17; "24") { Caption = 'Type 24'; }
}
