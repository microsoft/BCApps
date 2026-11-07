// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

enum 10012 "Sales Tax Document Area"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales") { Caption = 'Sales'; }
    value(1; "Purchase") { Caption = 'Purchase'; }
    value(2; "Service") { Caption = 'Service'; }
    value(6; "Posted Sale") { Caption = 'Posted Sale'; }
    value(7; "Posted Purchase") { Caption = 'Posted Purchase'; }
    value(8; "Posted Service") { Caption = 'Posted Service'; }
}
