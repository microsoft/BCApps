// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 258 "VAT Statement Line Amount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Amount") { Caption = 'Amount'; }
    value(2; "Base") { Caption = 'Base'; }
    value(3; "Unrealized Amount") { Caption = 'Unrealized Amount'; }
    value(4; "Unrealized Base") { Caption = 'Unrealized Base'; }
    value(6; "Non-Deductible Amount") { Caption = 'Non-Deductible Amount'; }
    value(7; "Non-Deductible Base") { Caption = 'Non-Deductible Base'; }
    value(8; "Full Amount") { Caption = 'Full Amount'; }
    value(9; "Full Base") { Caption = 'Full Base'; }
}
