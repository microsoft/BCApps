// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

enum 10723 "ES Document Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Open") { Caption = 'Open'; }
    value(2; "Honored") { Caption = 'Honored'; }
    value(3; "Rejected") { Caption = 'Rejected'; }
    value(4; "Redrawn") { Caption = 'Redrawn'; }
}
