// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

enum 8351 "MCP Server Feature"
{
    Access = Internal;
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "AL Query Server")
    {
        Caption = 'AL Query Server (Preview)';
    }
}
