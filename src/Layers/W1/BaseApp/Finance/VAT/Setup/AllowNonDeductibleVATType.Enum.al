// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

enum 6200 "Allow Non-Deductible VAT Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Do Not Allow") { Caption = 'Do Not Allow'; }
    value(1; "Allow") { Caption = 'Allow'; }
}