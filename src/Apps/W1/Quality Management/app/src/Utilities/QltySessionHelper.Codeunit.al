// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

/// <summary>
/// Keep track of global session values related to quality management, for example for item tracking.
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
        ItemTrackingIsFromQltyInspectionModeTok: Label 'Qlty::ItemTracking::StartingFromQltyInspection', Locked = true;

    /// <summary>
    /// Stores a text value for a session key.
    /// </summary>
    /// <param name="CurrentKey">The session key to set.</param>
    /// <param name="Value">The value to store.</param>
    internal procedure SetSessionValue(CurrentKey: Text; Value: Text)
    begin
        MiscKeyValuePairs.Set(CurrentKey, Value);
    end;

    /// <summary>
    /// Gets the text value stored for a session key.
    /// </summary>
    /// <param name="CurrentKey">The session key to read.</param>
    /// <returns>The stored value, or an empty value when the key is not present.</returns>
    internal procedure GetSessionValue(CurrentKey: Text) Value: Text
    begin
        if MiscKeyValuePairs.ContainsKey(CurrentKey) then
            MiscKeyValuePairs.Get(CurrentKey, Value);
    end;

    /// <summary>
    /// Marks the session as having started item tracking from Quality Management.
    /// </summary>
    internal procedure SetStartingFromQualityManagementFlag()
    begin
        SetSessionValue(ItemTrackingIsFromQltyInspectionModeTok, ItemTrackingIsFromQltyInspectionModeTok);
    end;

    /// <summary>
    /// Reads and clears the flag indicating that item tracking started from Quality Management.
    /// </summary>
    /// <returns>True if the flag was set; otherwise, false.</returns>
    internal procedure GetStartingFromQualityManagementFlagAndResetFlag() Result: Boolean
    begin
        Result := (GetSessionValue(ItemTrackingIsFromQltyInspectionModeTok) <> '');
        SetSessionValue(ItemTrackingIsFromQltyInspectionModeTok, '');
        exit(Result);
    end;

    /// <summary>
    /// Sets the item tracking form mode for the session.
    /// </summary>
    /// <param name="Value">The item tracking form mode value.</param>
    internal procedure SetTrackingFormModeFlag(Value: Text)
    begin
        SetSessionValue(ItemTrackingFlagAllOrSingleTok, Value);
    end;

    /// <summary>
    /// Gets the item tracking form mode for the session.
    /// </summary>
    /// <returns>The stored item tracking form mode.</returns>
    internal procedure GetTrackingFormModeFlag() Value: Text
    begin
        Value := GetSessionValue(ItemTrackingFlagAllOrSingleTok);
    end;

    /// <summary>
    /// Gets the item tracking mode token for all documents.
    /// </summary>
    /// <returns>The all-documents mode token.</returns>
    internal procedure GetTrackingFormFlagValueAllDocs(): Text
    begin
        exit(ItemTrackingFlagAllDocsTok);
    end;

    /// <summary>
    /// Gets the item tracking mode token for the source document only.
    /// </summary>
    /// <returns>The source-document-only mode token.</returns>
    internal procedure GetTrackingFormFlagValueSourceDoc(): Text
    begin
        exit(ItemTrackingFlagSourceDocOnlyTok);
    end;
}
