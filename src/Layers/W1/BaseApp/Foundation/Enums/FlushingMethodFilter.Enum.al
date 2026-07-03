// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

enum 5429 "Flushing Method Filter"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Manual") { Caption = 'Manual'; }
    value(1; "Forward") { Caption = 'Forward'; }
    value(2; "Backward") { Caption = 'Backward'; }
    value(3; "Pick + Forward") { Caption = 'Pick + Forward'; }
    value(4; "Pick + Backward") { Caption = 'Pick + Backward'; }
    value(6; "Pick + Manual") { Caption = 'Pick + Manual'; }
    value(50; "Manual Methods") { Caption = 'Manual methods'; }
    value(5; "All Methods") { Caption = 'All methods'; }
}
