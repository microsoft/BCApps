// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location.AddressPrototype;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Location;

codeunit 17700 "Location Address Mgt."
{
    procedure FormatAddress(Location: Record Location): Text
    var
        AddressFormatter: Codeunit "Format Address";
        AddressLines: array[8] of Text[100];
        AddressBuilder: TextBuilder;
        LineNo: Integer;
    begin
        AddressFormatter.FormatAddr(
            AddressLines, '', '', '', Location.Address, Location."Address 2",
            Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
        for LineNo := 1 to ArrayLen(AddressLines) do
            if AddressLines[LineNo] <> '' then
                AddressBuilder.AppendLine(AddressLines[LineNo]);

        exit(AddressBuilder.ToText().TrimEnd());
    end;

    procedure EditAddress(var Location: Record Location): Boolean
    var
        TempEditedLocation: Record Location temporary;
        UpdatedLocation: Record Location;
        LocationAddressEditor: Page "Location Address Editor";
    begin
        LocationAddressEditor.SetLocation(Location);
        if LocationAddressEditor.RunModal() <> Action::OK then
            exit(false);

        LocationAddressEditor.GetLocation(TempEditedLocation);
        UpdatedLocation := Location;
        if UpdatedLocation."Country/Region Code" <> TempEditedLocation."Country/Region Code" then
            UpdatedLocation.Validate("Country/Region Code", TempEditedLocation."Country/Region Code");
        if UpdatedLocation.Address <> TempEditedLocation.Address then
            UpdatedLocation.Validate(Address, TempEditedLocation.Address);
        if UpdatedLocation."Address 2" <> TempEditedLocation."Address 2" then
            UpdatedLocation.Validate("Address 2", TempEditedLocation."Address 2");
        if UpdatedLocation."Post Code" <> TempEditedLocation."Post Code" then
            UpdatedLocation.Validate("Post Code", TempEditedLocation."Post Code");
        if UpdatedLocation.City <> TempEditedLocation.City then
            UpdatedLocation.Validate(City, TempEditedLocation.City);
        if UpdatedLocation.County <> TempEditedLocation.County then
            UpdatedLocation.Validate(County, TempEditedLocation.County);

        Location := UpdatedLocation;
        exit(true);
    end;
}
