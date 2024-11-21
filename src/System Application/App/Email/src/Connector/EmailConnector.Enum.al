// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>
/// Enum that holds all of the available email connectors.
/// </summary>
#if not CLEAN26
#pragma warning disable AL0432
enum 8889 "Email Connector" implements "Email Connector", "Email Connector v2", "Email Connector v3", "Default Email Rate Limit"
#pragma warning restore AL0432
#else
enum 8889 "Email Connector" implements "Email Connector", "Email Connector v3", "Default Email Rate Limit"
#endif
{
    Extensible = true;
    DefaultImplementation = "Default Email Rate Limit" = "Default Email Rate Limit",
#if not CLEAN26
                            "Email Connector v2" = "Default Email Connector v2",
#endif
                            "Email Connector v3" = "Default Email Connector v2";
}