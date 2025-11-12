// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

#pragma warning disable AL0659
enum 13 "VAT Statement Report Period Selection"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Before and Within Period") { Caption = 'Before and Within Period'; }
    value(1; "Within Period") { Caption = 'Within Period'; }
}
