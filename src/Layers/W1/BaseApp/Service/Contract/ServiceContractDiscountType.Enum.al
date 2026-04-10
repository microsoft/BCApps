// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

enum 5973 "Service Contract Discount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Service Item Group") { Caption = 'Service Item Group'; }
    value(1; "Resource Group") { Caption = 'Resource Group'; }
    value(2; "Cost") { Caption = 'Cost'; }
}
