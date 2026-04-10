namespace System.Environment.Configuration;

using System.Reflection;

codeunit 9177 "Application Area Cache"
{
    SingleInstance = true;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = tabledata "Application Area Setup" = r;

    var
        ApplicationAreaCache: Dictionary of [Text, Text];

    procedure GetApplicationAreasForUser(var ApplicationAreas: Text): Boolean
    begin
        if not ApplicationAreaCache.ContainsKey('User:' + UserId()) then
            PopulateCacheForUser();

        ApplicationAreas := ApplicationAreaCache.Get('User:' + UserId());
        exit(ApplicationAreas <> '-')
    end;

    local procedure PopulateCacheForUser()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreas: Text;
    begin
        if ApplicationAreaSetup.Get('', '', UserId()) then begin
            ApplicationAreas := GetApplicationAreas(ApplicationAreaSetup);
            ApplicationAreaCache.Set('User:' + UserId(), ApplicationAreas);
        end else
            ApplicationAreaCache.Set('User:' + UserId(), '-');
    end;

    procedure GetApplicationAreasForProfile(var ApplicationAreas: Text): Boolean
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        if not ApplicationAreaCache.ContainsKey('Profile:' + AllProfile."Profile ID") then
            PopulateCacheForProfile(AllProfile."Profile ID");

        ApplicationAreas := ApplicationAreaCache.Get('Profile:' + AllProfile."Profile ID");
        exit(ApplicationAreas <> '-')
    end;

    local procedure PopulateCacheForProfile(ProfileCode: Code[30])
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreas: Text;
    begin
        if ApplicationAreaSetup.Get('', ProfileCode) then begin
            ApplicationAreas := GetApplicationAreas(ApplicationAreaSetup);
            ApplicationAreaCache.Set('Profile:' + ProfileCode, ApplicationAreas);
        end else
            ApplicationAreaCache.Set('Profile:' + ProfileCode, '-');
    end;

    procedure GetApplicationAreasForCompany(var ApplicationAreas: Text): Boolean
    begin
        if not ApplicationAreaCache.ContainsKey('Company:' + CompanyName()) then
            PopulateCacheForCompany();

        ApplicationAreas := ApplicationAreaCache.Get('Company:' + CompanyName());
        exit(ApplicationAreas <> '-')
    end;

    local procedure PopulateCacheForCompany()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreas: Text;
    begin
        if ApplicationAreaSetup.Get(CompanyName()) then begin
            ApplicationAreas := GetApplicationAreas(ApplicationAreaSetup);
            ApplicationAreaCache.Set('Company:' + CompanyName(), ApplicationAreas);
        end else
            ApplicationAreaCache.Set('Company:' + CompanyName(), '-');
    end;

    procedure GetApplicationAreasCrossCompany(var ApplicationAreas: Text): Boolean
    begin
        if not ApplicationAreaCache.ContainsKey('') then
            PopulateCacheCrossCompany();

        ApplicationAreas := ApplicationAreaCache.Get('');
        exit(ApplicationAreas <> '-')
    end;

    local procedure PopulateCacheCrossCompany()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreas: Text;
    begin
        if ApplicationAreaSetup.Get() then begin
            ApplicationAreas := GetApplicationAreas(ApplicationAreaSetup);
            ApplicationAreaCache.Set('', ApplicationAreas);
        end else
            ApplicationAreaCache.Set('', '-');
    end;

    local procedure GetApplicationAreas(ApplicationAreaSetup: Record "Application Area Setup") ApplicationAreas: Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldIndex: Integer;
    begin
        RecRef.GetTable(ApplicationAreaSetup);

        // Index 1 to 3 are used for the Primary Key fields, we need to skip these fields
        for FieldIndex := 4 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);
            if FieldRef.Value() then
                if ApplicationAreas = '' then
                    ApplicationAreas := '#' + DelChr(FieldRef.Name)
                else
                    ApplicationAreas := ApplicationAreas + ',#' + DelChr(FieldRef.Name);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Application Area Setup", 'OnAfterInsertEvent', '', true, true)]
    local procedure ClearCacheAfterApplicationAreaSetupInsert()
    begin
        ClearCache();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Application Area Setup", 'OnAfterDeleteEvent', '', true, true)]
    local procedure ClearCacheAfterApplicationAreaSetupDelete()
    begin
        ClearCache();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Application Area Setup", 'OnAfterModifyEvent', '', true, true)]
    local procedure ClearCacheAfterApplicationAreaSetupModify()
    begin
        ClearCache();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Application Area Setup", 'OnAfterRenameEvent', '', true, true)]
    local procedure ClearCacheAfterApplicationAreaSetupRename()
    begin
        ClearCache();
    end;

    internal procedure ClearCache()
    begin
        Clear(ApplicationAreaCache);
    end;

    internal procedure GetCache(var Cache: Dictionary of [Text, Text])
    begin
        Cache := ApplicationAreaCache;
    end;
}