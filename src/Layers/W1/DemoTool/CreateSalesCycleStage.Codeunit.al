codeunit 101591 "Create Sales Cycle Stage"
{

    trigger OnRun()
    begin
        InsertData(XEXLARGE, 1, XInitial, 2, 10, XINIT, false, true);
        InsertData(XEXLARGE, 2, XUnderstandingneedsmeeting, 35, 25, XNEEDS, false, true);
        InsertData(XEXLARGE, 3, XProductPresentationWorkshop, 70, 60, XPWORK, true, true);
        InsertData(XEXLARGE, 4, XProposallc, 85, 80, XPROPOSAL, true, false);
        InsertData(XEXLARGE, 5, XSignContract, 95, 100, XSIGN, true, false);
        InsertData(XEXSMALL, 1, XInitial, 2, 20, XINIT, false, true);
        InsertData(XEXSMALL, 2, XPresentation, 50, 40, XPWORK, false, true);
        InsertData(XEXSMALL, 3, XProposallc, 80, 60, XPROPOSAL, true, false);
        InsertData(XEXSMALL, 4, XSignContract, 95, 80, XSIGN, true, false);
        InsertData(XFIRSTLARGE, 1, XInitial, 2, 10, XINIT, false, true);
        InsertData(XFIRSTLARGE, 2, XQualification, 5, 20, XQUAL, false, false);
        InsertData(XFIRSTLARGE, 3, XCompanyPresentation, 20, 30, XCPRES, false, false);
        InsertData(XFIRSTLARGE, 4, XProductPresentation, 40, 40, XPPRES, false, false);
        InsertData(XFIRSTLARGE, 5, XWorkshoplc, 50, 60, XWORKSHOP, true, true);
        InsertData(XFIRSTLARGE, 6, XProposallc, 80, 80, XPROPOSAL, true, true);
        InsertData(XFIRSTLARGE, 7, XSignContract, 95, 100, XSIGN, true, false);
        InsertData(XFIRSTSMALL, 1, XInitial, 2, 20, XINIT, false, false);
        InsertData(XFIRSTSMALL, 2, XQualification, 5, 40, XQUAL, false, false);
        InsertData(XFIRSTSMALL, 3, XPresentation, 40, 60, XPWORK, true, true);
        InsertData(XFIRSTSMALL, 4, XProposallc, 60, 80, XPROPOSAL, true, false);
        InsertData(XFIRSTSMALL, 5, XSignContract, 95, 100, XSIGN, true, false);
    end;

    var
        SalesCycleStage: Record "Sales Cycle Stage";
        XEXLARGE: Label 'EX-LARGE';
        XFIRSTLARGE: Label 'FIRSTLARGE';
        XEXSMALL: Label 'EX-SMALL';
        XFIRSTSMALL: Label 'FIRSTSMALL';
        XInitial: Label 'Initial';
        XINIT: Label 'INIT';
        XUnderstandingneedsmeeting: Label 'Understanding needs meeting';
        XNEEDS: Label 'NEEDS';
        XProductPresentationWorkshop: Label 'Product Presentation/Workshop';
        XProposallc: Label 'Proposal';
        XPROPOSAL: Label 'PROPOSAL';
        XSignContract: Label 'Sign Contract';
        XPresentation: Label 'Presentation';
        XPWORK: Label 'P-WORK';
        XSIGN: Label 'SIGN';
        XQualification: Label 'Qualification';
        XQUAL: Label 'QUAL';
        XCompanyPresentation: Label 'Company Presentation';
        XCPRES: Label 'C-PRES';
        XProductPresentation: Label 'Product Presentation';
        XPPRES: Label 'P-PRES';
        XWorkshoplc: Label 'Workshop';
        XWORKSHOP: Label 'WORKSHOP';
        XEXISTING: Label 'EXISTING';
        XNEW: Label 'NEW';

    procedure InsertData("Sales Cycle Code": Code[10]; Stage: Integer; Description: Text[30]; "Completed %": Decimal; "Success %": Decimal; "Activity Code": Code[10]; "Quote Required": Boolean; "Allow Skip": Boolean)
    begin
        SalesCycleStage.Init();
        SalesCycleStage.Validate("Sales Cycle Code", "Sales Cycle Code");
        SalesCycleStage.Validate(Stage, Stage);
        SalesCycleStage.Validate(Description, Description);
        SalesCycleStage.Validate("Completed %", "Completed %");
        SalesCycleStage.Validate("Chances of Success %", "Success %");
        SalesCycleStage.Validate("Activity Code", "Activity Code");
        SalesCycleStage.Validate("Quote Required", "Quote Required");
        SalesCycleStage.Validate("Allow Skip", "Allow Skip");
        SalesCycleStage.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(XEXISTING, 1, XInitial, 2, 10, XINIT, false, true);
        InsertData(XEXISTING, 2, XPresentation, 50, 40, XPWORK, false, true);
        InsertData(XEXISTING, 3, XProposallc, 80, 80, XPROPOSAL, true, false);
        InsertData(XEXISTING, 4, XSignContract, 95, 100, XSIGN, true, false);
        InsertData(XNEW, 1, XInitial, 2, 10, XINIT, false, false);
        InsertData(XNEW, 2, XQualification, 5, 20, XQUAL, false, false);
        InsertData(XNEW, 3, XPresentation, 40, 50, XPWORK, true, true);
        InsertData(XNEW, 4, XProposallc, 60, 75, XPROPOSAL, true, false);
        InsertData(XNEW, 5, XSignContract, 95, 100, XSIGN, true, false);
    end;
}

