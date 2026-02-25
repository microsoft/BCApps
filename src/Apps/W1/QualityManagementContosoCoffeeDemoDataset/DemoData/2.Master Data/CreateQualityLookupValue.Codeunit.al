// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool.Helpers;

codeunit 5594 "Create Quality Lookup Value"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
    begin
        ContosoQualityManagement.InsertQualityTestLookupValue(EcoliPresent(), Absent(), NoEColiDetectedLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(EcoliPresent(), Present(), AnyEColiDetectedLbl);

        ContosoQualityManagement.InsertQualityTestLookupValue(NcrClassification(), Major(), MajorLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(NcrClassification(), Minor(), MinorLbl);

        ContosoQualityManagement.InsertQualityTestLookupValue(Odor(), BadOdor(), BadOdorDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(Odor(), MildOdor(), MildOdorDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(Odor(), NoOdor(), NoOdorDescLbl);

        ContosoQualityManagement.InsertQualityTestLookupValue(PackagingVisual(), Heavy(), HeavyDamageDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(PackagingVisual(), Light(), LightDamageDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(PackagingVisual(), Undamaged(), UndamagedPackagingDescLbl);

        ContosoQualityManagement.InsertQualityTestLookupValue(ShippingLabel(), BadPosition(), IncorrectPositionOfLabelLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(ShippingLabel(), Blurred(), LabelIsBlurredLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(ShippingLabel(), Damage(), LabelIsDamagedLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(ShippingLabel(), Good(), LabelIsGoodLbl);

        ContosoQualityManagement.InsertQualityTestLookupValue(TypeOfCar(), ACar(), AuditLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(TypeOfCar(), ICar(), InternalOrVendorLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(TypeOfCar(), SCar(), CustomerLbl);

        ContosoQualityManagement.InsertQualityTestLookupValue(CoffeeDefect(), CoffeeDefectColor(), CoffeeDefectColorDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(CoffeeDefect(), CoffeeDefectForeign(), CoffeeDefectForeignDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(CoffeeDefect(), CoffeeDefectInsect(), CoffeeDefectInsectDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(CoffeeDefect(), CoffeeDefectOdor(), CoffeeDefectOdorDescLbl);

        ContosoQualityManagement.InsertQualityTestLookupValue(CoffeeUniformity(), CoffeeUniformityIrregular(), CoffeeUniformityIrregularDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(CoffeeUniformity(), CoffeeUniformityMixed(), CoffeeUniformityMixedDescLbl);
        ContosoQualityManagement.InsertQualityTestLookupValue(CoffeeUniformity(), CoffeeUniformityUniform(), CoffeeUniformityUniformDescLbl);
    end;

    procedure EcoliPresent(): Code[20]
    begin
        exit(EcoliPresentTok);
    end;

    procedure NcrClassification(): Code[20]
    begin
        exit(NcrClassificationTok);
    end;

    procedure Odor(): Code[20]
    begin
        exit(OdorTok);
    end;

    procedure PackagingVisual(): Code[20]
    begin
        exit(PackagingVisualTok);
    end;

    procedure ShippingLabel(): Code[20]
    begin
        exit(ShippingLabelTok);
    end;

    procedure TypeOfCar(): Code[20]
    begin
        exit(TypeOfCarTok);
    end;

    procedure CoffeeDefect(): Code[20]
    begin
        exit(CoffeeDefectTok);
    end;

    procedure CoffeeUniformity(): Code[20]
    begin
        exit(CoffeeUniformityTok);
    end;

    procedure Absent(): Code[100]
    begin
        exit(AbsentTok);
    end;

    procedure Present(): Code[100]
    begin
        exit(PresentTok);
    end;

    procedure Major(): Code[100]
    begin
        exit(MajorTok);
    end;

    procedure Minor(): Code[100]
    begin
        exit(MinorTok);
    end;

    procedure BadOdor(): Code[100]
    begin
        exit(BadOdorTok);
    end;

    procedure MildOdor(): Code[100]
    begin
        exit(MildOdorTok);
    end;

    procedure NoOdor(): Code[100]
    begin
        exit(NoOdorTok);
    end;

    procedure Heavy(): Code[100]
    begin
        exit(HeavyTok);
    end;

    procedure Light(): Code[100]
    begin
        exit(LightTok);
    end;

    procedure Undamaged(): Code[100]
    begin
        exit(UndamagedTok);
    end;

    procedure BadPosition(): Code[100]
    begin
        exit(BadPositionTok);
    end;

    procedure Blurred(): Code[100]
    begin
        exit(BlurredTok);
    end;

    procedure Damage(): Code[100]
    begin
        exit(DamageTok);
    end;

    procedure Good(): Code[100]
    begin
        exit(GoodTok);
    end;

    procedure ACar(): Code[100]
    begin
        exit(ACarTok);
    end;

    procedure ICar(): Code[100]
    begin
        exit(ICarTok);
    end;

    procedure SCar(): Code[100]
    begin
        exit(SCarTok);
    end;

    procedure CoffeeDefectColor(): Code[100]
    begin
        exit(CoffeeDefectColorTok);
    end;

    procedure CoffeeDefectForeign(): Code[100]
    begin
        exit(CoffeeDefectForeignTok);
    end;

    procedure CoffeeDefectInsect(): Code[100]
    begin
        exit(CoffeeDefectInsectTok);
    end;

    procedure CoffeeDefectOdor(): Code[100]
    begin
        exit(CoffeeDefectOdorTok);
    end;

    procedure CoffeeUniformityIrregular(): Code[100]
    begin
        exit(CoffeeUniformityIrregularTok);
    end;

    procedure CoffeeUniformityMixed(): Code[100]
    begin
        exit(CoffeeUniformityMixedTok);
    end;

    procedure CoffeeUniformityUniform(): Code[100]
    begin
        exit(CoffeeUniformityUniformTok);
    end;

    var
        EcoliPresentTok: Label 'ECOLIPRESENT', MaxLength = 20;
        NcrClassificationTok: Label 'NCRCLASSIFICATION', MaxLength = 20;
        OdorTok: Label 'ODOR', MaxLength = 20;
        PackagingVisualTok: Label 'PACKAGINGVISUAL', MaxLength = 20;
        ShippingLabelTok: Label 'SHIPPINGLABEL', MaxLength = 20;
        TypeOfCarTok: Label 'TYPEOFCAR', MaxLength = 20;
        CoffeeDefectTok: Label 'COFFEE_DEFECT', MaxLength = 20;
        CoffeeUniformityTok: Label 'COFFEE_UNIFORMITY', MaxLength = 20;

        AbsentTok: Label 'ABSENT', MaxLength = 100;
        PresentTok: Label 'PRESENT', MaxLength = 100;
        MajorTok: Label 'MAJOR', MaxLength = 100;
        MinorTok: Label 'MINOR', MaxLength = 100;
        BadOdorTok: Label 'BADODOR', MaxLength = 100;
        MildOdorTok: Label 'MILDODOR', MaxLength = 100;
        NoOdorTok: Label 'NOODOR', MaxLength = 100;
        HeavyTok: Label 'HEAVY', MaxLength = 100;
        LightTok: Label 'LIGHT', MaxLength = 100;
        UndamagedTok: Label 'UNDAMAGED', MaxLength = 100;
        BadPositionTok: Label 'BADPOSITION', MaxLength = 100;
        BlurredTok: Label 'BLURRED', MaxLength = 100;
        DamageTok: Label 'DAMAGE', MaxLength = 100;
        GoodTok: Label 'GOOD', MaxLength = 100;
        ACarTok: Label 'ACAR', MaxLength = 100;
        ICarTok: Label 'ICAR', MaxLength = 100;
        SCarTok: Label 'SCAR', MaxLength = 100;
        CoffeeDefectColorTok: Label 'COLOR', MaxLength = 100;
        CoffeeDefectForeignTok: Label 'FOREIGN', MaxLength = 100;
        CoffeeDefectInsectTok: Label 'INSECT', MaxLength = 100;
        CoffeeDefectOdorTok: Label 'ODOR', MaxLength = 100;
        CoffeeUniformityIrregularTok: Label 'IRREGULAR', MaxLength = 100;
        CoffeeUniformityMixedTok: Label 'MIXED', MaxLength = 100;
        CoffeeUniformityUniformTok: Label 'UNIFORM', MaxLength = 100;

        NoEColiDetectedLbl: Label 'No E-Coli detected', MaxLength = 250;
        AnyEColiDetectedLbl: Label 'Any E-Coli detected', MaxLength = 250;
        MajorLbl: Label 'Major', MaxLength = 250;
        MinorLbl: Label 'Minor', MaxLength = 250;
        BadOdorDescLbl: Label 'Bad odor', MaxLength = 250;
        MildOdorDescLbl: Label 'Mild Odor', MaxLength = 250;
        NoOdorDescLbl: Label 'No Odor', MaxLength = 250;
        HeavyDamageDescLbl: Label 'Heavy Damage', MaxLength = 250;
        LightDamageDescLbl: Label 'Light Damage', MaxLength = 250;
        UndamagedPackagingDescLbl: Label 'Undamaged packaging', MaxLength = 250;
        IncorrectPositionOfLabelLbl: Label 'Incorrect position of label', MaxLength = 250;
        LabelIsBlurredLbl: Label 'Label is blurred', MaxLength = 250;
        LabelIsDamagedLbl: Label 'Label is damaged', MaxLength = 250;
        LabelIsGoodLbl: Label 'Label is in good position and placement', MaxLength = 250;
        AuditLbl: Label 'Audit', MaxLength = 250;
        InternalOrVendorLbl: Label 'Internal or Vendor', MaxLength = 250;
        CustomerLbl: Label 'Customer', MaxLength = 250;
        CoffeeDefectColorDescLbl: Label 'Black or discolored beans', MaxLength = 250;
        CoffeeDefectForeignDescLbl: Label 'Stones, sticks, or other non-coffee debris', MaxLength = 250;
        CoffeeDefectInsectDescLbl: Label 'Insect-Damaged Beans: visible holes or eaten portions', MaxLength = 250;
        CoffeeDefectOdorDescLbl: Label 'Unpleasant or abnormal smell', MaxLength = 250;
        CoffeeUniformityIrregularDescLbl: Label 'Beans have significant inconsistencies; likely to affect roasting and flavor', MaxLength = 250;
        CoffeeUniformityMixedDescLbl: Label 'Beans show moderate variation in size or shape; acceptable but not ideal', MaxLength = 250;
        CoffeeUniformityUniformDescLbl: Label 'Beans are consistent in size, shape, and color; minimal variation', MaxLength = 250;
}
