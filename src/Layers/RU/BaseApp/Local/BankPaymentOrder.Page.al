#pragma warning disable AA0247
page 12422 "Bank Payment Order"
{
    AutoSplitKey = true;
    Caption = 'Bank Payment Order';
    DataCaptionExpression = Rec."Document No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group("Payment Order")
            {
                Caption = 'Payment Order';
                group("General Info")
                {
                    Caption = 'General Info';
                    field("Bal. Account No."; Rec."Bal. Account No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                    }
                    field("Posting Date"; Rec."Posting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the entry''s posting date.';
                    }
                    field("Document Type"; Rec."Document Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = DocumentTypeEditable;
                        ToolTip = 'Specifies the type of the related document.';

                        trigger OnValidate()
                        begin
                            if not (Rec."Document Type" in [Rec."Document Type"::Payment, Rec."Document Type"::Refund]) then
                                error(DocumentTypeErr);

                            DocumentTypeOnAfterValidate();
                        end;
                    }
                    field(Prepayment; Rec.Prepayment)
                    {
                        ApplicationArea = Prepayments;
                        ToolTip = 'Specifies if the related payment is a prepayment.';
                    }
                    field("Document No."; Rec."Document No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field("Document Date"; Rec."Document Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the date when the related document was created.';
                    }
                    field("Account Type"; Rec."Account Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the purpose of the account.';

                        trigger OnValidate()
                        begin
                            CalcPayment();
                        end;
                    }
                    field("Account No."; Rec."Account No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the G/L account number.';

                        trigger OnValidate()
                        begin
                            AccountNoOnAfterValidate();
                        end;
                    }
                    field("Beneficiary Bank Code"; Rec."Beneficiary Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the beneficiary bank code associated with the general journal line.';

                        trigger OnValidate()
                        begin
                            BeneficiaryBankCodeOnAfterVali();
                        end;
                    }
                    field("Currency Code"; Rec."Currency Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the currency code for the record.';
                    }
                    field(DebitAmount; Rec."Debit Amount")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount';
                        Editable = true;
                        MinValue = 0;
                        ToolTip = 'Specifies the amount.';

                        trigger OnValidate()
                        begin
                            DebitAmountOnAfterValidate();
                        end;
                    }
                    field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    }
                    field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    }
                    field("Bank Payment Type"; Rec."Bank Payment Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                    }
                    field("Payment Method"; Rec."Payment Method")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies how to make payment, such as with bank transfer, cash , or check.';
                    }
                    field("Payment Type"; Rec."Payment Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the payment type associated with the general journal line.';
                    }
                    field("Payment Assignment"; Rec."Payment Assignment")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the payment assignment associated with the general journal line.';
                    }
                    field("Payment Date"; Rec."Payment Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the payment date associated with the general journal line.';
                    }
                    field("Payment Subsequence"; Rec."Payment Subsequence")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the payment subsequence associated with the general journal line.';
                    }
                    field("Payment Purpose"; Rec."Payment Purpose")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the payment purpose associated with the general journal line.';
                    }
                    field(CheckPrintedText; CheckPrintedText)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Rec.FieldCaption("Check Printed");
                        Editable = false;
                        HideValue = CheckPrintedHideValue;
                        Style = Attention;
                        StyleExpr = true;
                    }
                    field("Payment Code"; Rec."Payment Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the payment code associated with the general journal line.';
                    }
                }
                group(Payer)
                {
                    Caption = 'Payer';
                    field(BankAccNo; BankAccNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Debit Account';
                        Editable = false;
                        ToolTip = 'Specifies the G/L account for debit amounts, for the payment payer.';
                    }
                    field("PayerCode[CodeIndex::INN]"; PayerCode[CodeIndex::INN])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'INN, KPP';
                        Editable = false;
                        ToolTip = 'Specifies the company registration code.';
                    }
                    field("PayerCode[CodeIndex::KPP]"; PayerCode[CodeIndex::KPP])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payer Code';
                        Editable = false;
                        ToolTip = 'Specifies the payer''s code. ';
                    }
                    field("PayerCode[CodeIndex::""Current Account""]"; PayerCode[CodeIndex::"Current Account"])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Current Account';
                        Editable = false;
                        ToolTip = 'Specifies the number of the bank account for current operations.';
                    }
                    field(PayerName; PayerName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payer Name';
                        Editable = false;
                        ToolTip = 'Specifies the payer''s name. ';
                    }
                    field("PayerCode[CodeIndex::BIC]"; PayerCode[CodeIndex::BIC])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payer Bank';
                        Editable = false;
                        ToolTip = 'Specifies the payer''s bank. ';
                    }
                    field("PayerCode[CodeIndex::""Corresp. Account""]"; PayerCode[CodeIndex::"Corresp. Account"])
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(PayerBank);
                        Caption = 'Corresp. Account';
                        Editable = false;
                        ToolTip = 'Specifies the corresponding bank account number. This value is set up on the Bank Account card and used in bank transfers.';
                    }
                }
                group(Beneficiary)
                {
                    Caption = 'Beneficiary';
                    field(CorrAccNo; CorrAccNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Credit Account';
                        Editable = false;
                        ToolTip = 'Specifies the G/L account for credit amounts, for the payment beneficiary.';
                    }
                    field(INN; BenefCode[CodeIndex::INN])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'INN, KPP';
                        Editable = false;
                        ToolTip = 'Specifies the company registration code.';
                    }
                    field("BenefCode[CodeIndex::KPP]"; BenefCode[CodeIndex::KPP])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Beneficiary Code';
                        Editable = false;
                        ToolTip = 'Specifies the code of the payment recipient.';
                    }
                    field("BenefCode[CodeIndex::""Current Account""]"; BenefCode[CodeIndex::"Current Account"])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Current Account';
                        Editable = false;
                        ToolTip = 'Specifies the number of the bank account for current operations.';
                    }
                    field(BenefName; BenefName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Beneficiary Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the payment recipient.';
                    }
                    field("BenefCode[CodeIndex::BIC]"; BenefCode[CodeIndex::BIC])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Beneficiary Bank';
                        Editable = false;
                        ToolTip = 'Specifies the bank of the payment recipient.';
                    }
                    field("BenefCode[CodeIndex::""Corresp. Account""]"; BenefCode[CodeIndex::"Corresp. Account"])
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(BenefBank);
                        Caption = 'Corresp. Account';
                        Editable = false;
                        ToolTip = 'Specifies the corresponding bank account number. This value is set up on the Bank Account card and used in bank transfers.';
                    }
                    field("Agreement No."; Rec."Agreement No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the agreement number associated with the general journal line.';
                    }
                    field("External Document No."; Rec."External Document No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    }
                    field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    }
                    field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    }
                    field("Reason Code"; Rec."Reason Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    }
                    field("Payer Vendor No."; Rec."Payer Vendor No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the payer vendor number associated with the general journal line.';

                        trigger OnValidate()
                        begin
                            PayerVendorNoOnAfterValidate();
                        end;
                    }
                    field("Payer Beneficiary Bank Code"; Rec."Payer Beneficiary Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the payer beneficiary bank code associated with the general journal line.';

                        trigger OnValidate()
                        begin
                            PayerBeneficiaryBankCodeOnAfte();
                        end;
                    }
                    field("Export Status"; Rec."Export Status")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the status of a bank payment order. This value is set automatically.';
                    }
                }
            }
            group("Tax Information")
            {
                Caption = 'Tax Information';
                field("Taxpayer Status"; Rec."Taxpayer Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the taxpayer status associated with the general journal line.';
                }
                field("Payment Reason Code"; Rec."Payment Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment reason code associated with the general journal line.';
                }
                field("Reason Document Type"; Rec."Reason Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason document type associated with the general journal line.';
                }
                field("Reason Document No."; Rec."Reason Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason document number associated with the general journal line.';
                }
                field("Reason Document Date"; Rec."Reason Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason document date associated with the general journal line.';
                }
                field("Period Code"; Rec."Period Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period code associated with the general journal line.';
                }
                field("Tax Period"; Rec."Tax Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax period associated with the general journal line.';
                }
                field("Tax Payment Type"; Rec."Tax Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pay type associated with the general journal line.';
                }
                field(KBK; Rec.KBK)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the KBK code associated with the general journal line.';
                }
                field(OKATO; Rec.OKATO)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the OKATO code associated with the general journal line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Add VAT Info")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Add VAT Info';
                    Image = VATEntries;

                    trigger OnAction()
                    begin
                        Rec.UpdatePaymentVATInfo(true);
                    end;
                }
                action("Copy Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Document';
                    Image = CopyDocument;
                    ToolTip = 'Copy document lines and header information to quickly create a similar document.';

                    trigger OnAction()
                    begin
                        GenJnlLine.Reset();
                        GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        GenJnlLine.SetRange("Line No.", Rec."Line No.");
                        if GenJnlLine.FindFirst() then
                            REPORT.RunModal(REPORT::"Copy Payment Document", true, true, GenJnlLine);
                    end;
                }
                action("Cancel Export")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Export';
                    Image = Cancel;
                    ToolTip = 'Cancel the export.';

                    trigger OnAction()
                    begin
                        Rec.ExportCancel();
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    if (BankAccNo <> '') and (CorrAccNo <> '') then begin
                        GenJnlLine.Reset();
                        GenJnlLine.Copy(Rec);
                        GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        GenJnlLine.SetRange("Line No.", Rec."Line No.");
                        DocumentPrint.PrintCheck(GenJnlLine);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Print_Promoted; Print)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CheckPrintedHideValue := false;
        CalcPayment();
        CheckPrintedText := Format(Rec."Check Printed");
        CheckPrintedTextOnFormat(CheckPrintedText);
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable(Rec."Export Status" <> Rec."Export Status"::"Bank Statement Found");
    end;

    var
        CompanyInformation: Record "Company Information";
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        BankAccPostingGr: Record "Bank Account Posting Group";
        CustPostGroup: Record "Customer Posting Group";
        VendPostGroup: Record "Vendor Posting Group";
        VendorPayer: Record Vendor;
        VendorBankPayer: Record "Vendor Bank Account";
        DocumentPrint: Codeunit "Document-Print";
        StandardReportManagement: Codeunit "Local Report Management";
        AmountDocument: Decimal;
        PayerCode: array[5] of Code[20];
        PayerText: array[6] of Text[100];
        BenefCode: array[5] of Code[30];
        BenefText: array[6] of Text[100];
        CodeIndex: Option ,INN,BIC,"Corresp. Account","Current Account",KPP;
        TextIndex: Option ,Name,Name2,Bank,Bank2,Town;
        BankAccNo: Code[20];
        CorrAccNo: Code[20];
        PayerBank: Text[100];
        PayerName: Text[100];
        BenefBank: Text[100];
        BenefName: Text[100];
#pragma warning disable AA0074
        Text008: Label 'Printed';
#pragma warning restore AA0074
        CheckPrintedHideValue: Boolean;
        CheckPrintedText: Text[1024];
        DocumentTypeEditable: Boolean;
        DocumentTypeErr: Label 'Document Type should be Payment or Refund.';

    local procedure CalcPayment()
    var
        BankAccountDetail: Record "Bank Account Details";
    begin
        CompanyInformation.Get();
        BankAccount.Init();
        BankAccNo := '';
        CorrAccNo := '';
        Clear(PayerCode);
        Clear(PayerText);
        Clear(BenefCode);
        Clear(BenefText);

        Rec.TestField("Bal. Account Type", Rec."Bal. Account Type"::"Bank Account");
        BankAccount.Get(Rec."Bal. Account No.");
        BankAccPostingGr.Get(BankAccount."Bank Acc. Posting Group");
        BankAccPostingGr.TestField("G/L Account No.");
        BankAccNo := BankAccPostingGr."G/L Account No.";

        if Rec."Credit Amount" <> 0 then
            Rec.Validate("Debit Amount", -Rec."Credit Amount");

        CorrAccNo := '';
        DocumentTypeEditable := true;
        if Rec."Account No." <> '' then
            case Rec."Account Type" of
                Rec."Account Type"::Customer:
                    begin
                        CustPostGroup.Get(Rec."Posting Group");
                        if Rec.Prepayment then begin
                            CustPostGroup.TestField("Prepayment Account");
                            CorrAccNo := CustPostGroup."Prepayment Account";
                        end else begin
                            CustPostGroup.TestField("Receivables Account");
                            CorrAccNo := CustPostGroup."Receivables Account";
                        end;
                        DocumentTypeEditable := false;
                    end;
                Rec."Account Type"::Vendor:
                    begin
                        VendPostGroup.Get(Rec."Posting Group");
                        if Rec.Prepayment then begin
                            VendPostGroup.TestField("Prepayment Account");
                            CorrAccNo := VendPostGroup."Prepayment Account";
                        end else begin
                            VendPostGroup.TestField("Payables Account");
                            CorrAccNo := VendPostGroup."Payables Account";
                        end;
                        DocumentTypeEditable := false;
                    end;
                Rec."Account Type"::"Bank Account":
                    begin
                        BankAccount.Get(Rec."Account No.");
                        BankAccPostingGr.Get(BankAccount."Bank Acc. Posting Group");
                        BankAccPostingGr.TestField("G/L Account No.");
                        CorrAccNo := BankAccPostingGr."G/L Account No.";
                        DocumentTypeEditable := false;
                    end;
                Rec."Account Type"::"G/L Account":
                    begin
                        BankAccount.Get(Rec."Bal. Account No.");
                        if BankAccountDetail.Get(Rec."Beneficiary Bank Code") then
                            if BankAccount."Use Client-Bank" then begin
                                CorrAccNo := BankAccountDetail."Transit No.";
                                DocumentTypeEditable := false;
                            end;
                    end;
            end;

        if (BankAccNo <> '') and (CorrAccNo <> '') then
            StandardReportManagement.CheckAttributes(Rec,
              AmountDocument, PayerCode, PayerText, BenefCode, BenefText);

        if (Rec."Payer Vendor No." <> '') and (Rec."Payer Beneficiary Bank Code" <> '') then begin
            VendorPayer.Get(Rec."Payer Vendor No.");
            VendorBankPayer.Get(Rec."Payer Vendor No.", Rec."Payer Beneficiary Bank Code");
            BenefCode[CodeIndex::BIC] := VendorBankPayer.BIC;
            BenefCode[CodeIndex::"Corresp. Account"] := VendorBankPayer."Bank Corresp. Account No.";
            if VendorBankPayer.City <> '' then
                BenefText[TextIndex::Town] := VendorBankPayer."Abbr. City" + '. ' + VendorBankPayer.City;
            BenefText[TextIndex::Bank] := VendorBankPayer.Name;
            BenefText[TextIndex::Bank2] := VendorBankPayer."Name 2";
            BenefCode[CodeIndex::INN] := VendorPayer."VAT Registration No.";
            BenefCode[CodeIndex::"Current Account"] := VendorBankPayer."Bank Account No.";
            BenefText[TextIndex::Name] := VendorPayer.Name;
            BenefText[TextIndex::Name2] := VendorPayer."Name 2";
        end;

        if (Rec."Account Type" = Rec."Account Type"::"G/L Account") and (Rec."Account No." <> '') then begin
            BenefCode[CodeIndex::BIC] := DelChr(BankAccountDetail."Bank BIC", '<>', ' ');
            BenefCode[CodeIndex::"Corresp. Account"] := DelChr(BankAccountDetail."Transit No.", '<>', ' ');
            BenefText[TextIndex::Town] := DelChr(BankAccountDetail."Bank City", '<>', ' ');
            BenefText[TextIndex::Bank] := DelChr(BankAccountDetail."Bank Name", '<>', ' ');
            BenefText[TextIndex::Bank2] := '';
            BenefCode[CodeIndex::INN] := DelChr(BankAccountDetail."VAT Registration No.", '<>', ' ');
            BenefCode[CodeIndex::"Current Account"] := DelChr(BankAccountDetail."Bank Account No.", '<>', ' ');
            BenefText[TextIndex::Name] := BankAccountDetail."G/L Account Name";
            BenefText[TextIndex::Name2] := '';
        end;

        PayerBank :=
          CopyStr(
            DelChr(StrSubstNo('%1 %2', PayerText[TextIndex::Bank], PayerText[TextIndex::Bank2]),
              '<>', ' '), 1, MaxStrLen(PayerBank));
        PayerName :=
          CopyStr(
            DelChr(StrSubstNo('%1 %2', PayerText[TextIndex::Name], PayerText[TextIndex::Name2]),
              '<>', ' '), 1, MaxStrLen(PayerName));
        BenefBank :=
          CopyStr(DelChr(StrSubstNo('%1 %2', BenefText[TextIndex::Bank], BenefText[TextIndex::Bank2]),
              '<>', ' '), 1, MaxStrLen(BenefBank));
        BenefName :=
          CopyStr(DelChr(StrSubstNo('%1 %2', BenefText[TextIndex::Name], BenefText[TextIndex::Name2]),
              '<>', ' '), 1, MaxStrLen(BenefName));
    end;

    local procedure PayerVendorNoOnAfterValidate()
    begin
        CalcPayment();
    end;

    local procedure PayerBeneficiaryBankCodeOnAfte()
    begin
        CalcPayment();
    end;

    local procedure AccountNoOnAfterValidate()
    begin
        CalcPayment();
    end;

    local procedure DocumentTypeOnAfterValidate()
    begin
        CalcPayment();
    end;

    local procedure BeneficiaryBankCodeOnAfterVali()
    begin
        CalcPayment();
    end;

    local procedure DebitAmountOnAfterValidate()
    begin
        CalcPayment();
    end;

    local procedure CheckPrintedTextOnFormat(var Text: Text[1024])
    begin
        if Rec."Check Printed" then
            Text := Text008
        else
            CheckPrintedHideValue := true;
    end;
}

