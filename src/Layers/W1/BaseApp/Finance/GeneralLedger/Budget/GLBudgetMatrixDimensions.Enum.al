// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

enum 114 "G/L Budget Matrix Dimensions"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "G/L Account") { Caption = 'G/L Account'; }
    value(1; "Period") { Caption = 'Period'; }
    value(2; "Business Unit") { Caption = 'Business Unit'; }
    value(3; "Global Dimension 1") { Caption = 'Global Dimension 1'; }
    value(4; "Global Dimension 2") { Caption = 'Global Dimension 2'; }
    value(5; "Budget Dimension 1") { Caption = 'Budget Dimension 1'; }
    value(6; "Budget Dimension 2") { Caption = 'Budget Dimension 2'; }
    value(7; "Budget Dimension 3") { Caption = 'Budget Dimension 3'; }
    value(8; "Budget Dimension 4") { Caption = 'Budget Dimension 4'; }
    value(99; "Undefined") { Caption = ''; }
}
