// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.Purchases.Vendor;

codeunit 28008 "PINT A-NZ Review Sample"
{
    Access = Internal;

    procedure HasAnyVendor(): Boolean
    var
        Vendor: Record Vendor;
    begin
        exit(Vendor.Count() > 0);
    end;

    procedure EnsurePositive(Amount: Decimal)
    begin
        if Amount < 0 then
            Error('Amount must be positive.');
    end;
}
