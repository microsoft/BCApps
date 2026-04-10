// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

enum 99000763 "Routing Time Type"
{
    AssignmentCompatibility = true;


    value(0; "Setup Time")
    {
        Caption = 'Setup Time';
    }
    value(1; "Run Time")
    {
        Caption = 'Run Time';
    }
    value(2; "Wait Time")
    {
        Caption = 'Wait Time';
    }
    value(3; "Move Time")
    {
        Caption = 'Move Time';
    }
    value(4; "Queue Time")
    {
        Caption = 'Queue Time';
    }
}
