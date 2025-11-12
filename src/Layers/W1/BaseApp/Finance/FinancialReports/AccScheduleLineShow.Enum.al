// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 851 "Acc. Schedule Line Show"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Yes")
    {
        Caption = 'Yes';
    }
    value(1; "No")
    {
        Caption = 'No';
    }
    value(2; "If Any Column Not Zero")
    {
        Caption = 'If Any Column Not Zero';
    }
    value(3; "When Positive Balance")
    {
        Caption = 'When Positive Balance';
    }
    value(4; "When Negative Balance")
    {
        Caption = 'When Negative Balance';
    }
}
