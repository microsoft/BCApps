// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

using System.Email;

enumextension 134684 "Test Email Connector" extends "Email Connector"
{
    value(134684; "Test Email Connector")
    {
        Implementation = "Email Connector" = "Test Email Connector";
    }
#if not CLEAN26
    value(134685; "Test Email Connector v2")
    {
        Implementation = "Email Connector" = "Test Email Connector v2";
    }
#endif
#if not CLEAN28
    value(134686; "Test Email Connector v3")
    {
        Implementation = "Email Connector" = "Test Email Connector v3";
    }
#endif
    value(134687; "Test Email Connector v4")
    {
        Implementation = "Email Connector" = "Test Email Connector v4";
    }

}