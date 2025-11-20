namespace Microsoft.API.Upgrade;

table 9994 "API Data Upgrade"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Upgrade Tag"; Text[250])
        {
            DataClassification = SystemMetadata;
            // This will be used for entity name
        }
        field(2; Description; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(3; Status; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = " ",Scheduled,"In Progress",Completed;
            OptionCaption = ' ,Scheduled,In Progress,Completed';
        }
    }

    keys
    {
        key(Key1; "Upgrade Tag")
        {
            Clustered = true;
        }
    }

    procedure Load(): Boolean
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
        APIUpgradeTags: Dictionary of [Code[250], Text[250]];
        APIDataUpgradeEntities: Dictionary of [Code[250], Text[250]];
        APIUpgradeTag: Code[250];
        APIUpgradeDescription: Text[250];
        APIDataUpgradeEntity: Code[250];
    begin
        APIDataUpgrade.GetAPIUpgradeTags(APIUpgradeTags);
        foreach APIUpgradeTag in APIUpgradeTags.Keys() do
            if Rec.Get(APIUpgradeTag) then
                Rec.Delete();

        APIDataUpgrade.GetAPIDataUpgradeEntities(APIDataUpgradeEntities);
        foreach APIDataUpgradeEntity in APIDataUpgradeEntities.Keys() do begin
            APIUpgradeDescription := APIDataUpgradeEntities.Get(APIDataUpgradeEntity);
            if Rec.Get(APIDataUpgradeEntity) then begin
                if Rec.Description <> APIUpgradeDescription then begin
                    Rec.Description := APIUpgradeDescription;
                    Rec.Modify();
                end;
            end else begin
                Clear(Rec);
                Rec."Upgrade Tag" := APIDataUpgradeEntity;
                Rec.Status := Rec.Status::" ";
                Rec.Description := APIUpgradeDescription;
                Rec.Insert();
            end;
        end;
    end;
}