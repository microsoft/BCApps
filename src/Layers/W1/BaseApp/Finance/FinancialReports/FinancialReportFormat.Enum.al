// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 8390 "Financial Report Format"
{
    Caption = 'Financial Report Format';
    Extensible = false;

    value(0; View) { Caption = 'View'; }
    value(1; PDF) { Caption = 'PDF'; }
    value(2; Excel) { Caption = 'Excel'; }
}