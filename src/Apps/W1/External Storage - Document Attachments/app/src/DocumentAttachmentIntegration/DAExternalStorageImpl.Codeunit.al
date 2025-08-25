// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 8751 "DA External Storage Impl." implements "File Scenario"
{
    Permissions = tabledata "DA External Storage Setup" = r;

    /// <summary>
    /// Called before adding or modifying a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if the operation is allowed, otherwise false.</returns>
    procedure BeforeAddOrModifyFileScenarioCheck(Scenario: Integer; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SkipInsertOrModify: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        DisclaimerPart1Lbl: Label 'You are about to enable External Storage!!!';
        DisclaimerPart2Lbl: Label '\\This feature is provided as-is, and you use it at your own risk.';
        DisclaimerPart3Lbl: Label '\Microsoft is not responsible for any issues or data loss that may occur.';
        DisclaimerPart4Lbl: Label '\\Do you wish to continue?';
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage".AsInteger()) then
            exit;

        SkipInsertOrModify := not ConfirmManagement.GetResponseOrDefault(DisclaimerPart1Lbl +
                    DisclaimerPart2Lbl +
                    DisclaimerPart3Lbl +
                    DisclaimerPart4Lbl);
    end;

    /// <summary>
    /// Called to get additional setup for a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if additional setup is available, otherwise false.</returns>
    procedure GetAdditionalScenarioSetup(Scenario: Integer; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SetupExist: Boolean
    var
        ExternalStorageSetup: Page "DA External Storage Setup";
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage".AsInteger()) then
            exit;

        ExternalStorageSetup.RunModal();
        SetupExist := true;
    end;

    /// <summary>
    /// Called before deleting a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param> 
    /// <returns>True if the delete operation is handled and should not proceed, otherwise false.</returns>
    procedure BeforeDeleteFileScenarioCheck(Scenario: Integer; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SkipDelete: Boolean
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
        NotPossibleToUnassignScenarioMsg: Label 'External Storage scenario can not be unassigned when there are uploaded files.';
    begin
        if not (Scenario = Enum::"File Scenario"::"Doc. Attach. - External Storage".AsInteger()) then
            exit;

        if not ExternalStorageSetup.Get() then
            exit;

        ExternalStorageSetup.CalcFields("Has Uploaded Files");
        if not ExternalStorageSetup."Has Uploaded Files" then
            exit;

        SkipDelete := true;
        Message(NotPossibleToUnassignScenarioMsg);
    end;
}