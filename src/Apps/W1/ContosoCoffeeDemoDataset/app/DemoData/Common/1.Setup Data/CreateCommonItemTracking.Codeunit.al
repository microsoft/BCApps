// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Common;

using Microsoft.DemoTool.Helpers;

codeunit 5144 "Create Common Item Tracking"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoItem: Codeunit "Contoso Item";
    begin
        ContosoItem.InsertItemTrackingCode(LotSpecificTrackingCode(), LOTWMSpecifictrackingLbl, false, true, false, false, false, false);
        ContosoItem.InsertItemTrackingCode(SNSpecificTrackingCode(), SNSpecificTrackingLbl, true, false, false, false, false, false);
    end;

    var
        SNAllTok: Label 'SNALL', MaxLength = 10;
        SNSpecificTrackingLbl: Label 'SN specific tracking', MaxLength = 50;
        LOTWMSTok: Label 'LOTALLEXP', MaxLength = 10;
        LOTWMSpecifictrackingLbl: Label 'Lot specific tracking for warehouse', MaxLength = 50;

    procedure LotSpecificTrackingCode(): Code[10]
    begin
        exit(LOTWMSTok);
    end;

    procedure SNSpecificTrackingCode(): Code[10]
    begin
        exit(SNAllTok);
    end;
}
