codeunit 163551 "Create AdvLetter Template CZZ"
{

    trigger OnRun()
    begin
        InsertData("Advance Letter Type CZZ"::Purchase, 'XDOMESTIC', XDomesticPurchaseAdvances, MakeAdjustments.Convert('992410'), true);
        InsertData("Advance Letter Type CZZ"::Purchase, 'XFOREIGN', XForeignPurchaseAdvances, MakeAdjustments.Convert('992420'), true);
        InsertData("Advance Letter Type CZZ"::Purchase, 'XEU', XEUPurchaseAdvances, MakeAdjustments.Convert('992430'), true);
        InsertData("Advance Letter Type CZZ"::Sales, 'XDOMESTIC', XDomesticSalesAdvances, MakeAdjustments.Convert('995360'), true);
        InsertData("Advance Letter Type CZZ"::Sales, 'XFOREIGN', XForeignSalesAdvances, MakeAdjustments.Convert('995370'), true);
        InsertData("Advance Letter Type CZZ"::Sales, 'XEU', XEUSalesAdvances, MakeAdjustments.Convert('995380'), true);
    end;

    var
        AdvanceLetterTemplateCZZ: Record "Advance Letter Template CZZ";
        MakeAdjustments: Codeunit "Make Adjustments";
        CreateNoSeries: Codeunit "Create No. Series";
        XPurchAdvanceVatInvoice: Label 'Purchase Advance - VAT Invoice';
        XPurchAdvanceVatCrMemo: Label 'Purchase Advance - VAT Credit Memo';
        XDomesticPurchaseAdvances: Label 'Domestic Purchase Advances';
        XForeignPurchaseAdvances: Label 'Foreign Purchase Advances';
        XEUPurchaseAdvances: Label 'EU Purchase Advances';
        XSalesAdvanceVatInvoice: Label 'Sales Advance - VAT Invoice';
        XSalesAdvanceVatCrMemo: Label 'Sales Advance - VAT Credit Memo';
        XDomesticSalesAdvances: Label 'Domestic Sales Advances';
        XForeignSalesAdvances: Label 'Foreign Sales Advances';
        XEUSalesAdvances: Label 'EU Sales Advances';

    procedure InsertData(SalesPurchase: Enum "Advance Letter Type CZZ"; AdvanceLetterTemplateCode: Text; Description: Text[100]; AdvanceLetterGLAccount: Code[20]; AutomaticPostVATDocument: Boolean)
    begin
        AdvanceLetterTemplateCZZ.Init();
        AdvanceLetterTemplateCZZ.Code := GetAdvanceLetterTemplateCode(SalesPurchase, AdvanceLetterTemplateCode);
        AdvanceLetterTemplateCZZ."Sales/Purchase" := SalesPurchase;
        AdvanceLetterTemplateCZZ.Description := Description;
        AdvanceLetterTemplateCZZ."Advance Letter G/L Account" := AdvanceLetterGLAccount;
        AdvanceLetterTemplateCZZ."Automatic Post VAT Document" := AutomaticPostVATDocument;

        case SalesPurchase of
            SalesPurchase::Purchase:
                begin
                    case AdvanceLetterTemplateCode of
                        'XDOMESTIC':
                            InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Document Nos.", 'N-ZALD', XDomesticPurchaseAdvances, 'NZ01220001');
                        'XFOREIGN':
                            InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Document Nos.", 'N-ZALC', XForeignPurchaseAdvances, 'NZ03220001');
                        'XEU':
                            InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Document Nos.", 'N-ZALE', XEUPurchaseAdvances, 'NZ02220001');
                    end;
                    InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Invoice Nos.", 'N-ZDFA', XPurchAdvanceVatInvoice, 'NZDF220001');
                    InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Cr. Memo Nos.", 'N-ZDDO', XPurchAdvanceVatCrMemo, 'NZDD220001');
                end;
            SalesPurchase::Sales:
                begin
                    case AdvanceLetterTemplateCode of
                        'XDOMESTIC':
                            InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Document Nos.", 'P-ZALD', XDomesticSalesAdvances, 'PZ01220001');
                        'XFOREIGN':
                            InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Document Nos.", 'P-ZALC', XForeignSalesAdvances, 'PZ03220001');
                        'XEU':
                            InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Document Nos.", 'P-ZALE', XEUSalesAdvances, 'PZ02220001');
                    end;
                    InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Invoice Nos.", 'P-ZDFA', XSalesAdvanceVatInvoice, 'PZDF220001');
                    InitBaseSeries(AdvanceLetterTemplateCZZ."Advance Letter Cr. Memo Nos.", 'P-ZDDO', XSalesAdvanceVatCrMemo, 'PZDD220001');
                end;
        end;

        AdvanceLetterTemplateCZZ.Insert();
    end;

    local procedure InitBaseSeries(var SeriesCode: Code[20]; Code: Code[20]; Description: Text[100]; StartingNo: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(Code) then begin
            SeriesCode := Code;
            exit;
        end;

        CreateNoSeries.InitBaseSeries2(SeriesCode, Code, Description, StartingNo, '', '', '', 1);
    end;

    procedure GetAdvanceLetterTemplateCode(SalesPurchase: Enum "Advance Letter Type CZZ"; AdvanceLetterTemplateCode: Text): Code[20]
    var
        XDOMESTIC: Label 'DOMESTIC';
        XFOREIGN: Label 'FOREIGN';
        XEU: Label 'EU';
    begin
        case SalesPurchase of
            SalesPurchase::Purchase:
                case UpperCase(AdvanceLetterTemplateCode) of
                    'XDOMESTIC':
                        exit('N_' + XDOMESTIC);
                    'XFOREIGN':
                        exit('N_' + XFOREIGN);
                    'XEU':
                        exit('N_' + XEU);
                    else
                        Error('Unknown Purchase Advance Letter Template Code %1',AdvanceLetterTemplateCode);
                end;
            SalesPurchase::Sales:
                case UpperCase(AdvanceLetterTemplateCode) of
                    'XDOMESTIC':
                        exit('P_' + XDOMESTIC);
                    'XFOREIGN':
                        exit('P_' + XFOREIGN);
                    'XEU':
                        exit('P_' + XEU);
                    else
                        Error('Unknown Sales Advance Letter Template Code %1',AdvanceLetterTemplateCode);
                end;
        end;
    end;
}
