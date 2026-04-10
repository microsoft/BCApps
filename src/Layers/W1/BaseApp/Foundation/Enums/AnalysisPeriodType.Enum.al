// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 362 "Analysis Period Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Day") { Caption = 'Day'; }
    value(1; "Week") { Caption = 'Week'; }
    value(2; "Month") { Caption = 'Month'; }
    value(3; "Quarter") { Caption = 'Quarter'; }
    value(4; "Year") { Caption = 'Year'; }
    value(5; "Accounting Period") { Caption = 'Accounting Period'; }
}
