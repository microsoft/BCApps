// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

tableextension 13381 "VAT Reg. No. Format NL" extends "VAT Registration No. Format"
{
#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use codeunit "VAT Reg. No. Format NL" instead.', '30.0')]
    procedure CheckCompanyInfo(VATRegNo: Text[20])
    var
        VATRegNoFormatNL: Codeunit "VAT Reg. No. Format NL";
    begin
        VATRegNoFormatNL.CheckCompanyInfo(VATRegNo);
    end;
#endif
}
