// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

enum 5998 "Service Line Discount Type"
{
    value(0; " ") { Caption = ''; }
    value(1; "Warranty Disc.") { Caption = 'Warranty Disc.'; }
    value(2; "Contract Disc.") { Caption = 'Contract Disc.'; }
    value(3; "Line Disc.") { Caption = 'Line Disc.'; }
    value(4; "Manual") { Caption = 'Manual'; }
}