codeunit 101318 "Create Tax Areas"
{

    trigger OnRun()
    var
        TaxArea: Record "Tax Area";
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax"
        then begin
            InsertData('AB', xAlberta, TaxArea."Country/Region"::CA);
            InsertData('BC', xBritishColumbia, TaxArea."Country/Region"::CA);
            InsertData('MB', xManitoba, TaxArea."Country/Region"::CA);
            InsertData('NB', xNewBrunswick, TaxArea."Country/Region"::CA);
            InsertData('NL', xNewfoundlandAndLabrador, TaxArea."Country/Region"::CA);
            InsertData('NU', xNunavut, TaxArea."Country/Region"::CA);
            InsertData('NS', xNovaScotia, TaxArea."Country/Region"::CA);
            InsertData('NT', xNorthWestTerritories, TaxArea."Country/Region"::CA);
            InsertData('ON', xOntario, TaxArea."Country/Region"::CA);
            InsertData('PE', xPrinceEdwardIsland, TaxArea."Country/Region"::CA);
            InsertData('QC', xQuebec, TaxArea."Country/Region"::CA);
            InsertData('SK', xSaskatchewan, TaxArea."Country/Region"::CA);
            InsertData('YK', xYukon, TaxArea."Country/Region"::CA);
            InsertTranslations();
        end;
    end;

    var
        xAlberta: Label 'Alberta';
        xBritishColumbia: Label 'British Columbia';
        xManitoba: Label 'Manitoba';
        xNewBrunswick: Label 'New Brunswick';
        xNewfoundlandAndLabrador: Label 'Newfoundland and Labrador';
        xNovaScotia: Label 'Nova Scotia';
        xNorthWestTerritories: Label 'North West Territories';
        xOntario: Label 'Ontario';
        xPrinceEdwardIsland: Label 'Prince Edward Island';
        xQuebec: Label 'Quebec';
        xSaskatchewan: Label 'Saskatchewan';
        xYukon: Label 'Yukon';
        xNunavut: Label 'Nunavut';
        FRCTxt: Label 'FRC', Locked = true;

    local procedure InsertData("Code": Code[20]; Description: Text[30]; CountryRegion: Option)
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Init();
        TaxArea.Validate(Code, Code);
        TaxArea.Validate(Description, Description);
        TaxArea.Validate("Country/Region", CountryRegion);
        TaxArea.Insert();
    end;

    local procedure InsertTranslations()
    begin
        InsertTranslation('BC', FRCTxt, 'Colombie-Britannique');
        InsertTranslation('NB', FRCTxt, 'Nouveau-Brunswick');
        InsertTranslation('NL', FRCTxt, 'Terre-Neuve-et-Labrador');
        InsertTranslation('NS', FRCTxt, 'Nouvelle-Écosse');
        InsertTranslation('NT', FRCTxt, 'Territoires du Nord-Ouest');
        InsertTranslation('PE', FRCTxt, 'Île-du-Prince-Édouard');
        InsertTranslation('QC', FRCTxt, 'Québec');
    end;

    local procedure InsertTranslation(TaxAreaCode: Code[10]; LanguageCode: Code[10]; Description: Text[50])
    var
        TaxAreaTranslation: Record "Tax Area Translation";
    begin
        TaxAreaTranslation.Validate("Tax Area Code", TaxAreaCode);
        TaxAreaTranslation."Language Code" := LanguageCode;
        TaxAreaTranslation.Description := Description;
        if TaxAreaTranslation.Insert() then;
    end;

    procedure GetOntarioTaxAreaCode(): Code[20]
    begin
        exit('ON');
    end;
}

