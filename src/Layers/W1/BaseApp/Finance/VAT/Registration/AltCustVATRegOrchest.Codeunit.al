// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Finance.VAT.Setup;

codeunit 207 "Alt. Cust. VAT Reg. Orchest."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetAltCustVATRegConsistencyImpl(): Interface "Alt. Cust. VAT Reg. Consist."
    var
        VATSetup: Record "VAT Setup";
    begin
        exit(VATSetup.Get() ? VATSetup."Alt. Cust. VAT Reg. Consistent" : "Alt. Cust. VAT Reg. Consist."::Default);
    end;

    procedure GetShipToAlCustVATRegImpl(): Interface "Ship-To Alt. Cust. VAT Reg."
    var
        VATSetup: Record "VAT Setup";
    begin
        exit(VATSetup.Get() ? VATSetup."Ship-To Alt. Cust. VAT Reg." : "Ship-To Alt. Cust. VAT Reg."::Default);
    end;

    procedure GetAltCustVATRegDocImpl(): Interface "Alt. Cust. VAT Reg. Doc."
    var
        VATSetup: Record "VAT Setup";
    begin
        exit(VATSetup.Get() ? VATSetup."Alt. Cust. VAT Reg. Doc." : "Alt. Cust VAT Reg. Doc."::Default);
    end;

}