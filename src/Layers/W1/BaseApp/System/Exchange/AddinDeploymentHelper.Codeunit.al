namespace System.Integration;

using Microsoft.CRM.Outlook;
using Microsoft.Utilities;

codeunit 1640 "Add-in Deployment Helper"
{

    trigger OnRun()
    begin
    end;

    var
        AddinManifestMgt: Codeunit "Add-in Manifest Management";

    procedure CheckVersion(HostType: Text; UserVersion: Text) CanContinue: Boolean
    var
        OfficeAddin: Record "Office Add-in";
        InstructionMgt: Codeunit "Instruction Mgt.";
        LatestAddinVersion: Text;
    begin
        AddinManifestMgt.GetAddinByHostType(OfficeAddin, HostType);
        AddinManifestMgt.GetAddinVersion(LatestAddinVersion, OfficeAddin."Manifest Codeunit");

        // Make sure that the version of the add-in in the table is up to date
        if OfficeAddin.Version <> LatestAddinVersion then begin
            AddinManifestMgt.CreateDefaultAddins(OfficeAddin);
            Commit();
            AddinManifestMgt.GetAddinByHostType(OfficeAddin, HostType);
        end;

        CanContinue := true;
        if UserVersion <> OfficeAddin.Version then begin
            OfficeAddin.Breaking := OfficeAddin.IsBreakingChange(UserVersion);
            if OfficeAddin.Breaking then
                PAGE.RunModal(PAGE::"Office Update Available Dlg", OfficeAddin)
            else
                if InstructionMgt.IsEnabled(InstructionMgt.OfficeUpdateNotificationCode()) then
                    PAGE.RunModal(PAGE::"Office Update Available Dlg", OfficeAddin);

            CanContinue := not OfficeAddin.Breaking;
        end;
    end;
}

