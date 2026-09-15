codeunit 101979 "Set App. Database Config"
{

    trigger OnRun()
    begin
    end;

    var
        CountryRegionCodeSetMsg: Label 'Country/Region Code has been set to %1.', Comment = '%1 = the country/region code (e.g. GB)';
        CountryRegionCodeNotExistErr: Label 'The Country/Region Code %1 does not exist.', Comment = '%1 = the country/region code (e.g. GB)';

    procedure SetCountry(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
    begin
        if CountryRegionCode <> 'W1' then
            if not CountryRegion.Get(CountryRegionCode) then begin
                Message(CountryRegionCodeNotExistErr, CountryRegionCode);
                exit;
            end;

        MediaResourcesMgt.InsertBlobFromText('ApplicationCountry', CountryRegionCode);
        Message(CountryRegionCodeSetMsg, CountryRegionCode);
    end;
}

