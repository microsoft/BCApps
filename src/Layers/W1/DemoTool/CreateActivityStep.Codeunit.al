codeunit 101582 "Create Activity Step"
{

    trigger OnRun()
    begin
        InsertData(XCPRES, 10000, 0, XInvitekeypersonstopresentat, 2, '');
        InsertData(XCPRES, 20000, 0, XCheckdatesforshowroomavail, 1, '<+1W>');
        InsertData(XCPRES, 30000, 2, XCallcustomertoconfirmdate, 2, '<+1W>');
        InsertData(XCPRES, 40000, 0, XBookshowroomect, 1, '<+1W>');
        InsertData(XCPRES, 50000, 0, XTailorpresentationtocust, 2, '<+2W>');
        InsertData(XINIT, 5000, 0, XVerifyqualityofopportunity, 2, '');
        InsertData(XINIT, 10000, 0, XIdentifykeypersons, 1, '<+1W>');
        InsertData(XNEEDS, 10000, 0, XEstcustomerneeds, 0, '');
        InsertData(XNEEDS, 20000, 2, XSetupmeeting, 1, '<+3D>');
        InsertData(XNEEDS, 25000, 1, XGothroughexpectationsandneeds, 2, '<+2W>');
        InsertData(XNEEDS, 30000, 0, XVerifychangecustomerneeds, 1, '<+3W>');
        InsertData(XPROPOSAL, 10000, 0, XDraftaproposal, 2, '');
        InsertData(XPROPOSAL, 20000, 0, XInternalapprovementofproposal, 2, '<+3D>');
        InsertData(XPROPOSAL, 30000, 2, XArrngedateforthepresoftheprop, 2, '<+1W>');
        InsertData(XPROPOSAL, 40000, 1, XPresthepropandsetdateforfolup, 2, '<+2W>');
        InsertData(XPPRES, 10000, 2, XMakeappforprodpresentation, 1, '');
        InsertData(XPPRES, 20000, 0, XConfirmproductpresinwrit, 2, '<+2D>');
        InsertData(XPPRES, 30000, 0, XBooknecessaryequipment, 1, '<+2D>');
        InsertData(XPWORK, 10000, 2, XMakeappforprodpresworkshop, 1, '');
        InsertData(XPWORK, 20000, 0, XConfprodpresworkshopinwriting, 0, '<+3D>');
        InsertData(XPWORK, 30000, 0, XBooknecessaryequipment, 0, '<+3D>');
        InsertData(XPWORK, 40000, 0, XEnsureavailofintresources, 1, '<+3D>');
        InsertData(XQUAL, 10000, 0, XEstcustomerneeds, 1, '');
        InsertData(XQUAL, 20000, 0, XSendletterofintroduction, 1, '<+1W>');
        InsertData(XQUAL, 30000, 2, XFollowuponintroletter, 2, '<+2W>');
        InsertData(XQUAL, 40000, 0, XVerifychangecustomerneeds, 2, '<+2W+1D>');
        InsertData(XSIGN, 10000, 0, XCheckdeliverystatonprods, 0, '');
        InsertData(XSIGN, 20000, 1, XSignContract, 2, '<+1W>');
        InsertData(XSIGN, 30000, 0, XArrthattheadminhndlsthecontr, 1, '<+2W>');
        InsertData(XSIGN, 40000, 0, XFollowuponcustsatisfaction, 1, '<+6M>');
        InsertData(XWORKSHOP, 10000, 2, XMakeappointmentforworkshop, 1, '');
        InsertData(XWORKSHOP, 20000, 0, XConfirmworkshopinwriting, 2, '<+3D>');
        InsertData(XWORKSHOP, 30000, 0, XEnsureavailofintresources, 2, '<+3D>');
    end;

    var
        "Activity Step": Record "Activity Step";
        XCPRES: Label 'C-PRES';
        XINIT: Label 'INIT';
        XNEEDS: Label 'NEEDS';
        XPROPOSAL: Label 'PROPOSAL';
        XPPRES: Label 'P-PRES';
        XPWORK: Label 'P-WORK';
        XQUAL: Label 'QUAL';
        XSIGN: Label 'SIGN';
        XWORKSHOP: Label 'WORKSHOP';
        XInvitekeypersonstopresentat: Label 'Invite key persons to presentation';
        XCheckdatesforshowroomavail: Label 'Check dates for showroom availability';
        XCallcustomertoconfirmdate: Label 'Call customer to confirm date';
        XBookshowroomect: Label 'Book showroom ect.';
        XTailorpresentationtocust: Label 'Tailor presentation to customer';
        XVerifyqualityofopportunity: Label 'Verify quality of opportunity';
        XIdentifykeypersons: Label 'Identify key persons';
        XEstcustomerneeds: Label 'Est. customer needs';
        XSetupmeeting: Label 'Set up meeting';
        XGothroughexpectationsandneeds: Label 'Go through expectations and needs';
        XVerifychangecustomerneeds: Label 'Verify/change customer needs';
        XDraftaproposal: Label 'Draft a proposal';
        XInternalapprovementofproposal: Label 'Internal approvement of proposal';
        XArrngedateforthepresoftheprop: Label 'Arrange date for the presentation of the proposal';
        XPresthepropandsetdateforfolup: Label 'Present the proposal and set date for follow-up';
        XMakeappforprodpresentation: Label 'Make appointment for product presentation';
        XConfirmproductpresinwrit: Label 'Confirm product presentation in writing';
        XBooknecessaryequipment: Label 'Book necessary equipment';
        XMakeappforprodpresworkshop: Label 'Make appointment for product presentation/workshop';
        XConfprodpresworkshopinwriting: Label 'Confirm product presentation/workshop in writing';
        XEnsureavailofintresources: Label 'Ensure availability of internal resources';
        XSendletterofintroduction: Label 'Send letter of introduction';
        XFollowuponintroletter: Label 'Follow-up on introduction letter';
        XCheckdeliverystatonprods: Label 'Check delivery status on products';
        XSignContract: Label 'Sign Contract';
        XArrthattheadminhndlsthecontr: Label 'Arrange that the admin. handles the contract';
        XFollowuponcustsatisfaction: Label 'Follow-up on customer satisfaction';
        XMakeappointmentforworkshop: Label 'Make appointment for workshop';
        XConfirmworkshopinwriting: Label 'Confirm workshop in writing';

    procedure InsertData("Activity Code": Code[10]; "Step No.": Integer; Type: Option; Description: Text[50]; Priority: Option; "Date Formula": Text[30])
    begin
        "Activity Step".Init();
        "Activity Step".Validate("Activity Code", "Activity Code");
        "Activity Step".Validate("Step No.", "Step No.");
        "Activity Step".Validate(Type, Type);
        "Activity Step".Validate(Description, Description);
        "Activity Step".Validate(Priority, Priority);
        Evaluate("Activity Step"."Date Formula", "Date Formula");
        "Activity Step".Validate("Date Formula");
        "Activity Step".Insert();
    end;
}

