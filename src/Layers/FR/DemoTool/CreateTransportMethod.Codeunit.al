codeunit 101259 "Create Transport Method"
{

    trigger OnRun()
    begin
        InsertData('1', XSea);
        InsertData('2', XRail);
        InsertData('3', XRoad);
        InsertData('4', XAir);
        InsertData('5', XPost);
        InsertData('7', XFixedinstallations);
        InsertData('9', XOwnpropulsion);
        InsertData('8', XTransByIntNav);
        // Modif Demo Finance (CM) : ajout des régimes intracommunautaires
        InsertRegime('11', XTaxablesAcq);
        InsertRegime('19', XIntroRegardJobWork);
        InsertRegime('21', XExemptedDelivery);
        InsertRegime('25', XCommRegCausDev);
        InsertRegime('26', XCommRegCausRev);
        InsertRegime('29', XOtherExp);
        InsertRegime('31', XThreePartTradInvoicing);
    end;

    var
        "Transport Method": Record "Transport Method";
        XSea: Label 'Sea';
        XRail: Label 'Rail';
        XRoad: Label 'Road';
        XAir: Label 'Air';
        XPost: Label 'Post';
        XFixedinstallations: Label 'Fixed installations';
        XOwnpropulsion: Label 'Own propulsion';
        Regime: Record "Transaction Specification";
        XTransByIntNav: Label 'Transportation by internal navigation';
        XTaxablesAcq: Label 'Taxables Acquisitions';
        XIntroRegardJobWork: Label 'Introduction Regarding a Job Work';
        XExemptedDelivery: Label 'Exempted delivery';
        XCommRegCausDev: Label 'Commercial Regulation Causing Devaluation';
        XCommRegCausRev: Label 'Commercial Regulation Causing Revaluation';
        XOtherExp: Label 'Other Expeditions';
        XThreePartTradInvoicing: Label 'Three-Party Trade Invoicing';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        "Transport Method".Init();
        "Transport Method".Validate(Code, Code);
        "Transport Method".Validate(Description, Description);
        "Transport Method".Insert();
    end;

    procedure InsertRegime("Code": Code[10]; Text: Text[50])
    begin
        Regime.Init();
        Regime.Validate(Code, Code);
        Regime.Validate(Text, Text);
        Regime.Insert();
    end;
}

