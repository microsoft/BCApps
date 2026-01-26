codeunit 101320 "Create Tax Jurisdictions"
{

    trigger OnRun()
    var
        GetGLAccNo: Codeunit "Get G/L Account No. and Name";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            UpdateTaxSetup();
            if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax"
            then begin
                InsertTaxJurisdiction('CA', xGovernmentofCanada, xGSTHSTAccount, 'CA', xGSTPrintDescription);

                // HST - Harmonized Sales Tax Provinces
                InsertTaxJurisdiction('CANB', xNewBrunswick, xGSTHSTAccount, 'CA', xHSTPrintDescription);
                InsertTaxJurisdiction('CANL', xNewfoundlandAndLabrador, xGSTHSTAccount, 'CA', xHSTPrintDescription);
                InsertTaxJurisdiction('CANS', xNovaScotia, xGSTHSTAccount, 'CA', xHSTPrintDescription);
                InsertTaxJurisdiction('CAON', xOntario, xGSTHSTAccount, 'CA', xHSTPrintDescription);
                InsertTaxJurisdiction('CAPE', xPrinceEdwardIsland, xGSTHSTAccount, 'CA', xHSTPrintDescription);

                // PST - Province sales tax
                InsertTaxJurisdiction('CABC', xBritishColumbia, xPSTAccount, 'CABC', xPSTPrintDescription);
                InsertTaxJurisdiction('CAMB', xManitoba, xPSTAccount, 'CAMB', xPSTPrintDescription);
                InsertTaxJurisdiction('CASK', xSaskatchewan, xPSTAccount, 'CASK', xPSTPrintDescription);

                // QST - Quebec sales tax
                InsertTaxJurisdiction('CAQC', xQuebec, xPSTAccount, 'CAQC', xQuebecPrintDescription);

                UpdatePrintOrder();
                InsertTranslations();
            end;
        end else begin
            UpdateTaxMiniSetup();
            InsertTaxJurisdiction2('CA', xGovernmentofCanada, GetGLAccNo.GSTHSTSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CA', xGSTPrintDescription);

            // HST - Harmonized Sales Tax Provinces
            InsertTaxJurisdiction2('CANB', xNewBrunswick, GetGLAccNo.GSTHSTSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CA', xHSTPrintDescription);
            InsertTaxJurisdiction2('CANL', xNewfoundlandAndLabrador, GetGLAccNo.GSTHSTSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CA', xHSTPrintDescription);
            InsertTaxJurisdiction2('CANS', xNovaScotia, GetGLAccNo.GSTHSTSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CA', xHSTPrintDescription);
            InsertTaxJurisdiction2('CAON', xOntario, GetGLAccNo.GSTHSTSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CA', xHSTPrintDescription);
            InsertTaxJurisdiction2('CAPE', xPrinceEdwardIsland, GetGLAccNo.GSTHSTSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CA', xHSTPrintDescription);

            // PST - Province sales tax
            InsertTaxJurisdiction2('CABC', xBritishColumbia, GetGLAccNo.ProvincialSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CABC', xPSTPrintDescription);
            InsertTaxJurisdiction2('CAMB', xManitoba, GetGLAccNo.ProvincialSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CAMB', xPSTPrintDescription);
            InsertTaxJurisdiction2('CASK', xSaskatchewan, GetGLAccNo.ProvincialSalesTax(), GetGLAccNo.GSTHSTInputCredits(), 'CASK', xPSTPrintDescription);

            // QST - Quebec sales tax
            InsertTaxJurisdiction2('CAQC', xQuebec, GetGLAccNo.QSTSalesTaxCollected(), GetGLAccNo.GSTHSTInputCredits(), 'CAQC', xQuebecPrintDescription);

            UpdatePrintOrder();
            InsertTranslations();
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        xGovernmentofCanada: Label 'Government of Canada GST';
        xBritishColumbia: Label 'Province of British Columbia PST';
        xQuebecPrintDescription: Label 'QST';
        xGSTPrintDescription: Label 'GST';
        xHSTPrintDescription: Label 'HST';
        xPSTPrintDescription: Label 'PST';
        xManitoba: Label 'Province of Manitoba PST';
        xNewBrunswick: Label 'Province of New Brunswick HST';
        xNewfoundlandAndLabrador: Label 'Province of Newfoundland and Labrador HST';
        xNovaScotia: Label 'Province of Nova Scotia HST';
        xOntario: Label 'Province of Ontario HST';
        xPrinceEdwardIsland: Label 'Province of Prince Edward Island HST';
        xQuebec: Label 'Province of Quebec QST';
        xSaskatchewan: Label 'Province of Saskatchewan PST';
        xGSTHSTAccount: Label '990012', Locked = true;
        xPSTAccount: Label '990011', Locked = true;
        FRCTxt: Label 'FRC', Locked = true;
        GSTInFrenchTxt: Label 'TPS', Locked = true;
        QSTInFrenchTxt: Label 'TVQ', Locked = true;
        PSTInFrenchTxt: Label 'TVP', Locked = true;
        HSTInFrenchTxt: Label 'TVH', Locked = true;

    local procedure InsertTaxJurisdiction(NewCode: Code[10]; Description: Text[50]; TaxAccount: Code[20]; ReportToJurisdiction: Code[10]; PrintDescription: Text[30])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Init();
        TaxJurisdiction.Validate(Code, NewCode);
        TaxJurisdiction.Insert();
        TaxJurisdiction.Validate(Description, Description);

        TaxJurisdiction.Validate("Tax Account (Sales)", CA.Convert(TaxAccount));
        TaxJurisdiction.Validate("Tax Account (Purchases)", CA.Convert(TaxAccount));
        TaxJurisdiction.Validate("Report-to Jurisdiction", ReportToJurisdiction);
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", CA.Convert(TaxAccount));

        TaxJurisdiction.Validate("Print Description", PrintDescription);
        TaxJurisdiction.Validate("Country/Region", TaxJurisdiction."Country/Region"::CA);
        TaxJurisdiction.Modify();
    end;

    local procedure InsertTaxJurisdiction2(NewCode: Code[10]; Description: Text[50]; TaxAccountSales: Code[20]; TaxAccount: Code[20]; ReportToJurisdiction: Code[10]; PrintDescription: Text[30])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Init();
        TaxJurisdiction.Validate(Code, NewCode);
        TaxJurisdiction.Insert();
        TaxJurisdiction.Validate(Description, Description);

        TaxJurisdiction.Validate("Tax Account (Sales)", TaxAccountSales);
        TaxJurisdiction.Validate("Tax Account (Purchases)", TaxAccount);
        TaxJurisdiction.Validate("Report-to Jurisdiction", ReportToJurisdiction);
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", TaxAccount);

        TaxJurisdiction.Validate("Print Description", PrintDescription);
        TaxJurisdiction.Validate("Country/Region", TaxJurisdiction."Country/Region"::CA);
        TaxJurisdiction.Modify();
    end;

    local procedure UpdatePrintOrder()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        PrintOrder: Integer;
    begin
        PrintOrder := 1;
        TaxJurisdiction.Get('CA');
        TaxJurisdiction.Validate("Print Order", PrintOrder);
        TaxJurisdiction.Modify();

        TaxJurisdiction.SetFilter(Code, '<>CA');
        TaxJurisdiction.FindSet();

        repeat
            PrintOrder += 1;
            TaxJurisdiction.Validate("Print Order", PrintOrder);
            TaxJurisdiction.Modify();
        until TaxJurisdiction.Next() = 0;
    end;

    local procedure UpdateTaxSetup()
    var
        TaxSetup: Record "Tax Setup";
    begin
        TaxSetup.Get();
        TaxSetup."Tax Account (Sales)" := CA.Convert('995710');
        TaxSetup."Tax Account (Purchases)" := CA.Convert('995710');
        TaxSetup."Reverse Charge (Purchases)" := CA.Convert('995620');
        TaxSetup.Modify();
    end;

    local procedure UpdateTaxMiniSetup()
    var
        TaxSetup: Record "Tax Setup";
        GetGLAccNo: Codeunit "Get G/L Account No. and Name";
    begin
        TaxSetup.Get();
        TaxSetup."Tax Account (Sales)" := GetGLAccNo.ProvincialSalesTax();
        TaxSetup."Tax Account (Purchases)" := GetGLAccNo.GSTHSTInputCredits();
        TaxSetup."Reverse Charge (Purchases)" := GetGLAccNo.GSTHSTInputCredits();
        TaxSetup.Modify();
    end;

    local procedure InsertTranslations()
    begin
        InsertTranslation('CA', FRCTxt, 'Gouvernement du Canada TPS', GSTInFrenchTxt);
        InsertTranslation('CANB', FRCTxt, 'Province du Nouveau-Brunswick TVH', HSTInFrenchTxt);
        InsertTranslation('CANL', FRCTxt, 'Province de Terre-Neuve-et-Labrador TVH', HSTInFrenchTxt);
        InsertTranslation('CANS', FRCTxt, 'Province de la Nouvelle-Écosse TVH', HSTInFrenchTxt);
        InsertTranslation('CAON', FRCTxt, 'Province de l''Ontario TVH', HSTInFrenchTxt);
        InsertTranslation('CAPE', FRCTxt, 'Province de l''Île-du-Prince-Édouard TVH', HSTInFrenchTxt);
        InsertTranslation('CABC', FRCTxt, 'Province de la Colombie-Britannique TVP', PSTInFrenchTxt);
        InsertTranslation('CAMB', FRCTxt, 'Province du Manitoba TVP', PSTInFrenchTxt);
        InsertTranslation('CASK', FRCTxt, 'Province de la Saskatchewan TVP', PSTInFrenchTxt);
        InsertTranslation('CAQc', FRCTxt, 'Province de Québec TVQ', QSTInFrenchTxt);
    end;

    local procedure InsertTranslation(TaxJurisdictionCode: Code[10]; LanguageCode: Code[10]; Description: Text[50]; PrintDescription: Code[30])
    var
        TaxJurisdictionTranslation: Record "Tax Jurisdiction Translation";
    begin
        TaxJurisdictionTranslation."Tax Jurisdiction Code" := TaxJurisdictionCode;
        TaxJurisdictionTranslation."Language Code" := LanguageCode;
        TaxJurisdictionTranslation.Description := Description;
        TaxJurisdictionTranslation."Print Description" := PrintDescription;
        if TaxJurisdictionTranslation.Insert() then;
    end;
}

