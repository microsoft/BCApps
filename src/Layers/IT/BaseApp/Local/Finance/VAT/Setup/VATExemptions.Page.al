// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;

page 12100 "VAT Exemptions"
{
    Caption = 'VAT Exemptions';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "VAT Exemption";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("VAT Exempt. Starting Date"; Rec."VAT Exempt. Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the start date for the VAT exemption is valid.';
                }
                field("VAT Exempt. Ending Date"; Rec."VAT Exempt. Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the end date for the VAT exemption is valid.';
                }
                field("VAT Exempt. No."; Rec."VAT Exempt. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identification number of the VAT exemption.';
                    Visible = VATExemptNoVisible;
                }
                field("Consecutive VAT Exempt. No."; Rec."Consecutive VAT Exempt. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the consecutive number of the VAT exemption.';
                    Visible = VATExemptNoVisible;
                }
                field("VAT Exempt. Date"; Rec."VAT Exempt. Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the effective date of the VAT exemption.';
                    Visible = VATExemptDateVisible;
                }
                field("VAT Exempt. Int. Registry No."; Rec."VAT Exempt. Int. Registry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registry number of the VAT exemption.';

                    trigger OnAssistEdit()
                    var
                        NoSeries: Codeunit "No. Series";
                    begin
                        NoSeries.LookupRelatedNoSeries(GetVATExemptionNos(), Rec."No. Series");
                        Rec."VAT Exempt. Int. Registry No." := NoSeries.GetNextNo(Rec."No. Series");
                    end;
                }
                field("VAT Exempt. Int. Registry Date"; Rec."VAT Exempt. Int. Registry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registry date of the VAT exemption.';
                }
                field("VAT Exempt. Office"; Rec."VAT Exempt. Office")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the office that the VAT exemption applies to.';
                }
                field("Declared Operations Up To Amt."; Rec."Declared Operations Up To Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount which has been declared through a declaration of intent.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Export Decl. of Intent")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Decl. of Intent';
                Image = ExportElectronicDocument;
                ToolTip = 'Export the declaration of intent.';

                trigger OnAction()
                var
                    DeclarationOfIntentExport: Page "Declaration of Intent Export";
                begin
                    Rec.TestField(Type, Rec.Type::Vendor);
                    DeclarationOfIntentExport.Initialize(Rec);
                    DeclarationOfIntentExport.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Export Decl. of Intent_Promoted"; "Export Decl. of Intent")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        VATExemptDateVisible := true;
        VATExemptNoVisible := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateForm();
    end;

    var
        VATExemptNoVisible: Boolean;
        VATExemptDateVisible: Boolean;

    local procedure GetVATExemptionNos(): Code[20]
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Code[20];
    begin
        if Rec.GetFilter(Type) = Format(Rec.Type::Customer) then begin
            SalesSetup.Get();
            SalesSetup.TestField("VAT Exemption Nos.");
            NoSeries := SalesSetup."VAT Exemption Nos.";
        end else begin // Vendor
            PurchasesSetup.Get();
            PurchasesSetup.TestField("VAT Exemption Nos.");
            NoSeries := PurchasesSetup."VAT Exemption Nos.";
        end;

        exit(NoSeries);
    end;

    [Scope('OnPrem')]
    procedure UpdateForm()
    begin
        if Rec.GetFilter(Type) <> '' then begin
            VATExemptNoVisible := Rec.GetRangeMin(Rec.Type) <> Rec.Type::Vendor;
            VATExemptDateVisible := Rec.GetRangeMin(Rec.Type) <> Rec.Type::Vendor;
        end;
    end;
}