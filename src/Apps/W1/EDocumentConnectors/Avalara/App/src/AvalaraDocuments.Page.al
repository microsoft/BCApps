namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;

page 6379 "Avalara Documents"
{
    ApplicationArea = All;
    Caption = 'Avalara Documents';
    PageType = List;
    SourceTable = "Avalara Document Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(CompanyDetails)
            {
                Caption = 'Company Details';
                field("Avalara Company"; CompanyID)
                {
                    ApplicationArea = All;
                    Caption = 'Avalara Company';
                    Editable = false;
                    ToolTip = 'Specifies the Avalara company ID configured in connection setup';
                }
            }

            repeater(Group)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the document in Avalara';
                }
                field("Document Number"; Rec."Document Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of document (e.g., Invoice, Credit Memo)';
                }
                field("Document Version"; Rec."Document Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the version of the document';
                }
                field(Flow; Rec.Flow)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the flow direction (inbound/outbound)';
                }
                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country code for the document';
                }
                field("Country Mandate"; Rec."Country Mandate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country mandate (e.g., AU-B2B-PEPPOL)';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document date';
                }
                field("Process DateTime"; Rec."Process DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the document was processed';
                }
                field("Supplier Name"; Rec."Supplier Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the supplier';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the customer';
                }
                field(Receiver; Rec.Receiver)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the receiver of the document';
                }
                field("Interface"; Rec."Interface")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the interface used for the document';
                }
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                    Caption = 'Document ID';
                    ToolTip = 'Specifies the unique Avalara document ID';
                }
                field("Company Id"; Rec."Company Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Avalara company ID for the document';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshDocuments)
            {
                ApplicationArea = All;
                Caption = 'Refresh Documents';
                Image = Refresh;
                ToolTip = 'Refresh the list of documents from Avalara API';

                trigger OnAction()
                var
                    AvalaraDocumentManagement: Codeunit "Avalara Document Management";
                begin
                    AvalaraDocumentManagement.LoadDocumentList(Rec);
                    CurrPage.Update(false);
                    Message('%1 documents loaded', Rec.Count);
                end;
            }

            action(DownloadAsXML)
            {
                ApplicationArea = All;
                Caption = 'Download as XML';
                Enabled = Rec.Id <> '';
                Image = XMLFile;
                ToolTip = 'Download the selected document as XML format';

                trigger OnAction()
                begin
                    DownloadSelectedDocument('application/xml');
                end;
            }

            action(DownloadAsPDF)
            {
                ApplicationArea = All;
                Caption = 'Download as PDF';
                Enabled = Rec.Id <> '';
                Image = SendAsPDF;
                ToolTip = 'Download the selected document as PDF format';

                trigger OnAction()
                begin
                    DownloadSelectedDocument('application/pdf');
                end;
            }

            action(DownloadAsUBL)
            {
                ApplicationArea = All;
                Caption = 'Download as UBL';
                Enabled = Rec.Id <> '';
                Image = XMLFile;
                ToolTip = 'Download the selected document as UBL XML format';

                trigger OnAction()
                begin
                    DownloadSelectedDocument('application/vnd.oasis.ubl+xml');
                end;
            }
        }
    }

    var
        CompanyID: Text;

    trigger OnOpenPage()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        if ConnectionSetup.Get() then
            CompanyID := ConnectionSetup."Company Id";

        // Don't auto-load documents on page open for better performance
        // User should click "Refresh Documents" action when ready
        Rec.SetCurrentKey("Process DateTime");
        Rec.SetAscending("Process DateTime", false);
    end;

    local procedure DownloadSelectedDocument(MediaType: Text)
    var
        EDocument: Record "E-Document";
        AvalaraDocumentManagement: Codeunit "Avalara Document Management";
    begin
        if Rec.Id = '' then begin
            Message('Please select a document to download');
            exit;
        end;

        EDocument.Init();

        if AvalaraDocumentManagement.DownloadDocument(EDocument, Rec.Id, MediaType) then
            Message('Document %1 downloaded successfully as %2', Rec."Document Number", MediaType)
        else
            Error('Failed to download document %1', Rec."Document Number");

        CurrPage.Update(false);
    end;
}
