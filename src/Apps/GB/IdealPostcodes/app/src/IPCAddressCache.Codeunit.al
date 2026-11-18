// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address.IdealPostcodes;

/// <summary>
/// Holds the addresses returned by the last postcode search made through the Postcode Service Manager
/// in this session. The search already returns full addresses and is billed as one lookup, so the
/// address the user then selects is served from here instead of a second, billed API request.
/// </summary>
codeunit 9405 "IPC Address Cache"
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempCachedIPCAddressLookup: Record "IPC Address Lookup" temporary;

    procedure Store(var TempIPCAddressLookup: Record "IPC Address Lookup" temporary)
    begin
        ClearCache();
        TempIPCAddressLookup.Reset();
        if TempIPCAddressLookup.FindSet() then
            repeat
                TempCachedIPCAddressLookup := TempIPCAddressLookup;
                TempCachedIPCAddressLookup.Insert();
            until TempIPCAddressLookup.Next() = 0;
    end;

    procedure TryGet(AddressId: Text; DisplayText: Text; var TempIPCAddressLookup: Record "IPC Address Lookup" temporary): Boolean
    begin
        TempCachedIPCAddressLookup.Reset();
        if AddressId <> '' then
            TempCachedIPCAddressLookup.SetRange("Address ID", CopyStr(AddressId, 1, MaxStrLen(TempCachedIPCAddressLookup."Address ID")))
        else
            TempCachedIPCAddressLookup.SetRange("Display Text", CopyStr(DisplayText, 1, MaxStrLen(TempCachedIPCAddressLookup."Display Text")));
        if not TempCachedIPCAddressLookup.FindFirst() then
            exit(false);

        TempIPCAddressLookup := TempCachedIPCAddressLookup;
        exit(true);
    end;

    procedure ClearCache()
    begin
        TempCachedIPCAddressLookup.Reset();
        TempCachedIPCAddressLookup.DeleteAll();
    end;
}
