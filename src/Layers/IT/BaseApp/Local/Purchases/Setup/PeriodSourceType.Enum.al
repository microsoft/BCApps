// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

enum 12192 "Period Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Calendar Year") { Caption = 'Calendar Year'; }
    value(1; "Fiscal Year") { Caption = 'Fiscal Year'; }
}
