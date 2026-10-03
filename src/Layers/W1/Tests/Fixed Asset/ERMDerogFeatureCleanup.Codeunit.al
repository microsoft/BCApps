// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 144151 "ERM Derog. Feature Cleanup"
{
    SingleInstance = true;

    var
        PreviousFeatureStatus: Enum "Feature Status";
        CapturedFeatureKey: Text[50];
        CapturedCompanyName: Text[30];
        FeatureStateCaptured: Boolean;
        FeatureStatusRecordExisted: Boolean;

    procedure CaptureFeatureState(FeatureKey: Text[50]; CompanyNameToCapture: Text[30])
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        if FeatureStateCaptured then
            exit;

        FeatureStateCaptured := true;
        CapturedFeatureKey := FeatureKey;
        CapturedCompanyName := CompanyNameToCapture;
        FeatureStatusRecordExisted :=
            FeatureDataUpdateStatus.Get(CapturedFeatureKey, CapturedCompanyName);
        if FeatureStatusRecordExisted then
            PreviousFeatureStatus := FeatureDataUpdateStatus."Feature Status";
    end;

    procedure RestoreFeatureState()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        if not FeatureStateCaptured then
            exit;

        if FeatureStatusRecordExisted then begin
            FeatureDataUpdateStatus.Get(CapturedFeatureKey, CapturedCompanyName);
            FeatureDataUpdateStatus."Feature Status" := PreviousFeatureStatus;
            FeatureDataUpdateStatus.Modify();
        end else
            if FeatureDataUpdateStatus.Get(CapturedFeatureKey, CapturedCompanyName) then
                FeatureDataUpdateStatus.Delete();

        // Posting can commit the enabled state. Persist cleanup before a failed test body is reported.
        Commit();
        Clear(PreviousFeatureStatus);
        Clear(CapturedFeatureKey);
        Clear(CapturedCompanyName);
        Clear(FeatureStateCaptured);
        Clear(FeatureStatusRecordExisted);
    end;

}
