// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

enum 398 "Sales Tax Country"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "US") { Caption = 'US'; }
    value(1; "CA") { Caption = 'CA'; }
}