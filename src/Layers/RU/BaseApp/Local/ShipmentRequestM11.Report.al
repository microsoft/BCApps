#pragma warning disable AA0247
report 12471 "Shipment Request M-11"
{
    Caption = 'Shipment Request M-11';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Transfer Header"; "Transfer Header")
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                CopyFromTransferHeader("Transfer Header", LineBuffer);

                AuthorizedBy := "Transfer-from Contact";
                RequestedBy := "Transfer-to Contact";

                if ReleasedByCode = '' then
                    ReleasedByCode := GetEmployeeCode(DATABASE::"Transfer Header", "No.",
                        DocumentSignature."Employee Type"::ReleasedBy, "Transfer-from Code");

                if ReceivedByCode = '' then
                    ReceivedByCode := GetEmployeeCode(DATABASE::"Transfer Header", "No.",
                        DocumentSignature."Employee Type"::ReceivedBy, "Transfer-to Code");
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();
            end;
        }
        dataitem("Item Journal Line"; "Item Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");

            trigger OnAfterGetRecord()
            var
                Location: Record Location;
            begin
                CopyFromItemJournalLine("Item Journal Line", LineBuffer);

                if Location.Get("New Location Code") then begin
                    if ReceivedByCode = '' then
                        ReceivedByCode := Location."Responsible Employee No.";
                    RequestedBy := Location.Contact;
                end;

                if Location.Get("Location Code") then begin
                    if ReleasedByCode = '' then
                        ReleasedByCode := Location."Responsible Employee No.";
                    AuthorizedBy := Location.Contact;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();
            end;
        }
        dataitem("Transfer Receipt Header"; "Transfer Receipt Header")
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                CopyFromTransferReceiptHeader("Transfer Receipt Header", LineBuffer);

                AuthorizedBy := "Transfer-from Contact";
                RequestedBy := "Transfer-to Contact";

                if ReleasedByCode = '' then
                    ReleasedByCode := GetEmployeeCode(DATABASE::"Transfer Receipt Header", "No.",
                        DocumentSignature."Employee Type"::ReleasedBy, "Transfer-from Code");

                if ReceivedByCode = '' then
                    ReceivedByCode := GetEmployeeCode(DATABASE::"Transfer Receipt Header", "No.",
                        DocumentSignature."Employee Type"::ReceivedBy, "Transfer-to Code");
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();
            end;
        }
        dataitem("Transfer Shipment Header"; "Transfer Shipment Header")
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                CopyFromTransferShipmentHeader("Transfer Shipment Header", LineBuffer);

                AuthorizedBy := "Transfer-from Contact";
                RequestedBy := "Transfer-to Contact";

                if ReleasedByCode = '' then
                    ReleasedByCode := GetEmployeeCode(DATABASE::"Transfer Shipment Header", "No.",
                        DocumentSignature."Employee Type"::ReleasedBy, "Transfer-from Code");

                if ReceivedByCode = '' then
                    ReceivedByCode := GetEmployeeCode(DATABASE::"Transfer Shipment Header", "No.",
                        DocumentSignature."Employee Type"::ReceivedBy, "Transfer-to Code");
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();
            end;
        }
        dataitem(HeaderLoop; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    HeaderBuffer.FindSet();
                    FillReportHeader1();
                end else
                    HeaderBuffer.Next();

                CorrAcc := HeaderBuffer."Item No.";
                CorrAccDimValue := HeaderBuffer."Variant Code";
                UnitOfMeasure := HeaderBuffer."Location Code";

                Location.Get(LineBuffer."Location Code");
                OrgDepartFrom := Location.Name + Location."Name 2";

                Location.Get(LineBuffer."New Location Code");
                OrgDepartTo := Location.Name + Location."Name 2";

                FillBody1();
            end;

            trigger OnPostDataItem()
            begin
                FillReportHeader2();
            end;

            trigger OnPreDataItem()
            begin
                HeaderBuffer.Reset();

                CompanyInfo.Get();
                SetRange(Number, 1, HeaderBuffer.Count);
            end;
        }
        dataitem(LineLoop; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    LineBuffer.FindSet();
                    InventoryReportsHelper.FillM11PageHeader();
                end else
                    LineBuffer.Next();

                FillBody();
            end;

            trigger OnPostDataItem()
            begin
                FillReportFooter();
            end;

            trigger OnPreDataItem()
            begin
                LineBuffer.Reset();
                SetRange(Number, 1, LineCount);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(OperationTypeCode; OperationTypeCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation type code';
                        ToolTip = 'Specifies the type of the related operation, for the purpose of VAT reporting.';
                    }
                    field(TransferFromActivityCategory; TransferFromActivityCategory)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Transfer-from activity category';
                    }
                    field(TransferToActivityCategory; TransferToActivityCategory)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Transfer-to activity category';
                    }
                    field(KindOperationCode; KindOperationCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Corr. Acc. Dimension Code';
                        TableRelation = Dimension;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            DimensionTable: Record Dimension;
                            DimensionListForm: Page "Dimension List";
                        begin
                            Clear(DimensionListForm);
                            DimensionListForm.LookupMode := true;
                            if DimensionListForm.RunModal() = ACTION::LookupOK then begin
                                DimensionListForm.GetRecord(DimensionTable);
                                KindOperationCode := DimensionTable.Code;
                            end;
                        end;
                    }
                    field(PassedByCode; PassedByCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Passed by (Employee)';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the employee who approved the item.';
                    }
                    field(ReleasedByCode; ReleasedByCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Released by (Employee) ';
                        TableRelation = Employee;
                    }
                    field(ReceivedByCode; ReceivedByCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Received by (Employee) ';
                        TableRelation = Employee;
                    }
                    field(WithoutAmount; WithoutAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Without amounts';
                    }
                    field(QuantityType; QuantityType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Quantity - shipped';
                        OptionCaption = 'Qty. to Ship,Qty. Shipped';
                        ToolTip = 'Specifies how many pieces of the item are shipped.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            InventoryReportsHelper.ExportDataFile(FileName)
        else
            InventoryReportsHelper.ExportData();
    end;

    trigger OnPreReport()
    begin
        InventoryReportsHelper.InitM11Report();
    end;

    var
        Location: Record Location;
        CompanyInfo: Record "Company Information";
        LineBuffer: Record "Item Journal Line" temporary;
        Item: Record Item;
        HeaderBuffer: Record "Avg. Cost Adjmt. Entry Point" temporary;
        DocumentSignature: Record "Document Signature";
        DimSetEntry: Record "Dimension Set Entry";
        StdRepMgt: Codeunit "Local Report Management";
        InventoryReportsHelper: Codeunit "Shipment Request M-11 Helper";
        KindOperationCode: Code[20];
        CorrAcc: Code[20];
        CorrAccDimValue: Code[20];
        UnitOfMeasure: Code[10];
        PassedByCode: Code[20];
        ReceivedByCode: Code[20];
        ReleasedByCode: Code[20];
        OperationTypeCode: Text[30];
        RequestedBy: Text[100];
        AuthorizedBy: Text[100];
        TransferFromActivityCategory: Text[50];
        TransferToActivityCategory: Text[50];
        OrgDepartFrom: Text[250];
        OrgDepartTo: Text[250];
        FileName: Text;
        WithoutAmount: Boolean;
        QuantityType: Option "Qty. to Ship","Qty. Shipped";
        LineCount: Integer;

    [Scope('OnPrem')]
    procedure GetEmployeeCode(TableID: Integer; DocumentNo: Code[20]; EmployeeType: Option; LocationCode: Code[10]) EmployeeCode: Code[20]
    var
        Location: Record Location;
        PostedDocumentSignature: Record "Posted Document Signature";
        DocumentSignature: Record "Document Signature";
    begin
        case TableID of
            DATABASE::"Transfer Header":
                if DocumentSignature.Get(TableID, 0, DocumentNo, EmployeeType) then
                    exit(DocumentSignature."Employee No.");
            DATABASE::"Transfer Shipment Header", DATABASE::"Transfer Receipt Header":
                if PostedDocumentSignature.Get(TableID, 0, DocumentNo, EmployeeType) then
                    exit(PostedDocumentSignature."Employee No.");
        end;

        if Location.Get(LocationCode) then
            exit(Location."Responsible Employee No.");

        EmployeeCode := '';
    end;

    [Scope('OnPrem')]
    procedure HeaderBufferInsert(DimensionCodeValue: Code[20]; UnitOfMeasureCode: Code[10]; InventoryAccount: Code[20])
    begin
        HeaderBuffer.Init();
        HeaderBuffer."Item No." := InventoryAccount;
        HeaderBuffer."Variant Code" := DimensionCodeValue;
        HeaderBuffer."Location Code" := UnitOfMeasureCode;
        if HeaderBuffer.Insert() then;
    end;

    [Scope('OnPrem')]
    procedure CopyFromTransferHeader(TransferHeader: Record "Transfer Header"; var LineBuffer: Record "Item Journal Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        LineCount := TransferLine.Count();

        if TransferLine.FindSet() then
            repeat
                LineBuffer.Init();
                LineBuffer."Line No." := TransferLine."Line No.";
                LineBuffer."Document No." := TransferHeader."No.";
                LineBuffer."Posting Date" := TransferHeader."Posting Date";
                LineBuffer."Location Code" := TransferHeader."Transfer-from Code";
                LineBuffer."New Location Code" := TransferHeader."Transfer-to Code";
                LineBuffer.Description := TransferLine.Description;
                LineBuffer."Item No." := TransferLine."Item No.";
                LineBuffer."Unit of Measure Code" := TransferLine."Unit of Measure Code";
                LineBuffer.Quantity := TransferLine.Quantity;

                if QuantityType = 0 then
                    LineBuffer."Invoiced Quantity" := TransferLine."Qty. to Ship"
                else
                    LineBuffer."Invoiced Quantity" := TransferLine."Quantity Shipped";

                Item.Get(TransferLine."Item No.");
                if not WithoutAmount then
                    LineBuffer."Unit Cost" := Item."Unit Cost";

                if InventoryPostingSetup.Get(TransferHeader."Transfer-to Code", Item."Inventory Posting Group") then
                    LineBuffer."Shortcut Dimension 1 Code" := InventoryPostingSetup."Inventory Account";
                if DimSetEntry.Get(TransferLine."Dimension Set ID", KindOperationCode) then
                    LineBuffer."Shortcut Dimension 2 Code" := DimSetEntry."Dimension Value Code";

                InventoryPostingSetup.Get(TransferHeader."Transfer-from Code", Item."Inventory Posting Group");
                HeaderBufferInsert(LineBuffer."Shortcut Dimension 2 Code",
                  TransferLine."Unit of Measure Code",
                  InventoryPostingSetup."Inventory Account");

                LineBuffer.Insert();
            until TransferLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CopyFromItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; var LineBuffer: Record "Item Journal Line" temporary)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LineCount := ItemJournalLine.Count;

        if ItemJournalLine.FindSet() then
            repeat
                LineBuffer.Init();
                LineBuffer."Journal Template Name" := ItemJournalLine."Journal Template Name";
                LineBuffer."Journal Batch Name" := ItemJournalLine."Journal Batch Name";
                LineBuffer."Line No." := ItemJournalLine."Line No.";
                LineBuffer."Document No." := ItemJournalLine."Document No.";
                LineBuffer."Posting Date" := ItemJournalLine."Posting Date";
                LineBuffer."Location Code" := ItemJournalLine."Location Code";
                LineBuffer."New Location Code" := ItemJournalLine."New Location Code";
                LineBuffer.Description := ItemJournalLine.Description;
                LineBuffer."Item No." := ItemJournalLine."Item No.";
                LineBuffer."Unit of Measure Code" := ItemJournalLine."Unit of Measure Code";
                LineBuffer.Quantity := ItemJournalLine.Quantity;
                LineBuffer."Invoiced Quantity" := ItemJournalLine."Invoiced Quantity";

                if not WithoutAmount then
                    LineBuffer."Unit Cost" := ItemJournalLine."Unit Cost";

                Item.Get(ItemJournalLine."Item No.");
                if InventoryPostingSetup.Get(ItemJournalLine."New Location Code", Item."Inventory Posting Group") then
                    LineBuffer."Shortcut Dimension 1 Code" := InventoryPostingSetup."Inventory Account";
                if DimSetEntry.Get(ItemJournalLine."Dimension Set ID", KindOperationCode) then
                    LineBuffer."Shortcut Dimension 2 Code" := DimSetEntry."Dimension Value Code";

                InventoryPostingSetup.Get(ItemJournalLine."Location Code", Item."Inventory Posting Group");
                HeaderBufferInsert(LineBuffer."Shortcut Dimension 2 Code",
                  ItemJournalLine."Unit of Measure Code",
                  InventoryPostingSetup."Inventory Account");

                LineBuffer.Insert();
            until ItemJournalLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CopyFromTransferReceiptHeader(TransferReceiptHeader: Record "Transfer Receipt Header"; var LineBuffer: Record "Item Journal Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptLine.SetRange("Document No.", TransferReceiptHeader."No.");
        LineCount := TransferReceiptLine.Count();

        if TransferReceiptLine.FindSet() then
            repeat
                LineBuffer.Init();
                LineBuffer."Line No." := TransferReceiptLine."Line No.";
                LineBuffer."Document No." := TransferReceiptHeader."No.";
                LineBuffer."Posting Date" := TransferReceiptHeader."Posting Date";
                LineBuffer."Location Code" := TransferReceiptHeader."Transfer-from Code";
                LineBuffer."New Location Code" := TransferReceiptHeader."Transfer-to Code";
                LineBuffer.Description := TransferReceiptLine.Description;
                LineBuffer."Item No." := TransferReceiptLine."Item No.";
                LineBuffer."Unit of Measure Code" := TransferReceiptLine."Unit of Measure Code";
                LineBuffer.Quantity := TransferReceiptLine.Quantity;
                LineBuffer."Invoiced Quantity" := TransferReceiptLine.Quantity;

                if not WithoutAmount then
                    LineBuffer."Unit Cost" := GetUnitCost(LineBuffer);

                Item.Get(LineBuffer."Item No.");
                if InventoryPostingSetup.Get(TransferReceiptHeader."Transfer-to Code", Item."Inventory Posting Group") then
                    LineBuffer."Shortcut Dimension 1 Code" := InventoryPostingSetup."Inventory Account";
                if DimSetEntry.Get(TransferReceiptLine."Dimension Set ID", KindOperationCode) then
                    LineBuffer."Shortcut Dimension 2 Code" := DimSetEntry."Dimension Value Code";

                LineBuffer."Item Shpt. Entry No." := GetItemLedgerEntryNo(LineBuffer."Item No.",
                    LineBuffer."Document No.", LineBuffer."Line No.");

                InventoryPostingSetup.Get(TransferReceiptHeader."Transfer-from Code", Item."Inventory Posting Group");
                HeaderBufferInsert(LineBuffer."Shortcut Dimension 2 Code",
                  TransferReceiptLine."Unit of Measure Code",
                  InventoryPostingSetup."Inventory Account");

                LineBuffer.Insert();
            until TransferReceiptLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CopyFromTransferShipmentHeader(TransferShipmentHeader: Record "Transfer Shipment Header"; var LineBuffer: Record "Item Journal Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
        LineCount := TransferShipmentLine.Count();

        if TransferShipmentLine.FindSet() then
            repeat
                LineBuffer.Init();
                LineBuffer."Line No." := TransferShipmentLine."Line No.";
                LineBuffer."Document No." := TransferShipmentHeader."No.";
                LineBuffer."Posting Date" := TransferShipmentHeader."Posting Date";
                LineBuffer."Location Code" := TransferShipmentHeader."Transfer-from Code";
                LineBuffer."New Location Code" := TransferShipmentHeader."Transfer-to Code";
                LineBuffer.Description := TransferShipmentLine.Description;
                LineBuffer."Item No." := TransferShipmentLine."Item No.";
                LineBuffer."Unit of Measure Code" := TransferShipmentLine."Unit of Measure Code";
                LineBuffer.Quantity := TransferShipmentLine.Quantity;
                LineBuffer."Invoiced Quantity" := TransferShipmentLine.Quantity;

                if not WithoutAmount then
                    LineBuffer."Unit Cost" := GetUnitCost(LineBuffer);

                Item.Get(LineBuffer."Item No.");
                if InventoryPostingSetup.Get(TransferShipmentHeader."Transfer-to Code", Item."Inventory Posting Group") then
                    LineBuffer."Shortcut Dimension 1 Code" := InventoryPostingSetup."Inventory Account";
                if DimSetEntry.Get(TransferShipmentLine."Dimension Set ID", KindOperationCode) then
                    LineBuffer."Shortcut Dimension 2 Code" := DimSetEntry."Dimension Value Code";

                InventoryPostingSetup.Get(TransferShipmentHeader."Transfer-from Code", Item."Inventory Posting Group");
                HeaderBufferInsert(LineBuffer."Shortcut Dimension 2 Code",
                  TransferShipmentLine."Unit of Measure Code",
                  InventoryPostingSetup."Inventory Account");

                LineBuffer.Insert();
            until TransferShipmentLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetUnitCost(ItemJournalLine: Record "Item Journal Line") UnitCost: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item No.", "Posting Date", "Document No.", "Document Line No.");

        ValueEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ValueEntry.SetRange("Posting Date", ItemJournalLine."Posting Date");
        ValueEntry.SetRange("Document No.", ItemJournalLine."Document No.");
        ValueEntry.SetRange("Document Line No.", ItemJournalLine."Line No.");

        if ValueEntry.FindFirst() then
            UnitCost := ValueEntry."Cost per Unit"
        else
            UnitCost := 0;
    end;

    [Scope('OnPrem')]
    procedure GetItemLedgerEntryNo(ItemNo: Code[20]; DocumentNo: Code[20]; DocumentLineNo: Integer) EntryNo: Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Document Line No.", DocumentLineNo);

        if ItemLedgerEntry.FindLast() then
            EntryNo := ItemLedgerEntry."Entry No."
        else
            EntryNo := 0;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewOperationTypeCode: Text[30]; NewTransferFromActivityCategory: Text[50]; NewTransferToActivityCategory: Text[50]; NewKindOperationCode: Code[20]; NewPassedByCode: Code[20]; NewReceivedByCode: Code[20]; NewReleasedByCode: Code[20]; NewWithoutAmount: Boolean; NewQuantityType: Option)
    begin
        OperationTypeCode := NewOperationTypeCode;
        TransferFromActivityCategory := NewTransferFromActivityCategory;
        TransferToActivityCategory := NewTransferToActivityCategory;
        KindOperationCode := NewKindOperationCode;
        PassedByCode := NewPassedByCode;
        ReceivedByCode := NewReceivedByCode;
        ReleasedByCode := NewReleasedByCode;
        WithoutAmount := NewWithoutAmount;
        QuantityType := NewQuantityType;
    end;

    local procedure FillReportHeader1()
    var
        ReportHeaderArr: array[12] of Text;
    begin
        ReportHeaderArr[1] := LineBuffer."Document No.";
        ReportHeaderArr[2] := StdRepMgt.GetCompanyName();
        ReportHeaderArr[3] := CompanyInfo."OKPO Code";

        InventoryReportsHelper.FillM11ReportHeader1(ReportHeaderArr);
    end;

    local procedure FillBody1()
    var
        Body1Arr: array[9] of Text;
    begin
        Body1Arr[1] := Format(LineBuffer."Posting Date");
        Body1Arr[2] := OperationTypeCode;
        Body1Arr[3] := OrgDepartFrom;
        Body1Arr[4] := TransferFromActivityCategory;
        Body1Arr[5] := OrgDepartTo;
        Body1Arr[6] := TransferToActivityCategory;
        Body1Arr[7] := CorrAcc;
        Body1Arr[8] := CorrAccDimValue;
        Body1Arr[9] := UnitOfMeasure;

        InventoryReportsHelper.FillM11Body1(Body1Arr);
    end;

    local procedure FillReportHeader2()
    var
        ReportHeaderArr: array[3] of Text;
    begin
        ReportHeaderArr[1] := StdRepMgt.GetEmpName(PassedByCode);
        ReportHeaderArr[2] := RequestedBy;
        ReportHeaderArr[3] := AuthorizedBy;

        InventoryReportsHelper.FillM11ReportHeader2(ReportHeaderArr);
    end;

    local procedure FillBody()
    var
        BodyArr: array[11] of Text;
    begin
        BodyArr[1] := LineBuffer."Shortcut Dimension 1 Code";
        BodyArr[2] := LineBuffer."Shortcut Dimension 2 Code";
        BodyArr[3] := LineBuffer.Description;
        BodyArr[4] := LineBuffer."Item No.";
        BodyArr[5] := LineBuffer."Unit of Measure Code";
        BodyArr[6] := StdRepMgt.GetUoMDesc(LineBuffer."Unit of Measure Code");
        BodyArr[7] := Format(LineBuffer.Quantity);
        BodyArr[8] := Format(LineBuffer."Invoiced Quantity");
        BodyArr[9] := FormatAmount(LineBuffer."Unit Cost");
        BodyArr[10] := FormatAmount(LineBuffer."Invoiced Quantity" * LineBuffer."Unit Cost");
        BodyArr[11] := Format(LineBuffer."Item Shpt. Entry No.");

        InventoryReportsHelper.FillM11Body(BodyArr);
    end;

    local procedure FillReportFooter()
    var
        ReportFooterArr: array[4] of Text;
    begin
        ReportFooterArr[1] := StdRepMgt.GetEmpPosition(ReleasedByCode);
        ReportFooterArr[2] := StdRepMgt.GetEmpName(ReleasedByCode);
        ReportFooterArr[3] := StdRepMgt.GetEmpPosition(ReceivedByCode);
        ReportFooterArr[4] := StdRepMgt.GetEmpName(ReceivedByCode);

        InventoryReportsHelper.FillM11ReportFooter(ReportFooterArr);
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        if Amount = 0 then
            exit('');

        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;
}

