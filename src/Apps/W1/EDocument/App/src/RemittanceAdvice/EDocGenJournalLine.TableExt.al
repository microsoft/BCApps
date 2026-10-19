namespace Microsoft.eServices.EDocument.RemittanceAdvice;

using Microsoft.Finance.GeneralLedger.Journal;

tableextension 6101 "E-Doc. Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(6100; "Remit. Advice E-Doc. Created"; Boolean)
        {
            Caption = 'Remit. Advice E-Doc. Created';
            Editable = false;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies that an electronic document (remittance advice) was created for this payment line.';
        }
    }

    trigger OnDelete()
    begin
        if Rec."Remit. Advice E-Doc. Created" and GuiAllowed() then
            if not Confirm(DeleteRemitAdviceEDocCreatedQst) then
                Error('');
    end;

    var
        DeleteRemitAdviceEDocCreatedQst: Label 'A remittance advice e-document has been created for this payment line. If you delete the line, the e-document will no longer be linked to it.\\ Do you want to continue?';

    /// <summary>
    /// Flags this Gen. Journal Line as having a remittance advice e-document created for it.
    /// </summary>
    procedure SetRemitAdviceEDocCreated()
    begin
        Rec."Remit. Advice E-Doc. Created" := true;
        Rec.Modify();
    end;

    /// <summary>
    /// Clears the remittance advice e-document flag on this Gen. Journal Line.
    /// </summary>
    procedure ClearRemitAdviceEDocCreated()
    begin
        Rec."Remit. Advice E-Doc. Created" := false;
        Rec.Modify();
    end;

    /// <summary>
    /// Returns whether a remittance advice e-document was created for this Gen. Journal Line.
    /// </summary>
    procedure HasRemitAdviceEDoc(): Boolean
    begin
        exit(Rec."Remit. Advice E-Doc. Created");
    end;
}
