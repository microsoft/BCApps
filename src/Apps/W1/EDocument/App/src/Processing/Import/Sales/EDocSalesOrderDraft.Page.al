// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Sales.Customer;
using System.Utilities;

page 50000 "E-Document Sales Draft"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Document Draft';
    PageType = Card;
    SourceTable = "E-Document Sales Header";
    InsertAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = true;
    Extensible = false;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Customer No."; Rec."[BC] Customer No.")
                {
                    ApplicationArea = Suite;
                    Caption = 'Customer No.';
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the internal customer identifier code.';
                    Editable = PageEditable;
                    Lookup = true;

                    trigger OnValidate()
                    begin
                        Rec.Modify();
                        PrepareDraft();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupCustomer(Text));
                    end;
                }
                field("Buyer Company Name"; Rec."Buyer Company Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Buyer Name';
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the extracted name of the buyer.';
                }
                field(Status; EDocument.Status)
                {
                    Caption = 'Status';
                    Importance = Additional;
                    ToolTip = 'Specifies the status of the e-document.';
                    StyleExpr = StyleStatusTxt;
                    Editable = false;
                }
            }
            group(BuyerGroup)
            {
                Caption = 'Buyer';

                field("Buyer Company Id"; Rec."Buyer Company Id")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the extracted buyer company identifier.';
                }
                field("Buyer VAT Id"; Rec."Buyer VAT Id")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the extracted buyer VAT identifier.';
                }
                field("Buyer GLN"; Rec."Buyer GLN")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the extracted buyer Global Location Number.';
                }
                field("Buyer Address"; Rec."Buyer Address")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Editable = false;
                    ToolTip = 'Specifies the extracted buyer address.';
                }
                field("Buyer Address Recipient"; Rec."Buyer Address Recipient")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Editable = false;
                    ToolTip = 'Specifies the extracted buyer address recipient.';
                }
            }
            group(SellerGroup)
            {
                Caption = 'Seller';

                field("Seller Company Name"; Rec."Seller Company Name")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the extracted seller company name.';
                }
                field("Seller VAT Id"; Rec."Seller VAT Id")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the extracted seller VAT identifier.';
                }
                field("Seller GLN"; Rec."Seller GLN")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the extracted seller Global Location Number.';
                }
                field("Seller Address"; Rec."Seller Address")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Editable = false;
                    ToolTip = 'Specifies the extracted seller address.';
                }
                field("Seller Address Recipient"; Rec."Seller Address Recipient")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Editable = false;
                    ToolTip = 'Specifies the extracted seller address recipient.';
                }
            }
            group(OrderDetails)
            {
                Caption = 'Order Details';

                field("Buyer Order No."; Rec."Buyer Order No.")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the extracted buyer order number.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the extracted document date.';
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the requested delivery date.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the extracted currency code. Blank means local currency.';
                }
                field("Order Type Code"; Rec."Order Type Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Editable = false;
                    ToolTip = 'Specifies the UBL order type code (e.g. 220 = standard order, 221 = blanket order).';
                }
                field("Customer Reference"; Rec."Customer Reference")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Editable = false;
                    ToolTip = 'Specifies the extracted customer reference.';
                }
                field(Note; Rec.Note)
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Editable = false;
                    ToolTip = 'Specifies the extracted note or work description.';
                }
            }
            part(Lines; "E-Doc. Sales Draft Subform")
            {
                ApplicationArea = Suite;
                Editable = PageEditable;
                SubPageLink = "E-Document Entry No." = field("E-Document Entry No.");
                UpdatePropagation = Both;
            }
            group(TotalsGroup)
            {
                Caption = 'Totals';

                field("Sub Total"; Rec."Sub Total")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the extracted subtotal excluding VAT.';
                }
                field("Total Discount"; Rec."Total Discount")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the extracted total discount.';
                }
                field("Total VAT"; Rec."Total VAT")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the extracted total VAT amount.';
                }
                field(Total; Rec.Total)
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the extracted total amount including VAT.';
                }
            }
        }
        area(factboxes)
        {
            part(ErrorMessagesFactBox; "Error Messages Part")
            {
                Visible = HasErrorsOrWarnings;
                ShowFilter = false;
                UpdatePropagation = Both;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(ProcessDocument)
            {
                Caption = 'Process';
                Image = Process;

                action(CreateDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Finalize draft';
                    ToolTip = 'Process the electronic document into a Business Central sales order.';
                    Image = CreateDocument;
                    Visible = ShowFinalizeDraftAction;

                    trigger OnAction()
                    var
                        TempEDocImportParameters: Record "E-Doc. Import Parameters";
                    begin
                        FinalizeEDocument(TempEDocImportParameters);
                    end;
                }
                action(ResetDraftDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reset draft';
                    ToolTip = 'Resets the draft document. Any changes made to the draft document will be lost.';
                    Image = Restore;

                    trigger OnAction()
                    begin
                        ResetDraft();
                    end;
                }
                action(ViewExtractedDocumentData)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View extracted data';
                    ToolTip = 'View the extracted data from the source file.';
                    Image = ViewRegisteredOrder;

                    trigger OnAction()
                    var
                        EDocImport: Codeunit "E-Doc. Import";
                    begin
                        EDocImport.ViewExtractedData(EDocument);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Promoted_CreateDocument; CreateDocument) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadEDocument();
        PageEditable := IsEditable();
        if Rec."E-Document Entry No." <> 0 then
            Rec.SetRecFilter();
    end;

    trigger OnAfterGetRecord()
    begin
        LoadEDocument();
        SetStyle();
        HasErrorsOrWarnings := (EDocumentErrorHelper.ErrorMessageCount(EDocument) + EDocumentErrorHelper.WarningMessageCount(EDocument)) > 0;
        if HasErrorsOrWarnings then
            ShowErrorsAndWarnings()
        else
            ClearErrorsAndWarnings();
        EDocument.CalcFields("Import Processing Status");
        ShowFinalizeDraftAction := EDocument."Import Processing Status" in [Enum::"Import E-Doc. Proc. Status"::"Ready for draft", Enum::"Import E-Doc. Proc. Status"::"Draft Ready"];
        PageEditable := IsEditable();
    end;

    local procedure LoadEDocument()
    begin
        if Rec."E-Document Entry No." <> 0 then
            EDocument.Get(Rec."E-Document Entry No.");
    end;

    local procedure IsEditable(): Boolean
    begin
        exit(EDocument.Status <> EDocument.Status::Processed);
    end;

    local procedure SetStyle()
    begin
        case EDocument.Status of
            EDocument.Status::Error:
                StyleStatusTxt := 'Unfavorable';
            EDocument.Status::Processed:
                StyleStatusTxt := 'Favorable';
            else
                StyleStatusTxt := 'None';
        end;
    end;

    local procedure ShowErrorsAndWarnings()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        CurrPage.ErrorMessagesFactBox.Page.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesFactBox.Page.Update(false);
    end;

    local procedure ClearErrorsAndWarnings()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        CurrPage.ErrorMessagesFactBox.Page.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesFactBox.Page.Update(false);
    end;

    local procedure LookupCustomer(var CustomerNo: Text): Boolean
    var
        Customer: Record Customer;
        CustomerList: Page "Customer List";
    begin
        CustomerList.LookupMode := true;
        if CustomerList.RunModal() = Action::LookupOK then begin
            CustomerList.GetRecord(Customer);
            CustomerNo := Customer."No.";
            exit(true);
        end;
    end;

    local procedure FinalizeEDocument(EDocImportParameters: Record "E-Doc. Import Parameters")
    var
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentHelper: Codeunit "E-Document Helper";
    begin
        if not EDocumentHelper.EnsureInboundEDocumentHasService(EDocument) then
            exit;
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
        EDocument.Get(EDocument."Entry No");
        Rec.Get(Rec."E-Document Entry No.");
        EDocumentErrorHelper.ThrowIfHasErrors(EDocument);
        PageEditable := IsEditable();
        CurrPage.Update();
        if EDocument.Status = EDocument.Status::Processed then
            EDocument.ShowRecord();
    end;

    local procedure ResetDraft()
    var
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentHelper: Codeunit "E-Document Helper";
        ConfirmDialogMgt: Codeunit "Confirm Management";
        Progress: Dialog;
    begin
        if not EDocumentHelper.EnsureInboundEDocumentHasService(EDocument) then
            exit;
        if not ConfirmDialogMgt.GetResponseOrDefault(ResetDraftQst) then
            exit;
        if GuiAllowed() then
            Progress.Open(ProcessingDocumentMsg);
        TempEDocImportParameters."Step to Run" := Enum::"Import E-Document Steps"::"Read into Draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);
        TempEDocImportParameters."Step to Run" := Enum::"Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);
        EDocument.Get(EDocument."Entry No");
        Rec.Get(Rec."E-Document Entry No.");
        if GuiAllowed() then
            Progress.Close();
        EDocumentErrorHelper.ThrowIfHasErrors(EDocument);
    end;

    local procedure PrepareDraft()
    var
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentHelper: Codeunit "E-Document Helper";
        Progress: Dialog;
    begin
        if not EDocumentHelper.EnsureInboundEDocumentHasService(EDocument) then
            exit;
        if GuiAllowed() then
            Progress.Open(ProcessingDocumentMsg);
        TempEDocImportParameters."Step to Run" := Enum::"Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);
        EDocument.Get(EDocument."Entry No");
        Rec.Get(Rec."E-Document Entry No.");
        if GuiAllowed() then
            Progress.Close();
    end;

    var
        EDocument: Record "E-Document";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        StyleStatusTxt: Text;
        HasErrorsOrWarnings: Boolean;
        ShowFinalizeDraftAction: Boolean;
        PageEditable: Boolean;
        ResetDraftQst: Label 'All the changes that you may have made on the document draft will be lost. Do you want to continue?';
        ProcessingDocumentMsg: Label 'Processing document...';
}
