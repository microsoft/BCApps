// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

codeunit 8705 "Feature Uptake Status Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Feature Uptake";
    Permissions = tabledata "Feature Uptake" = rimd;

    var
        StartedSessionId: Integer;
        TelemetryLibraryCategoryTxt: Label 'TelemetryLibrary', Locked = true;
        StartedSessionHasNotEndedErr: Label 'A session updating the feature uptake status is taking longer than expected. The feature uptake status might not be updated correctly.', Locked = true;

    trigger OnRun()
    begin
        if not Rec.IsTemporary() then
            exit;

        UpdateFeatureUptakeStatus(Rec);
    end;

    procedure UpdateFeatureUptakeStatus(FeatureName: Text; FeatureUptakeStatus: Enum "Feature Uptake Status"; IsPerUser: Boolean; PerformWriteTransactionsInASeparateSession: Boolean; Publisher: Text) IsExpectedUpdate: Boolean
    var
        TempFeatureUptake: Record "Feature Uptake" temporary;
        UserSecurityIDForTheFeature: Guid;
        IsExpectedTransition: Boolean;
    begin
        if IsPerUser then
            UserSecurityIDForTheFeature := UserSecurityId();

        TempFeatureUptake."Feature Name" := CopyStr(FeatureName, 1, MaxStrLen(TempFeatureUptake."Feature Name"));
        TempFeatureUptake."User Security ID" := UserSecurityIDForTheFeature;
        TempFeatureUptake."Feature Uptake Status" := FeatureUptakeStatus;
        TempFeatureUptake.Publisher := CopyStr(Publisher, 1, MaxStrLen(TempFeatureUptake.Publisher));

        WaitForStartedUpdateFeatureUptakeSession();
        if NeedToUpdateFeatureUptakeStatus(TempFeatureUptake, IsExpectedTransition) then
            if PerformWriteTransactionsInASeparateSession then
                StartSession(StartedSessionId, Codeunit::"Feature Uptake Status Impl.", CompanyName(), TempFeatureUptake)
            else
                UpdateFeatureUptakeStatus(TempFeatureUptake);

        exit(IsExpectedTransition);
    end;

    local procedure NeedToUpdateFeatureUptakeStatus(TempFeatureUptake: Record "Feature Uptake" temporary; var IsExpectedTransition: Boolean): Boolean
    begin
        case TempFeatureUptake."Feature Uptake Status" of
            Enum::"Feature Uptake Status"::Discovered:
                exit(NeedToUpdateToFirstState(TempFeatureUptake, IsExpectedTransition));
            Enum::"Feature Uptake Status"::"Set up":
                exit(NeedToUpdateToIntermediateState(TempFeatureUptake, IsExpectedTransition));
            Enum::"Feature Uptake Status"::Used:
                exit(NeedToUpdateToIntermediateState(TempFeatureUptake, IsExpectedTransition));
            Enum::"Feature Uptake Status"::Undiscovered:
                begin
                    IsExpectedTransition := false; // the feature is now undiscovered
                    exit(NeedToResetState(TempFeatureUptake));
                end;
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Feature Uptake", 'rimd')]
    local procedure UpdateFeatureUptakeStatus(TempFeatureUptake: Record "Feature Uptake" temporary)
    var
        FeatureUptake: Record "Feature Uptake";
    begin
        FeatureUptake.LockTable();

        if FeatureUptake.Get(TempFeatureUptake."Feature Name", TempFeatureUptake."User Security ID", TempFeatureUptake.Publisher) then begin
            if TempFeatureUptake."Feature Uptake Status" = Enum::"Feature Uptake Status"::Undiscovered then
                FeatureUptake.Delete()
            else begin
                FeatureUptake."Feature Uptake Status" := TempFeatureUptake."Feature Uptake Status";
                FeatureUptake.Modify();
            end;
        end else begin
            FeatureUptake := TempFeatureUptake;
            FeatureUptake.Insert();
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Feature Uptake", 'r')]
    local procedure NeedToUpdateToFirstState(TempFeatureUptake: Record "Feature Uptake" temporary; var IsExpectedTransition: Boolean): Boolean
    var
        FeatureUptake: Record "Feature Uptake";
    begin
        if FeatureUptake.Get(TempFeatureUptake."Feature Name", TempFeatureUptake."User Security ID", TempFeatureUptake.Publisher) then begin
            IsExpectedTransition := false; // the feature has already been discovered
            exit(false);
        end;

        IsExpectedTransition := true; // the status has changed to "Discovered"
        exit(true);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Feature Uptake", 'r')]
    local procedure NeedToUpdateToIntermediateState(TempFeatureUptake: Record "Feature Uptake" temporary; var IsExpectedTransition: Boolean): Boolean
    var
        FeatureUptake: Record "Feature Uptake";
        PreviousFeatureUptakeStatus: Enum "Feature Uptake Status";
    begin
        PreviousFeatureUptakeStatus := Enum::"Feature Uptake Status".FromInteger(TempFeatureUptake."Feature Uptake Status".AsInteger() - 1);

        if FeatureUptake.Get(TempFeatureUptake."Feature Name", TempFeatureUptake."User Security ID", TempFeatureUptake.Publisher) then begin
            if FeatureUptake."Feature Uptake Status" = PreviousFeatureUptakeStatus then begin
                // expected transition
                IsExpectedTransition := true;
                exit(true);
            end else begin
                // the user went back to the FeatureUptakeStatus step
                IsExpectedTransition := false;
                exit(false);
            end;
        end else begin
            FeatureUptake.SetRange("Feature Name", TempFeatureUptake."Feature Name");
            FeatureUptake.SetRange(Publisher, TempFeatureUptake.Publisher);
            if FeatureUptake.IsEmpty() then begin
                // there was no record with the previous feature uptake status
                IsExpectedTransition := false;
                exit(true);
            end else begin
                // per-tenant feature switches to being per-user or vice versa
                IsExpectedTransition := false;
                exit(false);
            end;
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Feature Uptake", 'r')]
    local procedure NeedToResetState(TempFeatureUptake: Record "Feature Uptake" temporary): Boolean
    var
        FeatureUptake: Record "Feature Uptake";
    begin
        if FeatureUptake.Get(TempFeatureUptake."Feature Name", TempFeatureUptake."User Security ID", TempFeatureUptake.Publisher) then
            exit(true);

        exit(false);
    end;

    /// <summary>
    /// The updates to Feature Uptake states must be done in a separate session (e. g. to not interfere with subsequent Page.RunModal() calls).
    /// Normally we don't need to wait for this separate session to finish, as feature uptake states are expected to not change rapidly, and it only takes a few milliseconds for the session to complete.
    /// But if the feature registers uptake states one right after another, then the session may not have enough time to start and acquire a lock on the "Feature Uptake" table by the time the next uptake state is registered.
    /// For such cases, we can wait for this previous session to finish.
    /// </summary>
    /// <remarks>We will only ever wait when feature uptake states a registered for the first time, so there is no persistent performance penalty to this.</remarks>
    /// <remarks>It is not hard requirement to actually wait for the session to finish, we only need to wait long enough, so that it calls FeatureUptake.LockTable().</remarks>
    local procedure WaitForStartedUpdateFeatureUptakeSession()
    var
        StartDateTime: DateTime;
        Timeout: Duration;
    begin
        if StartedSessionId = 0 then
            exit;

        Timeout := 100; // wait for up 0.1 seconds
        StartDateTime := CurrentDateTime();
        while IsSessionActive(StartedSessionId) do begin
            if CurrentDateTime() - StartDateTime > Timeout then begin
                StartedSessionId := 0;
                Session.LogMessage('0000LKY', StartedSessionHasNotEndedErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryLibraryCategoryTxt);
                exit;
            end;

            Sleep(10);
        end;
        StartedSessionId := 0;
    end;
}
