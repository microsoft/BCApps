// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

enum 727 "Analysis Dimension Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "G/L Account") { Caption = 'G/L Account'; }
    value(1; "Period") { Caption = 'Period'; }
    value(2; "Business Unit") { Caption = 'Business Unit'; }
    value(3; "Dimension 1") { Caption = 'Dimension 1'; }
    value(4; "Dimension 2") { Caption = 'Dimension 2'; }
    value(5; "Dimension 3") { Caption = 'Dimension 3'; }
    value(6; "Dimension 4") { Caption = 'Dimension 4'; }
    value(7; "Cash Flow Account") { Caption = 'Cash Flow Account'; }
    value(8; "Cash Flow Forecast") { Caption = 'Cash Flow Forecast'; }
    value(99; "Undefined") { Caption = 'Undefined'; }
}
