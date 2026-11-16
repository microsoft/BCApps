// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6913 "Exp. Full Per Diem Calculation"
{
    Access = Internal;
    Caption = 'Full Per-Diem Calculation';

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; "Full Calendar Day")
    {
        Caption = 'Full Calendar Day';
    }
    value(2; "24-hour Rolling Period")
    {
        Caption = '24-hour Rolling Period';
    }
    value(3; "Overnight Stay")
    {
        Caption = 'Overnight Stay';
    }
}