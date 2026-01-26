// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Vendor;

page 12188 "Manual vendor Payment Line"
{
    Caption = 'Create Manual Bill Vendor Line';
    PageType = Card;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendorNo; VendorNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Code';
                    NotBlank = true;
                    TableRelation = Vendor;
                    ToolTip = 'Specifies the vendor code.';

                    trigger OnValidate()
                    var
                        Vend: Record Vendor;
                    begin
                        if Vend.Get(VendorNo) then begin
                            VendorName := Vend.Name;
                            WithholdingTaxCode := Vend."Withholding Tax Code";
                            SocialSecurityCode := Vend."Social Security Code";
                        end
                    end;
                }
                field(VendorName; VendorName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies the vendor name.';
                }
                field(WithholdingTaxCode; WithholdingTaxCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Withholding Tax Code';
                    TableRelation = "Withhold Code";
                    ToolTip = 'Specifies the withholding tax code.';
                }
                field(SocialSecurityCode; SocialSecurityCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Social Security Code';
                    TableRelation = "Contribution Code";
                    ToolTip = 'Specifies the social security code.';
                }
                field(Desc; Desc)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the payment.';
                }
                field(ExternalDocNo; ExternalDocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Doc. No.';
                    ToolTip = 'Specifies the external document number.';
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies the total amount.';

                    trigger OnValidate()
                    begin
                        TaxBaseAmount := TotalAmount;
                    end;
                }
                field(TaxBaseAmount; TaxBaseAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Base Amount';
                    ToolTip = 'Specifies the tax base amount.';
                }
                field(DocumentType; DocumentType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the document type.';
                }
                field(DocumentNo; DocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number.';
                }
                field(DocumentDate; DocumentDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Date';
                    ToolTip = 'Specifies the document date.';
                }
                field(VendorBankAccount; VendorBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Bank Account';
                    ToolTip = 'Specifies the vendor bank account.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VendBankAcc: Record "Vendor Bank Account";
                    begin
                        VendBankAcc.Reset();
                        VendBankAcc.SetRange("Vendor No.", VendorNo);
                        if PAGE.RunModal(PAGE::"Vendor Bank Account List", VendBankAcc, VendBankAcc.Code) = ACTION::LookupOK then
                            VendorBankAccount := VendBankAcc.Code;
                    end;

                    trigger OnValidate()
                    var
                        VendBankAcc: Record "Vendor Bank Account";
                    begin
                        if VendorBankAccount <> '' then
                            VendBankAcc.Get(VendorNo, VendorBankAccount);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(InsertLine)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Insert Line';
                Image = Line;
                ToolTip = 'Add a line.';

                trigger OnAction()
                var
                    VendorBillLine: Record "Vendor Bill Line";
                    DimMgt: Codeunit DimensionManagement;
                    DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
                    Dimension: Code[20];
                    NextLineNo: Integer;
                begin
                    VendorBillLine.LockTable();
                    VendorBillLine.Reset();
                    VendorBillLine.SetRange("Vendor Bill List No.", VendorBillNo);
                    if not VendorBillLine.FindLast() then
                        NextLineNo := 10000
                    else
                        NextLineNo := VendorBillLine."Line No." + 10000;
                    VendorBillLine.Init();
                    VendorBillLine."Vendor Bill List No." := VendorBillNo;
                    VendorBillLine."Line No." := NextLineNo;
                    if VendorNo <> '' then
                        VendorBillLine."Vendor No." := VendorNo
                    else
                        Error(Text12100);
                    VendorBillLine."Vendor Bank Acc. No." := VendorBankAccount;
                    VendorBillLine."Document Type" := DocumentType;
                    VendorBillLine."Document No." := DocumentNo;
                    VendorBillLine.Description := Desc;
                    VendorBillLine."Document Date" := DocumentDate;
                    VendorBillLine."Due Date" := PostingDate;
                    VendorBillLine."External Document No." := ExternalDocNo;
                    VendorBillLine."Instalment Amount" := TotalAmount;
                    VendorBillLine."Remaining Amount" := TotalAmount;
                    VendorBillLine."Gross Amount to Pay" := TotalAmount;
                    VendorBillLine."Amount to Pay" := TaxBaseAmount;
                    VendorBillLine."Manual Line" := true;
                    VendorBillLine."Cumulative Transfers" := true;
                    VendorBillLine.SetWithholdCode(WithholdingTaxCode);
                    VendorBillLine.SetSocialSecurityCode(SocialSecurityCode);
                    DimMgt.AddDimSource(DefaultDimSource, Database::Vendor, VendorNo);
                    VendorBillLine."Dimension Set ID" :=
                        DimMgt.GetRecDefaultDimID(
                            VendorBillLine, 0, DefaultDimSource, '', Dimension, Dimension, VendorBillLine."Dimension Set ID", DATABASE::Vendor);
                    OnInsertLineActionOnBeforeVendorBillLineInsert(VendorBillLine, VendorBillNo, PostingDate, VendorNo, TotalAmount, DocumentType, DocumentNo, DocumentDate);
                    VendorBillLine.Insert(true);
                    ClearAll();
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(InsertLine_Promoted; InsertLine)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        DocumentType := DocumentType::Invoice;
    end;

    var
        VendorNo: Code[20];
        VendorBillNo: Code[20];
        DocumentNo: Code[20];
        WithholdingTaxCode: Code[20];
        VendorBankAccount: Code[20];
        ExternalDocNo: Code[20];
        SocialSecurityCode: Code[20];
        VendorName: Text[100];
        Desc: Text[30];
        DocumentType: Enum "Gen. Journal Document Type";
        DocumentDate: Date;
        PostingDate: Date;
        TotalAmount: Decimal;
        Text12100: Label 'Please enter the vendor code.';
        TaxBaseAmount: Decimal;

    [Scope('OnPrem')]
    procedure SetVendBillNoAndDueDate(VendBillNo: Code[20]; Date: Date)
    begin
        VendorBillNo := VendBillNo;
        PostingDate := Date;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLineActionOnBeforeVendorBillLineInsert(var VendorBillLine: Record "Vendor Bill Line"; VendorBillNo: Code[20]; PostingDate: Date; VendorNo: Code[20]; TotalAmount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentDate: Date)
    begin
    end;
}

