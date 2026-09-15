#pragma warning disable AA0247
report 14912 "Allocate FA Charges"
{
    Caption = 'Allocate FA Charges';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.");

            trigger OnAfterGetRecord()
            begin
                if SourceDocNo = "No." then
                    FieldError("No.");

                if "Currency Code" = '' then
                    Currency.InitRoundingPrecision()
                else begin
                    TestField("Currency Factor");
                    Currency.Get("Currency Code");
                    Currency.TestField("Amount Rounding Precision");
                end;

                CreatePurchLineBuffer();

                if SourcePurchLine.FindSet() then begin
                    repeat
                        SourceDocAmount += SourcePurchLine."Direct Unit Cost";
                    until SourcePurchLine.Next() = 0;

                    PurchLine.SetRange("Document Type", "Document Type");
                    PurchLine.SetRange("Document No.", "No.");
                    if PurchLine.FindLast() then;
                    LineNo := PurchLine."Line No." + 10000;

                    SourcePurchLine.FindSet();
                    repeat
                        PurchLine.Init();
                        PurchLine := SourcePurchLine;
                        PurchLine."Document Type" := "Document Type";
                        PurchLine."Document No." := "No.";
                        PurchLine."Line No." := LineNo;
                        PurchLine.Validate("Direct Unit Cost",
                          Round(PurchLine."Direct Unit Cost" * AmountToAllocate / SourceDocAmount,
                            Currency."Amount Rounding Precision"));
                        PurchLine.Validate(Quantity);
                        PurchLine.Validate("FA Charge No.", FAChargeNo);
                        PurchLine.Insert();

                        LineNo += 10000;
                        TotalAmount += PurchLine."Direct Unit Cost";
                    until SourcePurchLine.Next() = 0;

                    if TotalAmount <> AmountToAllocate then begin
                        PurchLine.FindLast();
                        PurchLine.Validate("Direct Unit Cost",
                          PurchLine."Direct Unit Cost" + AmountToAllocate - TotalAmount);
                        PurchLine.Modify();
                    end;
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocType; DocType)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Source Document Type';
                        OptionCaption = 'Invoice,Order,Posted Invoice';
                        ToolTip = 'Specifies the type of the source document that is associated with the fixed asset charge.';

                        trigger OnValidate()
                        begin
                            SourceDocType := GetSourceType();
                        end;
                    }
                    field(SourceDocNo; SourceDocNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Source Document No.';
                        ToolTip = 'Specifies the number of the source document that is associated with the fixed asset charge.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo();
                        end;
                    }
                    field(AmountToAllocate; AmountToAllocate)
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount';
                        ToolTip = 'Specifies the amount.';
                    }
                    field(FAChargeNo; FAChargeNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Charge No.';
                        TableRelation = "FA Charge";
                        ToolTip = 'Specifies the fixed asset charge number. You can use fixed asset charges to include additional charges on the purchase of a fixed assets in the fixed asset acquisition cost.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            SourceDocType := GetSourceType();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if SourceDocNo = '' then
            Error(Text000);

        if AmountToAllocate = 0 then
            Error(Text001);

        if FAChargeNo = '' then
            Error(Text002);

        GLSetup.Get();
    end;

    var
        Currency: Record Currency;
        PurchHeader: Record "Purchase Header";
        FromPurchHeader: Record "Purchase Header";
        FromPurchRcptHeader: Record "Purch. Rcpt. Header";
        FromPurchInvHeader: Record "Purch. Inv. Header";
        FromReturnShptHeader: Record "Return Shipment Header";
        FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SourcePurchLine: Record "Purchase Line" temporary;
        PurchLine: Record "Purchase Line";
        GLSetup: Record "General Ledger Setup";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        DocType: Option Invoice,"Order","Posted Invoice";
        SourceDocType: Enum "Purchase Document Type From";
        SourceDocNo: Code[20];
        SourceDocAmount: Decimal;
        AmountToAllocate: Decimal;
        TotalAmount: Decimal;
        FAChargeNo: Code[20];
#pragma warning disable AA0074
        Text000: Label 'The Source Document No. must be entered.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label 'The Amount must be entered.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'The FA Charge No. must be entered.';
#pragma warning restore AA0074
        LineNo: Integer;

    local procedure LookupDocNo()
    begin
        case SourceDocType of
            SourceDocType::Quote,
            SourceDocType::"Blanket Order",
            SourceDocType::Order,
            SourceDocType::Invoice,
            SourceDocType::"Return Order",
            SourceDocType::"Credit Memo":
                begin
                    FromPurchHeader.FilterGroup := 0;
                    FromPurchHeader.SetRange("Document Type", SourceDocType);
                    if PurchHeader."Document Type" = CopyDocMgt.GetPurchaseDocumentType(SourceDocType) then
                        FromPurchHeader.SetFilter("No.", '<>%1', PurchHeader."No.");
                    FromPurchHeader.FilterGroup := 2;
                    FromPurchHeader."Document Type" := SourceDocType;
                    FromPurchHeader."No." := SourceDocNo;
                    if (SourceDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
                        if FromPurchHeader.SetCurrentKey("Document Type", "Buy-from Vendor No.") then begin
                            FromPurchHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                            if FromPurchHeader.Find('=><') then;
                        end;
                    if PAGE.RunModal(0, FromPurchHeader) = ACTION::LookupOK then
                        SourceDocNo := FromPurchHeader."No.";
                end;
            SourceDocType::"Posted Receipt":
                begin
                    FromPurchRcptHeader."No." := SourceDocNo;
                    if (SourceDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
                        if FromPurchRcptHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                            FromPurchRcptHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                            if FromPurchRcptHeader.Find('=><') then;
                        end;
                    if PAGE.RunModal(0, FromPurchRcptHeader) = ACTION::LookupOK then
                        SourceDocNo := FromPurchRcptHeader."No.";
                end;
            SourceDocType::"Posted Invoice":
                begin
                    FromPurchInvHeader."No." := SourceDocNo;
                    if (SourceDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
                        if FromPurchInvHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                            FromPurchInvHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                            if FromPurchInvHeader.Find('=><') then;
                        end;
                    if PAGE.RunModal(0, FromPurchInvHeader) = ACTION::LookupOK then
                        SourceDocNo := FromPurchInvHeader."No.";
                end;
            SourceDocType::"Posted Return Shipment":
                begin
                    FromReturnShptHeader."No." := SourceDocNo;
                    if (SourceDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
                        if FromReturnShptHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                            FromReturnShptHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                            if FromReturnShptHeader.Find('=><') then;
                        end;
                    if PAGE.RunModal(0, FromReturnShptHeader) = ACTION::LookupOK then
                        SourceDocNo := FromReturnShptHeader."No.";
                end;
            SourceDocType::"Posted Credit Memo":
                begin
                    FromPurchCrMemoHeader."No." := SourceDocNo;
                    if (SourceDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
                        if FromPurchCrMemoHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                            FromPurchCrMemoHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                            if FromPurchCrMemoHeader.Find('=><') then;
                        end;
                    if PAGE.RunModal(0, FromPurchCrMemoHeader) = ACTION::LookupOK then
                        SourceDocNo := FromPurchCrMemoHeader."No.";
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePurchLineBuffer()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        case SourceDocType of
            SourceDocType::Quote,
            SourceDocType::"Blanket Order",
            SourceDocType::Order,
            SourceDocType::Invoice,
            SourceDocType::"Return Order",
            SourceDocType::"Credit Memo":
                begin
                    PurchaseLine.SetRange("Document Type", SourceDocType);
                    PurchaseLine.SetRange("Document No.", SourceDocNo);
                    PurchaseLine.SetRange(Type, PurchaseLine.Type::"Fixed Asset");
                    if PurchaseLine.Find('-') then
                        repeat
                            SourcePurchLine := PurchaseLine;
                            SourcePurchLine.Insert();
                        until PurchaseLine.Next() = 0;
                end;
            SourceDocType::"Posted Receipt":
                begin
                    PurchRcptLine.SetRange("Document No.", SourceDocNo);
                    PurchRcptLine.SetRange(Type, PurchRcptLine.Type::"Fixed Asset");
                    if PurchRcptLine.Find('-') then
                        repeat
                            SourcePurchLine.TransferFields(PurchRcptLine);
                            SourcePurchLine.Insert();
                        until PurchRcptLine.Next() = 0;
                end;
            SourceDocType::"Posted Invoice":
                begin
                    PurchInvLine.SetRange("Document No.", SourceDocNo);
                    PurchInvLine.SetRange(Type, PurchInvLine.Type::"Fixed Asset");
                    if PurchInvLine.Find('-') then
                        repeat
                            SourcePurchLine.TransferFields(PurchInvLine);
                            SourcePurchLine.Insert();
                        until PurchInvLine.Next() = 0;
                end;
            SourceDocType::"Posted Return Shipment":
                begin
                    ReturnShipmentLine.SetRange("Document No.", SourceDocNo);
                    ReturnShipmentLine.SetRange(Type, ReturnShipmentLine.Type::"Fixed Asset");
                    if ReturnShipmentLine.Find('-') then
                        repeat
                            SourcePurchLine.TransferFields(ReturnShipmentLine);
                            SourcePurchLine.Insert();
                        until ReturnShipmentLine.Next() = 0;
                end;
            SourceDocType::"Posted Credit Memo":
                begin
                    PurchCrMemoLine.SetRange("Document No.", SourceDocNo);
                    PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::"Fixed Asset");
                    if PurchCrMemoLine.Find('-') then
                        repeat
                            SourcePurchLine.TransferFields(PurchCrMemoLine);
                            SourcePurchLine.Insert();
                        until PurchCrMemoLine.Next() = 0;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetSourceType(): Enum "Purchase Document Type From"
    begin
        case DocType of
            DocType::Invoice:
                exit(SourceDocType::Invoice);
            DocType::Order:
                exit(SourceDocType::Order);
            DocType::"Posted Invoice":
                exit(SourceDocType::"Posted Invoice");
        end;
    end;

    [Scope('OnPrem')]
    procedure SetParameters(NewDocType: Integer; NewDocNo: Code[20]; NewAmountToAllocate: Decimal; NewFAChargeNo: Code[20])
    begin
        DocType := NewDocType;
        SourceDocType := GetSourceType();
        SourceDocNo := NewDocNo;
        AmountToAllocate := NewAmountToAllocate;
        FAChargeNo := NewFAChargeNo;
    end;
}

