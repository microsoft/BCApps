// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

enum 205 "Alt. Cust VAT Reg. Doc." implements "Alt. Cust. VAT Reg. Doc."
{
    Extensible = true;
    DefaultImplementation = "Alt. Cust. VAT Reg. Doc." = "Alt. Cust. VAT Reg. Doc. Impl.";

    value(0; Default)
    {
    }
}