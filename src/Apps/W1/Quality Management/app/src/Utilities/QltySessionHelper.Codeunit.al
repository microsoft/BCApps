// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

/// <summary>
/// This exists to help keep track of variables to work around a variety of BC issues.
/// </summary>
codeunit 20430 "Qlty. Session Helper"
{
    SingleInstance = true;
    InherentPermissions = X;

    var
        MiscKeyValuePairs: Dictionary of [Text, Text];
        ItemTrackingFlagAllOrSingleTok: Label 'Qlty::ItemTracking::AllOrSingle', Locked = true;
        ItemTrackingFlagAllDocsTok: Label 'Qlty::ItemTracking::AllOrSingle::ALLDOCS', Locked = true;
        ItemTrackingFlagSourceDocOnlyTok: Label 'Qlty::ItemTracking::AllOrSingle::SOURCEDOCONLY', Locked = true;
        ItemTrackingIsFromQITestModeTok: Label 'Qlty::ItemTracking::StartingFromQITest', Locked = true;

    internal procedure SetSessionValue(CurrentKey: Text; Value: Text)
    begin
        MiscKeyValuePairs.Set(CurrentKey, Value);
    end;

    internal procedure GetSessionValue(CurrentKey: Text) Value: Text
    begin
        if MiscKeyValuePairs.ContainsKey(CurrentKey) then
            MiscKeyValuePairs.Get(CurrentKey, Value);
    end;

    internal procedure SetStartingFromQualityManagementFlag()
    begin
        SetSessionValue(ItemTrackingIsFromQITestModeTok, ItemTrackingIsFromQITestModeTok);
    end;

    internal procedure GetStartingFromQualityManagementFlagAndResetFlag() Result: Boolean
    begin
        Result := (GetSessionValue(ItemTrackingIsFromQITestModeTok) <> '');
        SetSessionValue(ItemTrackingIsFromQITestModeTok, '');
        exit(Result);
    end;

    internal procedure SetTrackingFormModeFlag(Value: Text)
    begin
        SetSessionValue(ItemTrackingFlagAllOrSingleTok, Value);
    end;

    internal procedure GetTrackingFormModeFlag() Value: Text
    begin
        Value := GetSessionValue(ItemTrackingFlagAllOrSingleTok);
    end;

    internal procedure GetTrackingFormFlagValueAllDocs(): Text
    begin
        exit(ItemTrackingFlagAllDocsTok);
    end;

    internal procedure GetTrackingFormFlagValueSourceDoc(): Text
    begin
        exit(ItemTrackingFlagSourceDocOnlyTok);
    end;
}
