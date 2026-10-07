codeunit 101581 "Create Activity"
{

    trigger OnRun()
    begin
        InsertData(XCPRES, XCompanyPresentationtasks);
        InsertData(XINIT, XInitialtasks);
        InsertData(XNEEDS, XUnderstandingneedstasks);
        InsertData(XPROPOSAL, XProposaltasks);
        InsertData(XPPRES, XProductPresentation);
        InsertData(XPWORK, XPresentationWorkshop);
        InsertData(XQUAL, XQualificationtasks);
        InsertData(XSIGN, XSignContracttasks);
        InsertData(XWORKSHOP, XWorkshoptasks);
    end;

    var
        Activity: Record Activity;
        XCPRES: Label 'C-PRES';
        XCompanyPresentationtasks: Label 'Company Presentation tasks';
        XINIT: Label 'INIT';
        XInitialtasks: Label 'Initial tasks';
        XNEEDS: Label 'NEEDS';
        XUnderstandingneedstasks: Label 'Understanding needs tasks';
        XPROPOSAL: Label 'PROPOSAL';
        XProposaltasks: Label 'Proposal tasks';
        XPPRES: Label 'P-PRES';
        XProductPresentation: Label 'Product Presentation';
        XPWORK: Label 'P-WORK';
        XPresentationWorkshop: Label 'Presentation/Workshop';
        XQUAL: Label 'QUAL';
        XQualificationtasks: Label 'Qualification tasks';
        XSIGN: Label 'SIGN';
        XSignContracttasks: Label 'Sign Contract tasks';
        XWORKSHOP: Label 'WORKSHOP';
        XWorkshoptasks: Label 'Workshop tasks';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        Activity.Init();
        Activity.Validate(Code, Code);
        Activity.Validate(Description, Description);
        Activity.Insert();
    end;
}

