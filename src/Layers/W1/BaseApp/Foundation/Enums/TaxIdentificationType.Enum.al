// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 253 "Tax Identification Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Legal Entity")
    {
        Caption = 'Legal Entity';
    }
    value(1; "Natural Person")
    {
        Caption = 'Natural Person';
    }
}
