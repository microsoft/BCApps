// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.Purchases.Vendor;
using System.Utilities;

/// <summary>
/// Page for creating and managing sample purchase invoices.
/// Allows users to create invoice data and generate PDF output.
/// </summary>
page 6117 "Sample Purch. Inv. Card"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;
    Caption = 'Sample Purchase Invoice';
    PageType = Card;
    SourceTable = "Sample Purch. Inv. Header";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the document number.';
                    Editable = false;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ToolTip = 'Specifies the vendor number.';

                    trigger OnValidate()
                    var
                        Vendor: Record Vendor;
                    begin
                        if Vendor.Get(Rec."Buy-from Vendor No.") then begin
                            Rec."Pay-to Vendor No." := Vendor."No.";
                            Rec."Pay-to Name" := Vendor.Name;
                            Rec."Pay-to Address" := Vendor.Address;
                            Rec."Pay-to Address 2" := Vendor."Address 2";
                            Rec."Pay-to City" := Vendor.City;
                            Rec."Pay-to Post Code" := Vendor."Post Code";
                            Rec."Pay-to County" := Vendor.County;
                            Rec."Pay-to Country/Region Code" := Vendor."Country/Region Code";
                            Rec."Pay-to Contact" := Vendor.Contact;
                        end;
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vendor: Record Vendor;
                        VendorList: Page "Vendor List";
                    begin
                        VendorList.LookupMode(true);
                        if VendorList.RunModal() = Action::LookupOK then begin
                            VendorList.GetRecord(Vendor);
                            Rec."Buy-from Vendor No." := Vendor."No.";
                            Rec.Validate("Buy-from Vendor No.");
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ToolTip = 'Specifies the external vendor invoice number.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the posting date of the invoice.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ToolTip = 'Specifies the due date of the invoice.';
                }
            }
            group("Pay-to")
            {
                Caption = 'Pay-to';
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ToolTip = 'Specifies the pay-to vendor number.';
                    Importance = Additional;
                }
                field("Pay-to Name"; Rec."Pay-to Name")
                {
                    ToolTip = 'Specifies the pay-to vendor name.';
                }
                field("Pay-to Address"; Rec."Pay-to Address")
                {
                    ToolTip = 'Specifies the pay-to vendor address.';
                }
                field("Pay-to Address 2"; Rec."Pay-to Address 2")
                {
                    ToolTip = 'Specifies the pay-to vendor address 2.';
                    Importance = Additional;
                }
                field("Pay-to City"; Rec."Pay-to City")
                {
                    ToolTip = 'Specifies the pay-to vendor city.';
                }
                field("Pay-to Post Code"; Rec."Pay-to Post Code")
                {
                    ToolTip = 'Specifies the pay-to vendor post code.';
                }
                field("Pay-to County"; Rec."Pay-to County")
                {
                    ToolTip = 'Specifies the pay-to vendor county.';
                    Importance = Additional;
                }
                field("Pay-to Country/Region Code"; Rec."Pay-to Country/Region Code")
                {
                    ToolTip = 'Specifies the pay-to vendor country/region code.';
                    Importance = Additional;
                }
                field("Pay-to Contact"; Rec."Pay-to Contact")
                {
                    ToolTip = 'Specifies the pay-to vendor contact.';
                    Importance = Additional;
                }
            }
            part(Lines; "Sample Purch. Inv. Subform")
            {
                Caption = 'Lines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(GeneratePDFRef; GeneratePDF)
            {
            }
            actionref(NewInvoiceRef; NewInvoice)
            {
            }
        }
        area(processing)
        {
            action(GeneratePDF)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Generate PDF';
                ToolTip = 'Generates a PDF of the sample invoice and displays it in the browser.';
                Image = Print;

                trigger OnAction()
                begin
                    GenerateAndViewPDF();
                end;
            }
            action(NewInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New Invoice';
                ToolTip = 'Creates a new sample invoice.';
                Image = NewDocument;

                trigger OnAction()
                begin
                    CreateNewInvoice();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            CreateNewInvoice();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        InitializeNewRecord();
    end;

    var
        TempSamplePurchInvLine: Record "Sample Purch. Inv. Line" temporary;
        DocumentCounter: Integer;
        FailedToGeneratePDFErr: Label 'Failed to generate the PDF invoice.';
        InvoiceFileNameTxt: Label 'SampleInvoice_%1.pdf', Comment = '%1 = Invoice No.';

    local procedure CreateNewInvoice()
    begin
        DocumentCounter += 1;
        Rec.Init();
        AssignHeaderData();
        Rec.Insert(true);
        CurrPage.Update(false);
    end;

    local procedure InitializeNewRecord()
    begin
        DocumentCounter += 1;
        AssignHeaderData();
    end;

    local procedure AssignHeaderData()
    begin
        Rec."No." := Format(DocumentCounter);
        Rec."Vendor Invoice No." := 'INV34689';
        Rec."Posting Date" := WorkDate();
        Rec."Due Date" := Rec."Posting Date" + 30;
    end;

    local procedure GenerateAndViewPDF()
    var
        SamplePurchaseInvoice: Report "Sample Purchase Invoice";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        InStream: InStream;
        OutStream: OutStream;
        FileName: Text;
    begin
        Rec.TestField("No.");
        Rec.TestField("Buy-from Vendor No.");

        // Get the lines from the subpage
        CurrPage.Lines.Page.GetRecords(TempSamplePurchInvLine);

        // Set up the report with data
        SamplePurchaseInvoice.SetData(Rec, TempSamplePurchInvLine);

        // Generate PDF using Report.SaveAs
        TempBlob.CreateOutStream(OutStream);
        RecRef.GetTable(Rec);
        if not SamplePurchaseInvoice.SaveAs('', ReportFormat::Pdf, OutStream, RecRef) then
            Error(FailedToGeneratePDFErr);

        // Display the PDF in the browser
        TempBlob.CreateInStream(InStream);
        FileName := StrSubstNo(InvoiceFileNameTxt, Rec."No.");
        File.ViewFromStream(InStream, FileName, true);
    end;
}
