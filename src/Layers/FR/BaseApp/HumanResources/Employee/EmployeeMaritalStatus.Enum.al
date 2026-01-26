// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
enum 5226 "Employee Marital Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; Single) { Caption = 'Single'; }
    value(2; Married) { Caption = 'Married'; }
    value(3; Divorced) { Caption = 'Divorced'; }
    value(4; Widowed) { Caption = 'Widowed'; }
}
