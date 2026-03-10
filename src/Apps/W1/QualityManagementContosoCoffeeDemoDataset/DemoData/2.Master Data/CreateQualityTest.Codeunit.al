// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool.Helpers;
using Microsoft.QualityManagement.Configuration.Template.Test;

codeunit 5593 "Create Quality Test"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
        CreateQualityTestLookupValue: Codeunit "Create Quality Lookup Value";
        QltyTestLookupValueTableNo: Integer;
        LookupFilterLbl: Label 'where(Lookup group code=const(%1))', Locked = true, Comment = '%1 is the Lookup group code to filter with';
    begin
        QltyTestLookupValueTableNo := Database::"Qlty. Test Lookup Value";

        ContosoQualityManagement.InsertQualityTest(ApcPerGram(), ApcPerGramDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Decimal", '1..999000000', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(ColiformCount(), ColiformCountDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Decimal", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(PackageHeight(), PackageHeightDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Decimal", '10..200', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(PackageLength(), PackageLengthDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Decimal", '1..100', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(PackageWidth(), PackageWidthDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Decimal", '1..100', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(Temperature(), TemperatureDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Decimal", '-100..100', 0, 0, '', '', '');

        ContosoQualityManagement.InsertQualityTest(BrakesCheck(), BrakesCheckDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Boolean", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(GearShiftCheck(), GearShiftCheckDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Boolean", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(HandlebarAligned(), HandlebarAlignedDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Boolean", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(VisualWeldCheck(), VisualWeldCheckDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Boolean", '', 0, 0, '', '', '');

        ContosoQualityManagement.InsertQualityTest(CarContainment(), CarContainmentDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(CorrectiveAction(), CorrectiveActionDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(DescriptionOfNonConf(), DescriptionOfNonConfDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(Explanation(), ExplanationDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(NcrObjectiveEvidence(), NcrObjectiveEvidenceDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(NcrRequirement(), NcrRequirementDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(RootCauseFindings(), RootCauseFindingsDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(VerificationOfEffecti(), VerificationOfEffectiDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');

        ContosoQualityManagement.InsertQualityTest(CarRequestedDate(), CarRequestedDateDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Date", '', 0, 0, '', '', '');

        ContosoQualityManagement.InsertQualityTest(LblNcrDetail(), LblNcrDetailDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Label", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(LblNcrPlannedAction(), LblNcrPlannedActionDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Label", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(LblVerification(), LblVerificationDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Label", '', 0, 0, '', '', '');

        ContosoQualityManagement.InsertQualityTest(CarType(), CarTypeDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, CreateQualityTestLookupValue.TypeOfCar()), '', '');
        ContosoQualityManagement.InsertQualityTest(CustomerServiceRepre(), CustomerServiceRepreDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', 5200, 1, '', '', '');
        ContosoQualityManagement.InsertQualityTest(EcoliPresent(), EcoliPresentDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, CreateQualityTestLookupValue.EcoliPresent()), '', '');
        ContosoQualityManagement.InsertQualityTest(NcrClassification(), NcrClassificationDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, CreateQualityTestLookupValue.NcrClassification()), '', '');
        ContosoQualityManagement.InsertQualityTest(Odor(), OdorDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, CreateQualityTestLookupValue.Odor()), '', '');
        ContosoQualityManagement.InsertQualityTest(PackagingVisual(), PackagingVisualDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, CreateQualityTestLookupValue.PackagingVisual()), '', '');
        ContosoQualityManagement.InsertQualityTest(ReasonCode(), ReasonCodeDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, ReasonCode()), '', '');
        ContosoQualityManagement.InsertQualityTest(ShippingLabel(), ShippingLabelDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, CreateQualityTestLookupValue.ShippingLabel()), '', '');

        ContosoQualityManagement.InsertQualityTest(CoffeeUniformity(), CoffeeUniformityDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, CreateQualityTestLookupValue.CoffeeUniformity()), '', '');
        ContosoQualityManagement.InsertQualityTest(CoffeeDefect(), CoffeeDefectDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Table Lookup", '', QltyTestLookupValueTableNo, 2, StrSubstNo(LookupFilterLbl, CreateQualityTestLookupValue.CoffeeDefect()), '', '');
        ContosoQualityManagement.InsertQualityTest(Comment(), CommentDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Text", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(Moisture(), MoistureDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Integer", '0..100', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(Labeling(), LabelingDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Boolean", '', 0, 0, '', '', '');
        ContosoQualityManagement.InsertQualityTest(BagWeight(), BagWeightDescLbl, Enum::"Qlty. Test Value Type"::"Value Type Decimal", '1..100', 0, 0, '', '', 'KG');
    end;

    procedure ApcPerGram(): Code[20]
    begin
        exit(ApcPerGramTok);
    end;

    procedure BrakesCheck(): Code[20]
    begin
        exit(BrakesCheckTok);
    end;

    procedure CarContainment(): Code[20]
    begin
        exit(CarContainmentTok);
    end;

    procedure CarRequestedDate(): Code[20]
    begin
        exit(CarRequestedDateTok);
    end;

    procedure CarType(): Code[20]
    begin
        exit(CarTypeTok);
    end;

    procedure ColiformCount(): Code[20]
    begin
        exit(ColiformCountTok);
    end;

    procedure CorrectiveAction(): Code[20]
    begin
        exit(CorrectiveActionTok);
    end;

    procedure CustomerServiceRepre(): Code[20]
    begin
        exit(CustomerServiceRepreTok);
    end;

    procedure DescriptionOfNonConf(): Code[20]
    begin
        exit(DescriptionOfNonConfTok);
    end;

    procedure EcoliPresent(): Code[20]
    begin
        exit(EcoliPresentTok);
    end;

    procedure Explanation(): Code[20]
    begin
        exit(ExplanationTok);
    end;

    procedure GearShiftCheck(): Code[20]
    begin
        exit(GearShiftCheckTok);
    end;

    procedure HandlebarAligned(): Code[20]
    begin
        exit(HandlebarAlignedTok);
    end;

    procedure LblNcrDetail(): Code[20]
    begin
        exit(LblNcrDetailTok);
    end;

    procedure LblNcrPlannedAction(): Code[20]
    begin
        exit(LblNcrPlannedActionTok);
    end;

    procedure LblVerification(): Code[20]
    begin
        exit(LblVerificationTok);
    end;

    procedure NcrClassification(): Code[20]
    begin
        exit(NcrClassificationTok);
    end;

    procedure NcrObjectiveEvidence(): Code[20]
    begin
        exit(NcrObjectiveEvidenceTok);
    end;

    procedure NcrRequirement(): Code[20]
    begin
        exit(NcrRequirementTok);
    end;

    procedure Odor(): Code[20]
    begin
        exit(OdorTok);
    end;

    procedure PackageHeight(): Code[20]
    begin
        exit(PackageHeightTok);
    end;

    procedure PackageLength(): Code[20]
    begin
        exit(PackageLengthTok);
    end;

    procedure PackageWidth(): Code[20]
    begin
        exit(PackageWidthTok);
    end;

    procedure PackagingVisual(): Code[20]
    begin
        exit(PackagingVisualTok);
    end;

    procedure ReasonCode(): Code[20]
    begin
        exit(ReasonCodeTok);
    end;

    procedure RootCauseFindings(): Code[20]
    begin
        exit(RootCauseFindingsTok);
    end;

    procedure ShippingLabel(): Code[20]
    begin
        exit(ShippingLabelTok);
    end;

    procedure Temperature(): Code[20]
    begin
        exit(TemperatureTok);
    end;

    procedure VerificationOfEffecti(): Code[20]
    begin
        exit(VerificationOfEffectiTok);
    end;

    procedure VisualWeldCheck(): Code[20]
    begin
        exit(VisualWeldCheckTok);
    end;

    procedure CoffeeUniformity(): Code[20]
    begin
        exit(CoffeeUniformityTok);
    end;

    procedure CoffeeDefect(): Code[20]
    begin
        exit(CoffeeDefectTok);
    end;

    procedure Comment(): Code[20]
    begin
        exit(CommentTok);
    end;

    procedure Moisture(): Code[20]
    begin
        exit(MoistureTok);
    end;

    procedure Labeling(): Code[20]
    begin
        exit(LabelingTok);
    end;

    procedure BagWeight(): Code[20]
    begin
        exit(BagWeightTok);
    end;

    var
        ApcPerGramTok: Label 'APCPERGRAM', MaxLength = 20;
        BrakesCheckTok: Label 'BRAKESCHECK', MaxLength = 20;
        CarContainmentTok: Label 'CARCONTAINMENT', MaxLength = 20;
        CarRequestedDateTok: Label 'CARREQUESTEDDATE', MaxLength = 20;
        CarTypeTok: Label 'CARTYPE', MaxLength = 20;
        ColiformCountTok: Label 'COLIFORMCOUNT', MaxLength = 20;
        CorrectiveActionTok: Label 'CORRECTIVEACTION', MaxLength = 20;
        CustomerServiceRepreTok: Label 'CUSTOMERSERVICEREPRE', MaxLength = 20;
        DescriptionOfNonConfTok: Label 'DESCRIPTIONOFNONCONF', MaxLength = 20;
        EcoliPresentTok: Label 'ECOLIPRESENT', MaxLength = 20;
        ExplanationTok: Label 'EXPLANATION', MaxLength = 20;
        GearShiftCheckTok: Label 'GEARSHIFTCHECK', MaxLength = 20;
        HandlebarAlignedTok: Label 'HANDLEBARALIGNED', MaxLength = 20;
        LblNcrDetailTok: Label 'LBLNCRDETAIL', MaxLength = 20;
        LblNcrPlannedActionTok: Label 'LBLNCRPLANNEDACTION', MaxLength = 20;
        LblVerificationTok: Label 'LBLVERIFICATION', MaxLength = 20;
        NcrClassificationTok: Label 'NCRCLASSIFICATION', MaxLength = 20;
        NcrObjectiveEvidenceTok: Label 'NCROBJECTIVEEVIDENCE', MaxLength = 20;
        NcrRequirementTok: Label 'NCRREQUIREMENT', MaxLength = 20;
        OdorTok: Label 'ODOR', MaxLength = 20;
        PackageHeightTok: Label 'PACKAGEHEIGHT', MaxLength = 20;
        PackageLengthTok: Label 'PACKAGELENGTH', MaxLength = 20;
        PackageWidthTok: Label 'PACKAGEWIDTH', MaxLength = 20;
        PackagingVisualTok: Label 'PACKAGINGVISUAL', MaxLength = 20;
        ReasonCodeTok: Label 'REASONCODE', MaxLength = 20;
        RootCauseFindingsTok: Label 'ROOTCAUSEFINDINGS', MaxLength = 20;
        ShippingLabelTok: Label 'SHIPPINGLABEL', MaxLength = 20;
        TemperatureTok: Label 'TEMPERATURE', MaxLength = 20;
        VerificationOfEffectiTok: Label 'VERIFICATIONOFFFECTI', MaxLength = 20;
        VisualWeldCheckTok: Label 'VISUALWELDCHECK', MaxLength = 20;
        CoffeeUniformityTok: Label 'COFFEE_UNIFORMITY', MaxLength = 20;
        CoffeeDefectTok: Label 'COFFEE_DEFECT', MaxLength = 20;
        CommentTok: Label 'COMMENT', MaxLength = 20;
        MoistureTok: Label 'MOISTURE', MaxLength = 20;
        LabelingTok: Label 'LABELING', MaxLength = 20;
        BagWeightTok: Label 'BAG_WEIGHT', MaxLength = 20;

        ApcPerGramDescLbl: Label 'Aerobic Plate Count per Gram', MaxLength = 100;
        BrakesCheckDescLbl: Label 'Brakes Check', MaxLength = 100;
        CarContainmentDescLbl: Label 'Containment Action(s) including correction', MaxLength = 100;
        CarRequestedDateDescLbl: Label 'Requested Date', MaxLength = 100;
        CarTypeDescLbl: Label 'Type of CAR', MaxLength = 100;
        ColiformCountDescLbl: Label 'Coliform Count', MaxLength = 100;
        CorrectiveActionDescLbl: Label 'Corrective Action', MaxLength = 100;
        CustomerServiceRepreDescLbl: Label 'Customer Service Representative', MaxLength = 100;
        DescriptionOfNonConfDescLbl: Label 'Description of Non Conformance', MaxLength = 100;
        EcoliPresentDescLbl: Label 'ECOLIPRESENT', MaxLength = 100;
        ExplanationDescLbl: Label 'Explanation', MaxLength = 100;
        GearShiftCheckDescLbl: Label 'Gear Shift Check', MaxLength = 100;
        HandlebarAlignedDescLbl: Label 'Handlebar Aligned', MaxLength = 100;
        LblNcrDetailDescLbl: Label 'Details of Nonconformity', MaxLength = 100;
        LblNcrPlannedActionDescLbl: Label 'Planned Actions', MaxLength = 100;
        LblVerificationDescLbl: Label 'Verification', MaxLength = 100;
        NcrClassificationDescLbl: Label 'Classification', MaxLength = 100;
        NcrObjectiveEvidenceDescLbl: Label 'Objective Evidence', MaxLength = 100;
        NcrRequirementDescLbl: Label 'Requirement / Clause No.(s)', MaxLength = 100;
        OdorDescLbl: Label 'Odor', MaxLength = 100;
        PackageHeightDescLbl: Label 'Package Height', MaxLength = 100;
        PackageLengthDescLbl: Label 'package length', MaxLength = 100;
        PackageWidthDescLbl: Label 'Package Width', MaxLength = 100;
        PackagingVisualDescLbl: Label 'Packaging Visual', MaxLength = 100;
        ReasonCodeDescLbl: Label 'Reason Code', MaxLength = 100;
        RootCauseFindingsDescLbl: Label 'Root Cause Findings', MaxLength = 100;
        ShippingLabelDescLbl: Label 'Shipping Label', MaxLength = 100;
        TemperatureDescLbl: Label 'Temperature', MaxLength = 100;
        VerificationOfEffectiDescLbl: Label 'Verification of Effectiveness', MaxLength = 100;
        VisualWeldCheckDescLbl: Label 'Visual Weld Check', MaxLength = 100;
        CoffeeUniformityDescLbl: Label 'Coffee bean uniformity', MaxLength = 100;
        CoffeeDefectDescLbl: Label 'Coffee bean defect type', MaxLength = 100;
        CommentDescLbl: Label 'Additional comments', MaxLength = 100;
        MoistureDescLbl: Label 'Moisture content (%)', MaxLength = 100;
        LabelingDescLbl: Label 'Labeling correct and readable', MaxLength = 100;
        BagWeightDescLbl: Label 'Bag weight (kg)', MaxLength = 100;
}
