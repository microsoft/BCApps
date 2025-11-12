// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

enum 53 "Gen. Journal Recurring Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "F  Fixed") { Caption = 'F  Fixed'; }
    value(2; "V  Variable") { Caption = 'V  Variable'; }
    value(3; "B  Balance") { Caption = 'B  Balance'; }
    value(4; "RF Reversing Fixed") { Caption = 'RF Reversing Fixed'; }
    value(5; "RV Reversing Variable") { Caption = 'RV Reversing Variable'; }
    value(6; "RB Reversing Balance") { Caption = 'RB Reversing Balance'; }
    value(7; "BD Balance by Dimension") { Caption = 'BD Balance by Dimension'; }
    value(8; "RBD Reversing Balance by Dimension") { Caption = 'RBD Reversing Balance by Dimension'; }
}
