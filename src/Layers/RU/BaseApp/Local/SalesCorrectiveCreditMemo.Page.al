#pragma warning disable AA0247
page 14973 "Sales Corrective Credit Memo"
{
    Caption = 'Sales Corrective Credit Memo';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = filter("Credit Memo"),
                            "Corrective Document" = filter(true));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Sell-to Contact No."; Rec."Sell-to Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the contact person at the customer''s main address.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Sell-to Address"; Rec."Sell-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the main address of the customer.';
                }
                field("Sell-to Address 2"; Rec."Sell-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the address.';
                }
                field("Sell-to Post Code"; Rec."Sell-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sell-to Post Code/City';
                    ToolTip = 'Specifies the post code or city of the address that the customer''s primary address.';
                }
                field("Sell-to City"; Rec."Sell-to City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the customer''s main address.';
                }
                field("Sell-to Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.UpdateForm(true);
                    end;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the campaign the journal line is linked to.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
            }
            part(SalesLines; "Sales Corr. Cr. Memo Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Bill-to Address"; Rec."Bill-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the customer to whom you will send the credit memo.';
                }
                field("Bill-to Address 2"; Rec."Bill-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional line of the address.';
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill-to Post Code/City';
                    ToolTip = 'Specifies the post code or city of the address that the invoice will be sent to.';
                }
                field("Bill-to City"; Rec."Bill-to City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.UpdateForm(true);
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.UpdateForm(true);
                    end;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment discount percent granted if payment is made on or before the date in the Pmt. Discount Date field.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement number associated with the sales header.';
                }
                field(Correction; Rec.Correction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry as a corrective entry. You can use the field if you need to post a corrective entry to an account.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address that the items are shipped to.';
                }
                field("Ship-to Address 2"; Rec."Ship-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to Post Code/City';
                    ToolTip = 'Specifies the post code or city of the address that address that the items are shipped to.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address that the items are shipped to.';
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                }
                field("Consignor No."; Rec."Consignor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the party who consigned the transportation.';
                }
                field("KPP Code"; Rec."KPP Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the company registration associated with the sales header.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ChangeExchangeRate);
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.UpdateForm(true);
                    end;
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Exit Point"; Rec."Exit Point")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the point of exit through which you ship the items out of your country/region, for reporting to Intrastat.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country or region of origin for the purpose of Intrastat reporting.';
                }
            }
            group(Application)
            {
                Caption = 'Application';
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
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
            }
            group(VAT)
            {
                Caption = 'VAT';
                field("Include In Purch. VAT Ledger"; Rec."Include In Purch. VAT Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the sales header is included in the purchase VAT ledger.';
                }
                field("Additional VAT Ledger Sheet"; Rec."Additional VAT Ledger Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional VAT ledger sheet associated with the sales header.';
                }
                field("Corrected Document Date"; Rec."Corrected Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the corrected document associated with the sales header.';
                }
                field("Posting No."; Rec."Posting No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Corrective Document"; Rec."Corrective Document")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document that made the correction.';
                }
                field("Corrective Doc. Type"; Rec."Corrective Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the document that made the correction.';
                }
                field("Corrected Doc. Type"; Rec."Corrected Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the document that was corrected.';
                }
                field("Corrected Doc. No."; Rec."Corrected Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that was corrected.';
                }
                field("Revision No."; Rec."Revision No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a revision number if this document is a revision of a corrective document.';
                }
                field("VAT Entry Type"; Rec."VAT Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT entry code according to Russian legislation. Some types of documents, such as corrective or revision invoices, must have multiple VAT entry type codes.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1903720907; "Sales Hist. Sell-to FactBox")
            {
                SubPageLink = "No." = field("Sell-to Customer No.");
                Visible = false;
            }
            part(Control1907234507; "Sales Hist. Bill-to FactBox")
            {
                SubPageLink = "No." = field("Sell-to Customer No.");
                Visible = false;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("Bill-to Customer No.");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("Sell-to Customer No.");
                Visible = true;
            }
            part(Control1906127307; "Sales Line FactBox")
            {
                Provider = SalesLines;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No.");
                Visible = false;
            }
            part(Control1906354007; "Approval FactBox")
            {
                SubPageLink = "Table ID" = const(36),
                              "Document Type" = field("Document Type"),
                              "Document No." = field("No."),
                              Status = const(Open);
                Visible = false;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                Provider = SalesLines;
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cr. Memo")
            {
                Caption = '&Cr. Memo';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        Rec.CalcInvDiscForHeader();
                        Commit();
                        PAGE.RunModal(PAGE::"Sales Statistics", Rec);
                    end;
                }
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Sell-to Customer No.");
                    ShortCutKey = 'Shift+F7';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("No."),
                                  "Document Line No." = const(0);
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                    end;
                }
                action(Approvals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approvals';
                    Image = Approvals;

                    trigger OnAction()
                    var
                        ApprovalEntries: Page "Approval Entries";
                    begin
                        ApprovalEntries.SetRecordFilters(DATABASE::"Sales Header", Rec."Document Type", Rec."No.");
                        ApprovalEntries.Run();
                    end;
                }
                separator(Action171)
                {
                }
                action("Sig&natures")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sig&natures';
                    Image = Signature;
                    RunObject = Page "Document Signatures";
                    RunPageLink = "Table ID" = const(36),
#pragma warning disable AL0603
                                  "Document Type" = field("Document Type"),
#pragma warning restore
                                  "Document No." = field("No.");
                    ToolTip = 'View signature information for employees and warranty.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Calculate &Invoice Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc();
                    end;
                }
                separator(Action113)
                {
                }
                action("Apply Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    ShortCutKey = 'Shift+F11';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Sales Header Apply", Rec);
                    end;
                }
                separator(Action126)
                {
                }
                action("Get St&d. Cust. Sales Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get St&d. Cust. Sales Codes';
                    Ellipsis = true;
                    Image = CustomerCode;
                    ToolTip = 'View a list of the standard sales lines that have been assigned to the customer to be used for recurring sales.';

                    trigger OnAction()
                    var
                        StdCustSalesCode: Record "Standard Customer Sales Code";
                    begin
                        StdCustSalesCode.InsertSalesLines(Rec);
                    end;
                }
                separator(Action128)
                {
                }
                action("Copy Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Image = CopyDocument;

                    trigger OnAction()
                    begin
                        CopySalesDoc.SetSalesHeader(Rec);
                        CopySalesDoc.RunModal();
                        Clear(CopySalesDoc);
                    end;
                }
                action("Move Negative Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Negative Lines';
                    Ellipsis = true;
                    Image = MoveNegativeLines;
                    ToolTip = 'Prepare to create a replacement sales order in a sales return process.';

                    trigger OnAction()
                    begin
                        Clear(MoveNegSalesLines);
                        MoveNegSalesLines.SetSalesHeader(Rec);
                        MoveNegSalesLines.RunModal();
                        MoveNegSalesLines.ShowDocument();
                    end;
                }
                action("Get Posted Doc&ument Lines to Reverse")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Posted Doc&ument Lines to Reverse';
                    Ellipsis = true;
                    Image = ReverseLines;
                    ToolTip = 'Copy one or more posted sales document lines in order to reverse the original order.';

                    trigger OnAction()
                    begin
                        Rec.GetPstdDocLinesToReverse();
                    end;
                }
                separator(Action141)
                {
                }
                action("Re&lease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualRelease(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualReopen(Rec);
                    end;
                }
                separator("-")
                {
                    Caption = '-';
                }
                action("Get Corr. Doc. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Corr. Doc. Lines';
                    Image = Line;
                    ToolTip = 'Copy one or more posted sales document lines in order to correct the original order.';

                    trigger OnAction()
                    var
                        CorrDocMgt: Codeunit "Corrective Document Mgt.";
                    begin
                        CorrDocMgt.SetSalesHeader(Rec."Document Type".AsInteger(), Rec."No.");
                        CorrDocMgt.SelectPstdSalesDocLines();
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                action("Send A&pproval Request")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = not OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval of the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckSalesApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendSalesDocForApproval(Rec);
                    end;
                }
                action("Cancel Approval Re&quest")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist;
                    Image = Cancel;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelSalesApprovalRequest(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintSalesHeader(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                            CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                            CODEUNIT.Run(CODEUNIT::"Sales-Post + Print", Rec);
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Sales Credit Memos", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;

                trigger OnAction()
                begin
                    DocPrint.PrintSalesHeader(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
                actionref("Apply Entries_Promoted"; "Apply Entries")
                {
                }
                actionref("Copy Document_Promoted"; "Copy Document")
                {
                }
                actionref("Re&lease_Promoted"; "Re&lease")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Category6)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Category7)
            {
                Caption = 'Prepare', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Category8)
            {
                Caption = 'Invoice', Comment = 'Generated from the PromotedActionCategories property index 7.';
            }
            group(Category_Category9)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 8.';

                actionref("Send A&pproval Request_Promoted"; "Send A&pproval Request")
                {
                }
                actionref("Cancel Approval Re&quest_Promoted"; "Cancel Approval Re&quest")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetControlAppearance();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Responsibility Center" := UserMgt.GetSalesFilter();
        Rec."Corrective Document" := true;
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetSalesFilter() <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Responsibility Center", UserMgt.GetSalesFilter());
            Rec.FilterGroup(0);
        end;
    end;

    var
        CopySalesDoc: Report "Copy Sales Document";
        MoveNegSalesLines: Report "Move Negative Sales Lines";
        ReportPrint: Codeunit "Test Report-Print";
        UserMgt: Codeunit "User Setup Management";
        DocPrint: Codeunit "Document-Print";
        ChangeExchangeRate: Page "Change Exchange Rate";
        OpenApprovalEntriesExist: Boolean;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.SalesLines.PAGE.ApproveCalcInvDisc();
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
    end;
}

