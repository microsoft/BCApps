// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

page 1606 "Office Doc Selection Dlg"
{
    Caption = 'No document found';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            label(Control4)
            {
                ShowCaption = false;
                Caption = '';
            }
            label(DocumentCouldNotBeFound)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'This document could not be found. You may use the links below to browse document lists or search for a specific document.';
                Editable = false;
                HideValue = true;
                ToolTip = 'Specifies whether the document was found.';
            }
            group("Search Sales Documents")
            {
                Caption = 'Search Sales Documents';
                Editable = false;
                field(SalesQuotes; SalesQuotesLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies entered sales quotes.';

                    trigger OnDrillDown()
                    begin
                        OfficeDocumentHandler.ShowDocumentSelection(DummyOfficeDocumentSelection.Series::Sales, DummyOfficeDocumentSelection."Document Type"::Quote.AsInteger());
                    end;
                }
                field(SalesOrders; SalesOrdersLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies entered sales orders.';

                    trigger OnDrillDown()
                    begin
                        OfficeDocumentHandler.ShowDocumentSelection(DummyOfficeDocumentSelection.Series::Sales, DummyOfficeDocumentSelection."Document Type"::Order.AsInteger());
                    end;
                }
                field(SalesInvoices; SalesInvoicesLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies entered sales invoices.';

                    trigger OnDrillDown()
                    begin
                        OfficeDocumentHandler.ShowDocumentSelection(DummyOfficeDocumentSelection.Series::Sales, DummyOfficeDocumentSelection."Document Type"::Invoice.AsInteger());
                    end;
                }
                field(SalesCrMemos; SalesCredMemosLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies entered sales credit memos.';

                    trigger OnDrillDown()
                    begin
                        OfficeDocumentHandler.ShowDocumentSelection(DummyOfficeDocumentSelection.Series::Sales, DummyOfficeDocumentSelection."Document Type"::"Credit Memo".AsInteger());
                    end;
                }
            }
            group("Search Purchasing Documents")
            {
                Caption = 'Search Purchasing Documents';
                field(PurchaseOrders; PurchOrdersLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies entered purchase orders.';

                    trigger OnDrillDown()
                    begin
                        OfficeDocumentHandler.ShowDocumentSelection(DummyOfficeDocumentSelection.Series::Purchase, DummyOfficeDocumentSelection."Document Type"::Order.AsInteger());
                    end;
                }
                field(PurchaseInvoices; PurchInvoicesLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies entered purchase invoices.';

                    trigger OnDrillDown()
                    begin
                        OfficeDocumentHandler.ShowDocumentSelection(DummyOfficeDocumentSelection.Series::Purchase, DummyOfficeDocumentSelection."Document Type"::Invoice.AsInteger());
                    end;
                }
                field(PurchaseCrMemos; PurchCredMemosLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies entered purchase credit memos.';

                    trigger OnDrillDown()
                    begin
                        OfficeDocumentHandler.ShowDocumentSelection(DummyOfficeDocumentSelection.Series::Purchase, DummyOfficeDocumentSelection."Document Type"::"Credit Memo".AsInteger());
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        DummyOfficeDocumentSelection: Record "Office Document Selection";
        SalesOrdersLbl: Label 'Sales Orders';
        SalesQuotesLbl: Label 'Sales Quotes';
        SalesInvoicesLbl: Label 'Sales Invoices';
        SalesCredMemosLbl: Label 'Sales Credit Memos';
        PurchInvoicesLbl: Label 'Purchase Invoices';
        PurchCredMemosLbl: Label 'Purchase Credit Memos';
        OfficeDocumentHandler: Codeunit "Office Document Handler";
        PurchOrdersLbl: Label 'Purchase Orders';
}

