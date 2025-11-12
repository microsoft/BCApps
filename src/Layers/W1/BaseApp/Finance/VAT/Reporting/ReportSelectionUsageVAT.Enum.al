// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 584 "Report Selection Usage VAT"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "VAT Statement") { Caption = 'VAT Statement'; }
    value(1; "Sales VAT Adv. Not. Acc") { Caption = 'Sales VAT Adv. Not. Acc'; }
    value(2; "VAT Statement Schedule") { Caption = 'VAT Statement Schedule'; }
}
