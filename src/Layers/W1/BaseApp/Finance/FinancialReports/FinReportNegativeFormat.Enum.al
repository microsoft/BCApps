// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 1083 "Fin. Report Negative Format"
{
    Extensible = true;

    value(0; "Minus Sign") { Caption = 'Minus Sign'; }
    value(1; "Parentheses") { Caption = 'Parentheses'; }
    value(100; Default) { Caption = 'Default'; }
}
