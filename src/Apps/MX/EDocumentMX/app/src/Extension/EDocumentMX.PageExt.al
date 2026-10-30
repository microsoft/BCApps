// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;

pageextension 3364 "EDoc CFDI E-Document Ext" extends "E-Document"
{
    layout
    {
        addlast(ClearanceInfo)
        {
            field(FiscalInvoiceNumberPAC; FiscalInvoiceNumberPAC)
            {
                ApplicationArea = All;
                Caption = 'Fiscal Invoice Number PAC';
                Editable = false;
                ToolTip = 'Specifies the UUID assigned by SAT when the CFDI document was stamped (cleared).';
            }
        }
        addafter(ClearanceInfo)
        {
            group(CFDIData)
            {
                Caption = 'CFDI';
                Visible = CFDIDataVisible;

                group(CFDIGeneral)
                {
                    ShowCaption = false;

                    field("CFDI Export Code"; Rec."CFDI Export Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the SAT export code (Exportacion) sent in the CFDI.';
                    }
                    field("CFDI Exchange Rate USD"; Rec."CFDI Exchange Rate USD")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the USD exchange rate (TipoCambioUSD) sent in the foreign trade complement.';
                    }
                    field("CFDI Foreign Trade"; Rec."CFDI Foreign Trade")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies whether the CFDI includes the foreign trade complement (Comercio Exterior).';
                    }
                    field("CFDI SAT Address ID"; Rec."CFDI SAT Address ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the SAT address of the receiver used in the foreign trade complement.';
                    }
                    field("CFDI Intl. Trade Term"; Rec."CFDI Intl. Trade Term")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the international trade term (Incoterm) sent in the foreign trade complement.';
                    }
                    field("CFDI Cert. of Origin No."; Rec."CFDI Cert. of Origin No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the certificate of origin number (NumCertificadoOrigen) sent in the foreign trade complement.';
                    }
                }
                group(CFDICartaPorte)
                {
                    ShowCaption = false;
                    Visible = CartaPorteVisible;

                    field("CFDI Transport Type"; Rec."CFDI Transport Type")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the mode of transport for the Carta Porte complement (ViaEntradaSalida). Defaults to 01 if left blank.';
                    }
                    field(TransportOperators; TransportOperatorCount)
                    {
                        ApplicationArea = All;
                        Caption = 'Transport Operators';
                        Editable = false;
                        ToolTip = 'Specifies the operators of the vehicle that transports the goods.';

                        trigger OnDrillDown()
                        var
                            EDocCFDIDataMX: Codeunit "EDoc CFDI Data MX";
                        begin
                            EDocCFDIDataMX.OpenTransportOperators(Rec);
                            TransportOperatorCount := EDocCFDIDataMX.CountTransportOperators(Rec);
                        end;
                    }
                    field("CFDI Transit-from Date/Time"; Rec."CFDI Transit-from Date/Time")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies when the goods leave the origin location.';
                    }
                    field("CFDI Transit Hours"; Rec."CFDI Transit Hours")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the estimated transit time in hours.';
                    }
                    field("CFDI Transit Distance"; Rec."CFDI Transit Distance")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the distance traveled in kilometers.';
                    }
                    field("CFDI Vehicle Code"; Rec."CFDI Vehicle Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the vehicle that transports the goods.';
                    }
                    field("CFDI Trailer 1"; Rec."CFDI Trailer 1")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the first trailer used to transport the goods.';
                    }
                    field("CFDI Trailer 2"; Rec."CFDI Trailer 2")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the second trailer used to transport the goods.';
                    }
                    field("CFDI Customs Regime"; Rec."CFDI Customs Regime")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the SAT customs regime (RegimenAduanero) for foreign trade shipments.';
                    }
                    field("CFDI Transfer Reason"; Rec."CFDI Transfer Reason")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the SAT transfer reason (MotivoTraslado) for foreign trade shipments.';
                    }
                    field("CFDI SAT ISTMO"; Rec."CFDI SAT ISTMO")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies whether the shipment is within the Istmo de Tehuantepec development zone (RegistroISTMO).';
                    }
                    field("CFDI ISTMO Polo Origen"; Rec."CFDI ISTMO Polo Origen")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the origin pole within the Istmo de Tehuantepec development zone (UbicacionPoloOrigen).';
                    }
                    field("CFDI ISTMO Polo Destino"; Rec."CFDI ISTMO Polo Destino")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the destination pole within the Istmo de Tehuantepec development zone (UbicacionPoloDestino).';
                    }
                    field("CFDI Insurer Name"; Rec."CFDI Insurer Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the insurer that covers the civil liability of the vehicle.';
                    }
                    field("CFDI Insurer Policy Number"; Rec."CFDI Insurer Policy Number")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the civil liability insurance policy number.';
                    }
                    field("CFDI Medical Insurer Name"; Rec."CFDI Medical Insurer Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the insurer that covers environmental damage for hazardous materials.';
                    }
                    field("CFDI Medical Ins. Policy No."; Rec."CFDI Medical Ins. Policy No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the environmental damage insurance policy number.';
                    }
                    field("CFDI Weight Unit Of Measure"; Rec."CFDI Weight Unit Of Measure")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the SAT unit of measure for the gross weight (UnidadPeso).';
                    }
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(EditCFDIData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit CFDI Data';
                ToolTip = 'Edit the CFDI values sent to the PAC. Available until the document is stamped. After editing, recreate and send the e-document.';
                Image = Edit;
                Visible = CFDIDataVisible;
                Enabled = CFDIDataEditable;

                trigger OnAction()
                var
                    EDocument: Record "E-Document";
                begin
                    EDocument.Get(Rec."Entry No");
                    EDocument.SetRecFilter();
                    Page.RunModal(Page::"E-Doc. CFDI Data MX", EDocument);
                    CurrPage.Update(false);
                end;
            }
            action(ViewPaymentOccurrences)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Complement Occurrences';
                ToolTip = 'Shows the CFDI payment complement occurrences linked to this e-document.';
                Image = Payment;
                Visible = IsCFDIDocument;
                RunObject = page "E-Doc. Payment Occurrences MX";
                RunPageLink = "E-Document Entry No." = field("Entry No");
            }
            action(PrintCFDI)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print CFDI';
                ToolTip = 'Prints the CFDI electronic document as a PDF.';
                Image = Print;
                Visible = IsCFDIDocument;

                trigger OnAction()
                var
                    EDocCFDIPrintMX: Codeunit "EDoc CFDI Print MX";
                begin
                    EDocCFDIPrintMX.PrintCFDI(Rec);
                end;
            }
            action(MarkAsCanceled)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark as Canceled';
                ToolTip = 'Manually marks this CFDI document as canceled in Business Central without contacting the PAC. Use this when the document is already canceled in SAT but the status has not been updated here.';
                Image = Cancel;
                Visible = IsCFDIDocument;

                trigger OnAction()
                var
                    EDocumentService: Record "E-Document Service";
                    EDocumentServiceStatus: Record "E-Document Service Status";
                    EDocumentProcessing: Codeunit "E-Document Processing";
                    EDocumentServices: Page "E-Document Services";
                begin
                    if not Confirm(MarkAsCanceledConfirmQst, false) then
                        exit;

                    EDocumentService.SetFilter(Code, GetLinkedCFDIServiceFilter());
                    case EDocumentService.Count() of
                        0:
                            Error(NoLinkedServiceErr);
                        1:
                            EDocumentService.FindFirst();
                        else begin
                            EDocumentServices.SetTableView(EDocumentService);
                            EDocumentServices.LookupMode := true;
                            if EDocumentServices.RunModal() <> Action::LookupOK then
                                exit;
                            EDocumentServices.GetRecord(EDocumentService);
                        end;
                    end;

                    EDocumentServiceStatus.Get(Rec."Entry No", EDocumentService.Code);
                    if not (EDocumentServiceStatus.Status in [
                        Enum::"E-Document Service Status"::Sent,
                        Enum::"E-Document Service Status"::"Pending Response",
                        Enum::"E-Document Service Status"::"Cancel Error"])
                    then
                        Error(InvalidStatusForMarkAsCanceledErr, EDocumentServiceStatus.Status);

                    EDocumentProcessing.ModifyServiceStatus(Rec, EDocumentService, Enum::"E-Document Service Status"::Canceled);
                    EDocumentProcessing.ModifyEDocumentStatus(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
        EDocCFDIDataMX: Codeunit "EDoc CFDI Data MX";
    begin
        if Rec.Direction = Rec.Direction::Outgoing then
            FiscalInvoiceNumberPAC := CopyStr(CFDIWriteBackMX.GetUUIDForDocument(Rec."Document Record ID"), 1, MaxStrLen(FiscalInvoiceNumberPAC))
        else
            FiscalInvoiceNumberPAC := CopyStr(Rec."Source Details", 1, MaxStrLen(FiscalInvoiceNumberPAC));

        IsCFDIDocument := (Rec.Direction = Rec.Direction::Outgoing) and (GetLinkedCFDIServiceFilter() <> '''''');
        CFDIDataVisible := IsCFDIDocument and EDocCFDIDataMX.IsSupportedSource(Rec);
        CFDIDataEditable := CFDIDataVisible and (FiscalInvoiceNumberPAC = '');
        CartaPorteVisible := CFDIDataVisible and EDocCFDIDataMX.IsCartaPorte(Rec);
        TransportOperatorCount := 0;
        if CartaPorteVisible then
            TransportOperatorCount := EDocCFDIDataMX.CountTransportOperators(Rec);
    end;

    local procedure GetLinkedCFDIServiceFilter() ServiceFilter: Text
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.SetRange("E-Document Entry No", Rec."Entry No");
        if EDocumentServiceStatus.FindSet() then
            repeat
                if EDocumentService.Get(EDocumentServiceStatus."E-Document Service Code") then
                    if EDocumentService."Document Format" = EDocumentService."Document Format"::CFDI then begin
                        if ServiceFilter <> '' then
                            ServiceFilter += '|';
                        ServiceFilter += '''' + EDocumentServiceStatus."E-Document Service Code" + '''';
                    end;
            until EDocumentServiceStatus.Next() = 0;
        if ServiceFilter = '' then
            ServiceFilter := '''''';
    end;

    var
        FiscalInvoiceNumberPAC: Text[50];
        TransportOperatorCount: Integer;
        IsCFDIDocument: Boolean;
        CFDIDataVisible: Boolean;
        CFDIDataEditable: Boolean;
        CartaPorteVisible: Boolean;
        MarkAsCanceledConfirmQst: Label 'This will mark the document as Canceled in Business Central without contacting the PAC. Only use this if you have confirmed the document is already canceled in SAT. Do you want to continue?';
        NoLinkedServiceErr: Label 'No E-Document service is linked to this document.';
        InvalidStatusForMarkAsCanceledErr: Label 'The document cannot be marked as canceled because it has status %1. Only documents with status Sent, Pending Response, or Cancel Error can be manually marked as canceled.', Comment = '%1 = current service status';
}
