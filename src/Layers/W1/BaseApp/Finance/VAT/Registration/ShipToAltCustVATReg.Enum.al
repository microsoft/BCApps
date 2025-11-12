// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

enum 206 "Ship-To Alt. Cust. VAT Reg." implements "Ship-To Alt. Cust. VAT Reg."
{
    Extensible = true;
    DefaultImplementation = "Ship-To Alt. Cust. VAT Reg." = "Ship Alt. Cust. VAT Reg. Impl.";

    value(0; Default)
    {
    }
}