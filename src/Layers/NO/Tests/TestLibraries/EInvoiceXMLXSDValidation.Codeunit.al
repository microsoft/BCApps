codeunit 143002 "E-Invoice XML XSD Validation"
{

    trigger OnRun()
    begin
    end;

    var
        FileDoesNotExistMsg: Label 'File does not exist.';
        Assert: Codeunit Assert;
        NodeDoesNotExistErr: Label 'Node does not exist.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        UnsupportedVATRateErr: Label 'Unsupported VAT rate %1.';
        WrongVATCategoryTxt: Label 'VAT Category is wrong.';
        WrongVATExemptionReasonTxt: Label 'Tax Exemption reason is wrong.';
        WrongTransactionAmountTxt: Label 'The transaction amounts does not match.';
        NOXMLReadHelper: Codeunit "NO XML Read Helper";

    [Scope('OnPrem')]
    procedure CheckIfFileExists(FileName: Text[1024])
    begin
        Assert.IsTrue(Exists(FileName), FileDoesNotExistMsg);
    end;

    [Scope('OnPrem')]
    procedure GetTaxCategoryID(var TempVATEntry: Record "VAT Entry" temporary; VATPercentage: Decimal): Text[2]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        case VATPercentage of
            0:
                begin
                    if TempVATEntry."VAT Calculation Type" = TempVATEntry."VAT Calculation Type"::"Reverse Charge VAT" then
                        exit('K');
                    VATProductPostingGroup.SetRange(Code, TempVATEntry."VAT Prod. Posting Group");
                    if VATProductPostingGroup.FindFirst() and VATProductPostingGroup."Outside Tax Area" then
                        exit('Z');
                    exit('E');
                end;
            10:
                exit('AA');
            11.11:
                exit('R');
            15:
                exit('H');
            25:
                exit('S');
            else
                Error(UnsupportedVATRateErr, TempVATEntry."VAT Base Discount %");
        end;
    end;

    local procedure InvertInvoiceVATAmounts(var VATEntry: Record "VAT Entry")
    begin
        if VATEntry."Document Type" in [VATEntry."Document Type"::Invoice,
                                        VATEntry."Document Type"::"Finance Charge Memo",
                                        VATEntry."Document Type"::Reminder]
        then begin
            VATEntry.Base := -VATEntry.Base;
            VATEntry.Amount := -VATEntry.Amount;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetBankInformation(BankAccountNo: Text[30]; IBAN: Code[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Bank Account No.", BankAccountNo);
        CompanyInformation.Validate(IBAN, IBAN);
        CompanyInformation.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetRandomVATRegNoInCompanyInfo(): Text[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(
          "VAT Registration No.",
          LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code"));
        CompanyInformation.Modify(true);
        exit(CompanyInformation."VAT Registration No.");
    end;

    [Scope('OnPrem')]
    procedure VerifyAccountingParty(TempExpectedCustomer: Record Customer temporary; ExpectedSalesPersonCode: Code[20]; XmlFileName: Text[1024])
    begin
        // AccountingCustomerParty: PostalAddress node has changed
        VerifyAddress(XmlFileName, 'cac:AccountingCustomerParty/cac:Party/cac:PostalAddress', TempExpectedCustomer);

        // AccountingCustomerParty: Contact/cbc:name was added and other elements are "Recommended" instead of "Optional"
        VerifyCustomerContact(XmlFileName, 'cac:AccountingCustomerParty/cac:Party/cac:Contact', TempExpectedCustomer);

        // The 'Person' subnode was deleted
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsenceByXPath('cac:AccountingCustomerParty/cac:Party/cac:Person');
        NOXMLReadHelper.VerifyNodeAbsenceByXPath('cac:AccountingSupplierParty/cac:Party/cac:Person');

        // AccountingSupplierParty information is taked from CompanyInfo, if there's no representant
        VerifySupplierAddress(XmlFileName, 'cac:AccountingSupplierParty/cac:Party/cac:PostalAddress');
        VerifySupplierContact(XmlFileName, 'cac:AccountingSupplierParty/cac:Party/cac:Contact', ExpectedSalesPersonCode);
    end;

    [Scope('OnPrem')]
    procedure VerifyAddress(XmlFileName: Text; XPath: Text; ExpectedCustomerAddress: Record Customer)
    var
        AddressNodes: DotNet XmlNodeList;
        i: Integer;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.GetNodeListByElementName(XPath, AddressNodes);
        for i := 1 to AddressNodes.Count do
            VerifyAddressInNode(AddressNodes.Item(i - 1), ExpectedCustomerAddress);
        NOXMLReadHelper.VerifyAttributeValue('//cbc:IdentificationCode', 'listID', 'ISO3166-1:Alpha2');
    end;

    [Scope('OnPrem')]
    procedure VerifyAddressInNode(Node: DotNet XmlNode; ExpectedCustomerAddress: Record Customer)
    begin
        NOXMLReadHelper.VerifySubnodeValueInCurrNode(Node, 'cbc:StreetName', ExpectedCustomerAddress.Address);
        NOXMLReadHelper.VerifySubnodeValueInCurrNode(Node, 'cbc:AdditionalStreetName', ExpectedCustomerAddress."Address 2");
        NOXMLReadHelper.VerifySubnodeValueInCurrNode(Node, 'cbc:CityName', ExpectedCustomerAddress.City);
        NOXMLReadHelper.VerifySubnodeValueInCurrNode(Node, 'cbc:PostalZone', ExpectedCustomerAddress."Post Code");
        NOXMLReadHelper.VerifySubnodeValueInCurrNode(
          Node, 'cac:Country/cbc:IdentificationCode', ExpectedCustomerAddress."Country/Region Code");
    end;

    [Scope('OnPrem')]
    procedure VerifyCustomerContact(XmlFileName: Text; XPath: Text; ExpectedCustomerInfo: Record Customer)
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:ID', ExpectedCustomerInfo."No.");
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:Name', ExpectedCustomerInfo.Name);
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:Telephone', ExpectedCustomerInfo."Phone No.");
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:Telefax', ExpectedCustomerInfo."Fax No.");
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:ElectronicMail', ExpectedCustomerInfo."E-Mail");
    end;

    [Scope('OnPrem')]
    procedure VerifyDeliveryLocation(XmlFileName: Text[1024])
    var
        DeliveryNodeTxt: Text[30];
    begin
        DeliveryNodeTxt := '//cac:InvoiceLine/cac:Delivery';
        NOXMLReadHelper.Initialize(XmlFileName);
        Assert.IsTrue(NOXMLReadHelper.VerifyNodeExists(DeliveryNodeTxt), DeliveryNodeTxt + NodeDoesNotExistErr);
    end;

    [Scope('OnPrem')]
    procedure VerifyDocumentCurrencyCode(XmlFileName: Text[1024])
    var
        Node: DotNet XmlNode;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.GetNodeByXPath('cbc:DocumentCurrencyCode', Node);
        NOXMLReadHelper.VerifyAttributeFromNode(Node, 'listID', 'ISO4217')
    end;

    [Scope('OnPrem')]
    procedure VerifyEndpointID(XmlFileName: Text[1024])
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeExists('cac:AccountingSupplierParty/cac:Party/cbc:EndpointID[@schemeID="NO:ORGNR"]');
        NOXMLReadHelper.VerifyNodeExists('cac:AccountingCustomerParty/cac:Party/cbc:EndpointID[@schemeID="NO:ORGNR"]');
    end;

    [Scope('OnPrem')]
    procedure VerifyEntRegElements(XmlFileName: Text[1024]; BillToName: Text[100]; VATRegistrationNo: Text[30]; EntRegistered: Boolean)
    var
        Node: DotNet XmlNode;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValueByXPath(
          'cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName', BillToName);

        NOXMLReadHelper.GetNodeByXPath('cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Node);
        // UBL 2.1
        if GetUBLVersionID() = '2.1' then begin
            NOXMLReadHelper.VerifyAttributeFromNode(Node, 'schemeID', 'NO:ORGNR');
            NOXMLReadHelper.VerifyAttributeFromNode(Node, 'schemeAgencyID', '82');
        end;

        NOXMLReadHelper.VerifyNodeValueByXPath(
          'cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', StripVATRegNo(VATRegistrationNo));

        NOXMLReadHelper.GetNodeByXPath('cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Node);

        NOXMLReadHelper.VerifyAttributeFromNode(Node, 'schemeID', 'NO:ORGNR');
        if EntRegistered then
            NOXMLReadHelper.VerifyAttributeFromNode(Node, 'schemeName', 'Foretaksregisteret')
        else
            NOXMLReadHelper.VerifyAttributeAbsenceFromNode(Node, 'schemeName');
        NOXMLReadHelper.VerifyAttributeFromNode(Node, 'schemeAgencyID', '82');
    end;

    [Scope('OnPrem')]
    procedure VerifyIdentificationCode(XmlFileName: Text[1024])
    var
        Node: DotNet XmlNode;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.GetNodeByXPath(
          'cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode', Node);
        NOXMLReadHelper.VerifyAttributeFromNode(Node, 'listID', 'ISO3166-1:Alpha2');

        NOXMLReadHelper.GetNodeByXPath(
          'cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode', Node);
        NOXMLReadHelper.VerifyAttributeFromNode(Node, 'listID', 'ISO3166-1:Alpha2');
    end;

    [Scope('OnPrem')]
    procedure VerifyInvoiceTypeCode(XmlFileName: Text[1024])
    var
        Node: DotNet XmlNode;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.GetNodeByXPath('cbc:InvoiceTypeCode', Node);
        NOXMLReadHelper.VerifyAttributeFromNode(Node, 'listID', 'UNCL1001')
    end;

    [Scope('OnPrem')]
    procedure VerifyPaymentMeansCode(XmlFileName: Text[1024])
    var
        Node: DotNet XmlNode;
        nodeList: DotNet XmlNodeList;
        i: Integer;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.GetNodeList('cac:PaymentMeans/cbc:PaymentMeansCode', nodeList);
        for i := 0 to nodeList.Count - 1 do begin
            Node := nodeList.Item(i);
            NOXMLReadHelper.VerifyAttributeFromNode(Node, 'listID', 'UNCL4461');
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyForeignCurrencyNodes(XmlFileName: Text)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        TaxCurrencyCodeNode: DotNet XmlNode;
        TaxExchangeRateNode: DotNet XmlNode;
        TaxSubtotalNode: DotNet XmlNode;
        SourceCurrencyCode: Code[10];
        TaxCurrencyCode: Code[10];
        ExchangeRateDate: Date;
        DateText: Text;
        TaxAmount: Decimal;
        TransactionCurrencyTaxAmount: Decimal;
        ActualAmount: Decimal;
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] TaxExchangeRate is added to the header
        NOXMLReadHelper.GetNodeByXPath('//cac:TaxExchangeRate', TaxExchangeRateNode);

        // [THEN] TaxCurrencyCode is added to the header
        NOXMLReadHelper.GetNodeByXPath('//cbc:TaxCurrencyCode', TaxCurrencyCodeNode);
        TaxCurrencyCode := TaxCurrencyCodeNode.InnerText;

        // [THEN] TaxExchangeRate has children SourceCurrencyCode, TargetCurrencyCode, Date and MathematicOperatorCode
        SourceCurrencyCode := CopyStr(NOXMLReadHelper.GetElementValueInCurrNode(TaxExchangeRateNode, 'cbc:SourceCurrencyCode'), 1, 10);
        NOXMLReadHelper.VerifyNodeValue('//cac:TaxExchangeRate/cbc:MathematicOperatorCode', 'Multiply');

        // [THEN] TaxCurrencyCode equals SourceCurrencyCode
        Assert.AreEqual(TaxCurrencyCode, SourceCurrencyCode, 'Currency code mismatch');

        DateText := NOXMLReadHelper.GetElementValueInCurrNode(TaxExchangeRateNode, 'cbc:Date');

        Evaluate(Day, CopyStr(DateText, 9, 2));
        Evaluate(Month, CopyStr(DateText, 6, 2));
        Evaluate(Year, CopyStr(DateText, 3, 2));
        ExchangeRateDate := DMY2Date(Day, Month, Year);

        LibraryERM.FindExchRate(CurrencyExchangeRate, SourceCurrencyCode, ExchangeRateDate);

        // [THEN] CalculationRate in TaxExchangeRate = X
        NOXMLReadHelper.VerifyNodeValue('//cac:TaxExchangeRate/cbc:CalculationRate',
          Format(CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount", 0, 9));

        // [THEN] TransactionCurrencyTaxAmount is added to subtotal with correct amount
        NOXMLReadHelper.GetNodeByXPath('//cac:TaxTotal/cac:TaxSubtotal', TaxSubtotalNode);
        Evaluate(TaxAmount, NOXMLReadHelper.GetElementValueInCurrNode(TaxSubtotalNode, 'cbc:TaxAmount'), 9);
        Evaluate(
          TransactionCurrencyTaxAmount,
          NOXMLReadHelper.GetElementValueInCurrNode(TaxSubtotalNode, 'cbc:TransactionCurrencyTaxAmount[@currencyID="NOK"]'), 9);

        ActualAmount := Round(LibraryERM.ConvertCurrency(TaxAmount, SourceCurrencyCode, '', ExchangeRateDate), 0.01);
        Assert.AreEqual(ActualAmount, TransactionCurrencyTaxAmount, WrongTransactionAmountTxt);
    end;

    [Scope('OnPrem')]
    procedure VerifyReminderTypeCode(XmlFileName: Text[1024])
    var
        Node: DotNet XmlNode;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.GetNodeByXPath('cbc:ReminderTypeCode', Node);
        NOXMLReadHelper.VerifyAttributeFromNode(Node, 'listID', 'UN/ECE 1001 Subset')
    end;

    [Scope('OnPrem')]
    procedure VerifySupplierAddress(XmlFileName: Text; XPath: Text)
    var
        CompanyInformation: Record "Company Information";
        Node: DotNet XmlNode;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        CompanyInformation.Get();
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:StreetName', CompanyInformation.Address);
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:CityName', CompanyInformation.City);
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:PostalZone', CompanyInformation."Post Code");
        NOXMLReadHelper.VerifySubnodeValueInParentNode(
          XPath + '/cac:Country', 'cbc:IdentificationCode', CompanyInformation."Country/Region Code");
        NOXMLReadHelper.GetNodeByXPath(StrSubstNo('%1%2', XPath, '/cac:Country/cbc:IdentificationCode'), Node);
        NOXMLReadHelper.VerifyAttributeFromNode(Node, 'listID', 'ISO3166-1:Alpha2');
    end;

    [Scope('OnPrem')]
    procedure VerifySupplierContact(XmlFileName: Text; XPath: Text; SalesPersonCode: Code[20])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        SalespersonPurchaser.Get(SalesPersonCode);
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:ID', SalespersonPurchaser.Code);
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:Name', SalespersonPurchaser.Name);
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:Telephone', SalespersonPurchaser."Phone No.");
        NOXMLReadHelper.VerifySubnodeValueInParentNode(XPath, 'cbc:ElectronicMail', SalespersonPurchaser."E-Mail");
    end;

    [Scope('OnPrem')]
    procedure VerifyVATEntriesCount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ExpectedVATEntriesCount: Integer; var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        if VATEntry.FindSet() then
            repeat
                if not DoesVATGroupExist(TempVATEntry, VATEntry) then begin
                    TempVATEntry := VATEntry;
                    TempVATEntry.Insert();
                end else begin
                    TempVATEntry.Base += VATEntry.Base;
                    TempVATEntry.Amount += VATEntry.Amount;
                    TempVATEntry.Modify();
                end;
            until VATEntry.Next() = 0;
        TempVATEntry.Reset();

        Assert.AreEqual(ExpectedVATEntriesCount, TempVATEntry.Count, 'Wrong number of VAT Entries posted.');
    end;

    [Scope('OnPrem')]
    procedure VerifyVATDataInTaxSubtotal(var VATEntry: Record "VAT Entry"; XmlFileName: Text; ExpectedNoOfGroups: Integer)
    var
        TempVATEntry: Record "VAT Entry" temporary;
        TaxSubtotalList: DotNet XmlNodeList;
        NoOfGroups: Integer;
        ElementName: Text[30];
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        ElementName := '//cac:TaxSubtotal';
        NoOfGroups := NOXMLReadHelper.GetNodeListByElementName(ElementName, TaxSubtotalList);
        Assert.AreEqual(ExpectedNoOfGroups, NoOfGroups, 'Wrong number of <' + ElementName + '>');

        FillTempVATEntryBufFromHeader(TaxSubtotalList, TempVATEntry);

        if VATEntry.FindSet() then
            repeat
                TempVATEntry.SetRange("VAT Prod. Posting Group", GetVATIdentifier(VATEntry));
                TempVATEntry.FindFirst();
                InvertInvoiceVATAmounts(VATEntry);
                Assert.AreEqual(VATEntry.Base, TempVATEntry.Base, 'Wrong TaxableAmount');
                Assert.AreEqual(VATEntry.Amount, TempVATEntry.Amount, 'Wrong TaxAmount');
                Assert.AreEqual(GetTaxCategoryID(VATEntry, TempVATEntry."VAT Base Discount %"), TempVATEntry."VAT Number", 'Wrong ID');
                if VATEntry."Entry No." = 0 then
                    Assert.AreEqual(GetExemptionReason(VATEntry), GetExemptionReason(TempVATEntry), WrongVATExemptionReasonTxt);
                TempVATEntry.Delete();
            until VATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyTaxCategorySchemaIdAttribute(XmlFileName: Text)
    var
        Node: DotNet XmlNode;
        TaxSubtotalList: DotNet XmlNodeList;
        NoOfGroups: Integer;
        ElementName: Text[30];
        i: Integer;
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        ElementName := '//cac:TaxSubtotal';
        NoOfGroups := NOXMLReadHelper.GetNodeListByElementName(ElementName, TaxSubtotalList);
        for i := 1 to NoOfGroups do begin
            NOXMLReadHelper.GetNodeByXPath('cac:TaxTotal/cac:TaxSubtotal[' + Format(i) + ']/cac:TaxCategory/cbc:ID', Node);
            NOXMLReadHelper.VerifyAttributeFromNode(Node, 'schemeID', 'UNCL5305');
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyZeroVATCategory(XmlFileName: Text; TaxCategory: Text[2]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SchemaType: Option Invoice,CrMemo,Reminder)
    var
        TempVATEntry: Record "VAT Entry" temporary;
    begin
        VerifyVATEntriesCount(DocumentType, DocumentNo, 1, TempVATEntry);
        Assert.AreEqual(TaxCategory, GetTaxCategoryID(TempVATEntry, 0), WrongVATCategoryTxt);
        VerifyVATDataInTaxSubtotal(TempVATEntry, XmlFileName, 1);
        if SchemaType = SchemaType::Invoice then
            VerifyVATDataInInvoiceLine(TempVATEntry, XmlFileName, 2);
    end;

    local procedure CreateGenProdPostingGroup(Description: Text): Code[10]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        DescriptionTrimmed: Text[50];
    begin
        GenProductPostingGroup.Init();
        GenProductPostingGroup.Validate(Code, CopyStr(LibraryUtility.GenerateGUID(), 5, 6)); // Currency code must be exactly 3 characters long.
        DescriptionTrimmed := CopyStr(Description, 1, 50);
        GenProductPostingGroup.Validate(Description, DescriptionTrimmed);
        GenProductPostingGroup.Insert();
        exit(GenProductPostingGroup.Code);
    end;

    local procedure DoesVATGroupExist(var TempVATEntry: Record "VAT Entry" temporary; VATEntry: Record "VAT Entry"): Boolean
    begin
        TempVATEntry.SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
        TempVATEntry.SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
        exit(TempVATEntry.FindFirst())
    end;

    local procedure GetExemptionReason(VATEntry: Record "VAT Entry"): Text
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.SetFilter(Code, VATEntry."Gen. Prod. Posting Group");
        GenProductPostingGroup.FindFirst();
        exit(GenProductPostingGroup.Description);
    end;

    local procedure FillTempVATEntryBufFromHeader(TaxSubtotalList: DotNet XmlNodeList; var TempVATEntry: Record "VAT Entry" temporary)
    var
        TaxSubtotalNode: DotNet XmlNode;
        TaxCategoryNode: DotNet XmlNode;
        i: Integer;
    begin
        for i := 1 to TaxSubtotalList.Count do begin
            TaxSubtotalNode := TaxSubtotalList.Item(i - 1);

            TempVATEntry.Init();
            Evaluate(TempVATEntry.Base, NOXMLReadHelper.GetElementValueInCurrNode(TaxSubtotalNode, 'cbc:TaxableAmount'), 9);
            Evaluate(TempVATEntry.Amount, NOXMLReadHelper.GetElementValueInCurrNode(TaxSubtotalNode, 'cbc:TaxAmount'), 9);

            FillTempVATEntryBuffWithTaxCategory(TaxSubtotalNode, TempVATEntry, 'cac:TaxCategory');

            NOXMLReadHelper.GetElementInCurrNode(TaxSubtotalNode, 'cac:TaxCategory', TaxCategoryNode);
            if TempVATEntry."Entry No." = 0 then
                TempVATEntry.Validate("Gen. Prod. Posting Group",
                  CreateGenProdPostingGroup(NOXMLReadHelper.GetElementValueInCurrNode(TaxCategoryNode, 'cbc:TaxExemptionReason')));

            TempVATEntry.Insert();
        end;
    end;

    local procedure FillTempVATEntryBufFromLine(ItemList: DotNet XmlNodeList; var TempVATEntry: Record "VAT Entry" temporary)
    var
        i: Integer;
    begin
        for i := 1 to ItemList.Count do begin
            TempVATEntry.Init();
            FillTempVATEntryBuffWithTaxCategory(ItemList.Item(i - 1), TempVATEntry, 'cac:ClassifiedTaxCategory');
            if TempVATEntry.Insert() then;
        end;
    end;

    local procedure FillTempVATEntryBuffWithTaxCategory(TaxSubtotalNode: DotNet XmlNode; var TempVATEntry: Record "VAT Entry" temporary; TaxCategoryName: Text)
    var
        TaxCategoryNode: DotNet XmlNode;
        TaxPctText: Text[10];
        DotIndex: Integer;
    begin
        NOXMLReadHelper.GetElementInCurrNode(TaxSubtotalNode, TaxCategoryName, TaxCategoryNode);
        TaxPctText := CopyStr(NOXMLReadHelper.GetElementValueInCurrNode(TaxCategoryNode, 'cbc:Percent'), 1, 10);
        Evaluate(TempVATEntry."VAT Base Discount %", TaxPctText, 9);
        DotIndex := StrPos(TaxPctText, '.');
        if DotIndex > 1 then
            TaxPctText := CopyStr(TaxPctText, 1, DotIndex - 1);
        Evaluate(TempVATEntry."Entry No.", TaxPctText, 9);
        TempVATEntry."VAT Prod. Posting Group" := CopyStr('VAT' + TaxPctText, 1, MaxStrLen(TempVATEntry."VAT Prod. Posting Group"));
        TempVATEntry."VAT Number" :=
            CopyStr(NOXMLReadHelper.GetElementValueInCurrNode(TaxCategoryNode, 'cbc:ID'), 1, MaxStrLen(TempVATEntry."VAT Number"));
    end;

    local procedure GetVATIdentifier(VATEntry: Record "VAT Entry"): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        exit(VATPostingSetup."VAT Identifier");
    end;

    local procedure GetUBLVersionID(): Code[3]
    var
        Node: DotNet XmlNode;
    begin
        NOXMLReadHelper.GetNodeByXPath('cbc:UBLVersionID', Node);
        exit(Format(Node.InnerText))
    end;

    local procedure VerifyVATDataInInvoiceLine(var VATEntry: Record "VAT Entry"; XmlFileName: Text; ExpectedNoOfGroups: Integer)
    var
        TempVATEntry: Record "VAT Entry" temporary;
        ItemList: DotNet XmlNodeList;
        NoOfGroups: Integer;
        ElementName: Text[30];
    begin
        NOXMLReadHelper.Initialize(XmlFileName);
        // Verifies that Invoice->item VAT categories exists in the VATEntry
        ElementName := '//cac:Item';
        NoOfGroups := NOXMLReadHelper.GetNodeListByElementName(ElementName, ItemList);
        Assert.AreEqual(ExpectedNoOfGroups, NoOfGroups, 'Wrong number of <' + ElementName + '>');

        FillTempVATEntryBufFromLine(ItemList, TempVATEntry);

        if VATEntry.FindSet() then
            repeat
                TempVATEntry.SetRange("VAT Prod. Posting Group", GetVATIdentifier(VATEntry));
                TempVATEntry.FindFirst();
                Assert.AreEqual(GetTaxCategoryID(VATEntry, TempVATEntry."VAT Base Discount %"), TempVATEntry."VAT Number", 'Wrong ID');
                TempVATEntry.Delete();
            until VATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure StripVATRegNo(VATRegNo: Text[30]): Text[30]
    begin
        exit(DelChr(VATRegNo, '=', DelChr(VATRegNo, '=', '0123456789')));
    end;
}

