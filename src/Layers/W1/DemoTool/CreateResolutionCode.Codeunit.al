codeunit 117020 "Create Resolution Code"
{

    trigger OnRun()
    begin
        InsertData('1', XSoftwarecorrectionreset);
        InsertData('2', XSoftwareupgrade);
        InsertData('3', XProductupgradeonrequest);
        InsertData('A', XReplacement);
        InsertData('A1', XRefilling);
        InsertData('B', XMechanicalalignment);
        InsertData('C', XElectricalalignment);
        InsertData('D', XResoldering);
        InsertData('D1', XRefttngpttngbckinpstncnnctrtb);
        InsertData('E', XCleaning);
        InsertData('F', XLubrication);
        InsertData('G', XRepairedelectricalparts);
        InsertData('H', XRepairedmechanicalparts);
        InsertData('I', XModifictnrqustdbymnfctrr);
        InsertData('J', XRemoved);
        InsertData('K', XAdded);
        InsertData('L', XFunctionalcheck);
        InsertData('M', XSpecificationmeasurement);
        InsertData('N', XMaintenance);
        InsertData('O', XRefurbishingreconditioning);
        InsertData('P', XPreventivepartsreplacement);
        InsertData('Q', XPrvntvactnwthtprtsrplacmnt);
        InsertData('U', XExplanationforcustomer);
        InsertData('V', XCostestimationrefused);
        InsertData('W', XCostestimationwithparts);
        InsertData('X', XCostestimationwithoutparts);
        InsertData('Y', XReturnwithoutrepair);
        InsertData('Z', XSetexchange);
        InsertData('Z1', XProdxchngreptooxpensive);
        InsertData('Z2', XProdxchngetoomnyvistsrepairs);
        InsertData('Z3', XProdxchangepartsnotavailable);
        InsertData('Z4', XProdxchngeimpossibletorepair);
        InsertData('Z5', XProdxchngeonrequestofretailr);
        InsertData('Z6', XProdxchngeonrequestofmnfctrr);
    end;

    var
        XSoftwarecorrectionreset: Label 'Software correction / reset';
        XSoftwareupgrade: Label 'Software upgrade';
        XProductupgradeonrequest: Label 'Product upgrade (on request)';
        XReplacement: Label 'Replacement';
        XRefilling: Label 'Refilling';
        XMechanicalalignment: Label 'Mechanical alignment';
        XElectricalalignment: Label 'Electrical alignment';
        XResoldering: Label 'Resoldering';
        XRefttngpttngbckinpstncnnctrtb: Label 'Refitting / putting back in position (connector / tube ?)';
        XCleaning: Label 'Cleaning';
        XLubrication: Label 'Lubrication';
        XRepairedelectricalparts: Label 'Repaired electrical parts';
        XRepairedmechanicalparts: Label 'Repaired mechanical parts';
        XModifictnrqustdbymnfctrr: Label 'Modification requested by manufacturer';
        XRemoved: Label 'Removed';
        XAdded: Label 'Added';
        XFunctionalcheck: Label 'Functional check';
        XSpecificationmeasurement: Label 'Specification measurement';
        XMaintenance: Label 'Maintenance';
        XRefurbishingreconditioning: Label 'Refurbishing / reconditioning';
        XPreventivepartsreplacement: Label 'Preventive parts replacement';
        XPrvntvactnwthtprtsrplacmnt: Label 'Preventive action without parts replacement';
        XExplanationforcustomer: Label 'Explanation for customer';
        XCostestimationrefused: Label 'Cost estimation refused';
        XCostestimationwithparts: Label 'Cost estimation with parts';
        XCostestimationwithoutparts: Label 'Cost estimation without parts';
        XReturnwithoutrepair: Label 'Return without repair';
        XSetexchange: Label 'Set exchange';
        XProdxchngreptooxpensive: Label 'Product exchange (repair too expensive)';
        XProdxchngetoomnyvistsrepairs: Label 'Product exchange (too many visits / repairs)';
        XProdxchangepartsnotavailable: Label 'Product exchange (parts not available)';
        XProdxchngeimpossibletorepair: Label 'Product exchange (impossible to repair)';
        XProdxchngeonrequestofretailr: Label 'Product exchange (on request of retailer)';
        XProdxchngeonrequestofmnfctrr: Label 'Product exchange (on request of manufacturer)';

    procedure InsertData("Code": Text[250]; Description: Text[250])
    var
        ResolutionCode: Record "Resolution Code";
    begin
        ResolutionCode.Init();
        ResolutionCode.Validate(Code, Code);
        ResolutionCode.Validate(Description, Description);
        ResolutionCode.Insert(true);
    end;
}

